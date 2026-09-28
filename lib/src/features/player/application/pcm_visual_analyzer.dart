import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../domain/track.dart';
import '../domain/visual_analysis.dart';

typedef BeatAnalysisProgressCallback = void Function(double progress);

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
  static bool _androidProgressHandlerInstalled = false;

  Process? _linuxProcess;
  String? _linuxRequestId;
  bool _disposed = false;

  Future<BeatEnvelope?> analyze(
    Track track, {
    required String requestId,
    required BeatAnalysisProgressCallback onProgress,
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
        );
      }
      if (Platform.isAndroid) {
        return await _analyzeAndroid(
          filePath,
          track.duration,
          requestId: requestId,
        );
      }
      return null;
    } finally {
      _androidProgressListeners.remove(requestId);
      if (_linuxRequestId == requestId) {
        _linuxRequestId = null;
        _linuxProcess = null;
      }
    }
  }

  /// 取消当前请求，切歌时避免继续占用解码器和 CPU。
  Future<void> cancel(String requestId) async {
    _androidProgressListeners.remove(requestId);
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
        expectedBytes: expectedBytes,
        onProgress: onProgress,
      );
      final errorFuture = process.stderr.drain<void>();
      final result = await Future.wait<Object?>([
        outputFuture,
        process.exitCode,
      ]).timeout(_ffmpegTimeout);
      await errorFuture;

      final output = result[0] as Uint8List;
      final exitCode = result[1] as int;
      if (exitCode != 0 || output.isEmpty) return null;

      final samples = ByteData.sublistView(output);
      const sourceRate = 200;
      final blockSize = sourceRate ~/ _beatSampleRate;
      final values = <double>[];
      final sampleCount = samples.lengthInBytes ~/ 4;
      for (
        var offset = 0;
        offset + blockSize <= sampleCount;
        offset += blockSize
      ) {
        var energy = 0.0;
        var peak = 0.0;
        for (var index = 0; index < blockSize; index++) {
          final sample = samples.getFloat32(
            (offset + index) * 4,
            Endian.little,
          );
          final magnitude = sample.abs();
          energy += sample * sample;
          peak = math.max(peak, magnitude);
        }
        final rms = math.sqrt(energy / blockSize);
        values.add(((rms * .55 + peak * .45) * 2.4).clamp(0.0, 1.0));
      }
      if (values.isEmpty) return null;
      onProgress(1);
      return BeatEnvelope(
        durationMs: duration.inMilliseconds,
        sampleRate: _beatSampleRate,
        values: values,
      );
    } on Object {
      process?.kill();
      return null;
    }
  }

  Future<Uint8List> _readLinuxOutput(
    Process process, {
    required int expectedBytes,
    required BeatAnalysisProgressCallback onProgress,
  }) async {
    final output = BytesBuilder(copy: false);
    var receivedBytes = 0;
    var lastProgress = -1.0;
    var lastUpdate = DateTime.now();
    await for (final chunk in process.stdout) {
      output.add(chunk);
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
    return output.takeBytes();
  }

  Future<BeatEnvelope?> _analyzeAndroid(
    String filePath,
    Duration duration, {
    required String requestId,
  }) async {
    try {
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
      final values = [
        for (final value in rawValues)
          if (value is num) value.toDouble().clamp(0.0, 1.0).toDouble(),
      ];
      if (values.isEmpty) return null;
      final sampleRate = result['sampleRate'];
      final durationMs = result['durationMs'];
      if (sampleRate is! num || durationMs is! num) return null;
      _androidProgressListeners[requestId]?.call(1);
      return BeatEnvelope(
        durationMs: durationMs.round(),
        sampleRate: sampleRate.round(),
        values: values,
      );
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
        if (requestId is String && progress is num) {
          _androidProgressListeners[requestId]?.call(
            progress.toDouble().clamp(0.0, 1.0).toDouble(),
          );
        }
      }
      return null;
    });
  }
}
