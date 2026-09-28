import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../domain/track.dart';
import '../domain/visual_analysis.dart';

typedef BeatAnalysisProgressCallback = void Function(double progress);
typedef BeatEnvelopeCallback = void Function(BeatEnvelope envelope);
typedef _AndroidProgressCallback = void Function(
  double progress,
  int offset,
  List<double> values,
);

/// 播放期间按需解码 PCM，并生成背景跳动使用的低频能量包络。
///
/// Linux 使用 FFmpeg 输出单声道 200 Hz 浮点 PCM，Android 使用系统解码器。
/// 两个平台最后都按 50 ms 窗口计算 RMS/Peak，保持已保存数据的语义一致。
class PcmVisualAnalyzer {
  static const _androidMediaLibrary = MethodChannel(
    'linglun/android_media_library',
  );
  static const _beatSampleRate = 20;
  static const _ffmpegTimeout = Duration(minutes: 2);

  static final Map<String, BeatAnalysisProgressCallback>
  _androidProgressListeners = {};
  static final Map<String, _AndroidProgressCallback> _androidChunkListeners =
      {};
  static bool _androidProgressHandlerInstalled = false;

  Process? _linuxProcess;
  String? _linuxRequestId;
  bool _disposed = false;

  Future<BeatEnvelope?> analyze(
    Track track, {
    required String requestId,
    required BeatAnalysisProgressCallback onProgress,
    required BeatEnvelopeCallback onEnvelope,
  }) async {
    final filePath = track.path;
    if (_disposed || filePath == null || track.duration <= Duration.zero) {
      return null;
    }

    if (Platform.isAndroid) {
      _installAndroidProgressHandler();
      _androidProgressListeners[requestId] = onProgress;
    }
    onProgress(0);

    try {
      if (Platform.isLinux) {
        return await _analyzeLinux(
          filePath,
          track.duration,
          requestId: requestId,
          onProgress: onProgress,
          onEnvelope: onEnvelope,
        );
      }
      if (Platform.isAndroid) {
        return await _analyzeAndroid(
          filePath,
          track.duration,
          requestId: requestId,
          onProgress: onProgress,
          onEnvelope: onEnvelope,
        );
      }
      return null;
    } finally {
      _androidProgressListeners.remove(requestId);
      _androidChunkListeners.remove(requestId);
      if (_linuxRequestId == requestId) {
        _linuxRequestId = null;
        _linuxProcess = null;
      }
    }
  }

  /// 取消当前请求，切歌时避免继续占用解码器和 CPU。
  Future<void> cancel(String requestId) async {
    _androidProgressListeners.remove(requestId);
    _androidChunkListeners.remove(requestId);
    if (_linuxRequestId == requestId) {
      _linuxProcess?.kill();
      _linuxProcess = null;
      _linuxRequestId = null;
    }
    if (Platform.isAndroid) {
      try {
        await _androidMediaLibrary.invokeMethod<void>(
          'cancelPcmEnvelope',
          <String, Object?>{'requestId': requestId},
        );
      } on Object {
        // 取消请求失败时仍由请求标识阻止旧结果更新当前曲目。
      }
    }
  }

  void dispose() {
    _disposed = true;
    _linuxProcess?.kill();
    _linuxProcess = null;
    _linuxRequestId = null;
  }

  Future<BeatEnvelope?> _analyzeLinux(
    String filePath,
    Duration duration, {
    required String requestId,
    required BeatAnalysisProgressCallback onProgress,
    required BeatEnvelopeCallback onEnvelope,
  }) async {
    Process? process;
    try {
      process = await Process.start('ffmpeg', [
        '-nostdin',
        '-v',
        'error',
        '-i',
        filePath,
        '-map',
        '0:a:0',
        '-ac',
        '1',
        '-ar',
        '200',
        '-f',
        'f32le',
        'pipe:1',
      ]);
      _linuxProcess = process;
      _linuxRequestId = requestId;

      final expectedBytes = math.max(
        4,
        (duration.inMicroseconds / Duration.microsecondsPerSecond * 200 * 4)
            .round(),
      );
      final outputFuture = _readLinuxOutput(
        process,
        duration: duration,
        expectedBytes: expectedBytes,
        onProgress: onProgress,
        onEnvelope: onEnvelope,
      );
      final errorFuture = process.stderr.drain<void>();
      final result = await Future.wait<Object?>([
        outputFuture,
        process.exitCode,
      ]).timeout(_ffmpegTimeout);
      await errorFuture;

      final partialEnvelope = result[0] as BeatEnvelope?;
      final exitCode = result[1] as int;
      if (exitCode != 0 || partialEnvelope == null) return null;
      final envelope = BeatEnvelope(
        durationMs: duration.inMilliseconds,
        sampleRate: _beatSampleRate,
        values: partialEnvelope.values,
        analyzedDurationMs: duration.inMilliseconds,
      );
      onEnvelope(envelope);
      onProgress(1);
      return envelope;
    } on Object {
      process?.kill();
      return null;
    }
  }

  Future<BeatEnvelope?> _readLinuxOutput(
    Process process, {
    required Duration duration,
    required int expectedBytes,
    required BeatAnalysisProgressCallback onProgress,
    required BeatEnvelopeCallback onEnvelope,
  }) async {
    final accumulator = _LinuxEnvelopeAccumulator(
      duration: duration,
      onEnvelope: onEnvelope,
    );
    var receivedBytes = 0;
    var lastProgress = -1.0;
    var lastUpdate = DateTime.now();
    await for (final chunk in process.stdout) {
      accumulator.add(chunk);
      receivedBytes += chunk.length;
      final now = DateTime.now();
      final progress = (receivedBytes / expectedBytes).clamp(0.0, 1.0);
      if (progress - lastProgress >= .01 ||
          now.difference(lastUpdate) >= const Duration(milliseconds: 200)) {
        lastProgress = progress;
        lastUpdate = now;
        onProgress(progress);
      }
    }
    return accumulator.finish();
  }

  Future<BeatEnvelope?> _analyzeAndroid(
    String filePath,
    Duration duration, {
    required String requestId,
    required BeatAnalysisProgressCallback onProgress,
    required BeatEnvelopeCallback onEnvelope,
  }) async {
    try {
      final values = <double>[];
      _androidChunkListeners[requestId] = (progress, offset, chunk) {
        onProgress(progress);
        if (chunk.isEmpty) return;
        if (offset == values.length) {
          values.addAll(chunk);
        } else if (offset < values.length) {
          values.replaceRange(
            offset,
            math.min(values.length, offset + chunk.length),
            chunk,
          );
        } else {
          return;
        }
        onEnvelope(
          BeatEnvelope(
            durationMs: duration.inMilliseconds,
            sampleRate: _beatSampleRate,
            values: List.unmodifiable(values),
            analyzedDurationMs: math.min(
              duration.inMilliseconds,
              values.length * 1000 ~/ _beatSampleRate,
            ),
          ),
        );
      };
      var source = filePath;
      try {
        final uri = await _androidMediaLibrary.invokeMethod<String>(
          'uriForPath',
          <String, Object?>{'path': filePath},
        );
        if (uri != null && uri.isNotEmpty) source = uri;
      } on Object {
        // URI 查询失败时继续尝试文件路径，兼容可直接访问的共享目录。
      }

      final result = await _androidMediaLibrary.invokeMethod<Object?>(
        'analyzePcmEnvelope',
        <String, Object?>{
          'path': source,
          'durationMs': duration.inMilliseconds,
          'requestId': requestId,
        },
      );
      if (result is! Map) return null;
      final rawValues = result['values'];
      if (rawValues is! List || rawValues.isEmpty) return null;
      final finalValues = [
        for (final value in rawValues)
          if (value is num) value.toDouble().clamp(0.0, 1.0).toDouble(),
      ];
      if (finalValues.isEmpty) return null;
      final sampleRate = result['sampleRate'];
      final durationMs = result['durationMs'];
      if (sampleRate is! num || durationMs is! num) return null;
      final envelope = BeatEnvelope(
        durationMs: durationMs.round(),
        sampleRate: sampleRate.round(),
        values: finalValues,
        analyzedDurationMs: durationMs.round(),
      );
      onEnvelope(envelope);
      onProgress(1);
      return envelope;
    } on Object {
      // Android 设备缺少对应解码器时，保留歌曲并跳过视觉分析。
      return null;
    }
  }

  static void _installAndroidProgressHandler() {
    if (_androidProgressHandlerInstalled) return;
    _androidProgressHandlerInstalled = true;
    _androidMediaLibrary.setMethodCallHandler((call) async {
      if (call.method != 'pcmAnalysisProgress') return null;
      final arguments = call.arguments;
      if (arguments is Map) {
        final requestId = arguments['requestId'];
        final progress = arguments['progress'];
        final offset = arguments['offset'];
        final rawValues = arguments['values'];
        if (requestId is String && progress is num && offset is num) {
          final values = rawValues is List
              ? [
                  for (final value in rawValues)
                    if (value is num)
                      value.toDouble().clamp(0.0, 1.0).toDouble(),
                ]
              : const <double>[];
          _androidChunkListeners[requestId]?.call(
            progress.toDouble().clamp(0.0, 1.0).toDouble(),
            offset.round(),
            values,
          );
        } else if (requestId is String && progress is num) {
          _androidProgressListeners[requestId]?.call(
            progress.toDouble().clamp(0.0, 1.0).toDouble(),
          );
        }
      }
      return null;
    });
  }
}

class _LinuxEnvelopeAccumulator {
  _LinuxEnvelopeAccumulator({required this.duration, required this.onEnvelope});

  final Duration duration;
  final BeatEnvelopeCallback onEnvelope;
  final _pendingBytes = <int>[];
  final _values = <double>[];
  var _lastEmittedValueCount = 0;
  var _lastEmitAt = DateTime.now();

  void add(List<int> chunk) {
    _pendingBytes.addAll(chunk);
    const blockBytes = 10 * 4;
    final completeBytes =
        _pendingBytes.length - _pendingBytes.length % blockBytes;
    if (completeBytes == 0) return;
    final samples = ByteData.sublistView(
      Uint8List.fromList(_pendingBytes.sublist(0, completeBytes)),
    );
    _pendingBytes.removeRange(0, completeBytes);
    const blockSize = 10;
    final sampleCount = samples.lengthInBytes ~/ 4;
    for (
      var offset = 0;
      offset + blockSize <= sampleCount;
      offset += blockSize
    ) {
      var energy = 0.0;
      var peak = 0.0;
      for (var index = 0; index < blockSize; index++) {
        final sample = samples.getFloat32((offset + index) * 4, Endian.little);
        energy += sample * sample;
        peak = math.max(peak, sample.abs());
      }
      final rms = math.sqrt(energy / blockSize);
      _values.add(((rms * .55 + peak * .45) * 2.4).clamp(0.0, 1.0));
    }
    final now = DateTime.now();
    if (_values.length - _lastEmittedValueCount >= 4 ||
        now.difference(_lastEmitAt) >= const Duration(milliseconds: 200)) {
      _emit(now);
    }
  }

  BeatEnvelope? finish() {
    if (_values.isEmpty) return null;
    _emit(DateTime.now());
    return BeatEnvelope(
      durationMs: duration.inMilliseconds,
      sampleRate: 20,
      values: List.unmodifiable(_values),
      analyzedDurationMs: math.min(
        duration.inMilliseconds,
        _values.length * 1000 ~/ 20,
      ),
    );
  }

  void _emit(DateTime now) {
    if (_values.length == _lastEmittedValueCount) return;
    _lastEmittedValueCount = _values.length;
    _lastEmitAt = now;
    onEnvelope(
      BeatEnvelope(
        durationMs: duration.inMilliseconds,
        sampleRate: 20,
        values: List.unmodifiable(_values),
        analyzedDurationMs: math.min(
          duration.inMilliseconds,
          _values.length * 1000 ~/ 20,
        ),
      ),
    );
  }
}
