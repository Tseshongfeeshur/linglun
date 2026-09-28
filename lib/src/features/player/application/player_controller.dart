import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' hide Track;

import 'dart:async';
import 'dart:math' as math;

import '../../../core/database/app_database.dart';
import '../domain/audio_processing.dart';
import '../domain/playback_background.dart';
import '../domain/track.dart';
import 'pcm_visual_analyzer.dart';
import 'playback_media_session.dart';

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

enum RepeatMode { off, all, one }

/// 当前播放器状态。后续将由 libmpv 事件流驱动，而不是由页面自行维护。
class PlayerState {
  const PlayerState({
    required this.queue,
    required this.currentIndex,
    required this.isPlaying,
    required this.position,
    required this.audioSettings,
    this.backgroundSettings = const PlaybackBackgroundSettings(),
    this.shuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
    this.beatAnalysisProgress,
    this.debugMode = false,
  });

  final List<Track> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final AudioProcessingSettings audioSettings;
  final PlaybackBackgroundSettings backgroundSettings;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final double? beatAnalysisProgress;
  final bool debugMode;

  bool get normalizationEnabled => audioSettings.normalizationEnabled;

  Track get currentTrack => queue[currentIndex];

  PlayerState copyWith({
    List<Track>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    AudioProcessingSettings? audioSettings,
    PlaybackBackgroundSettings? backgroundSettings,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
    double? beatAnalysisProgress,
    bool clearBeatAnalysisProgress = false,
    bool? debugMode,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      audioSettings: audioSettings ?? this.audioSettings,
      backgroundSettings: backgroundSettings ?? this.backgroundSettings,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      beatAnalysisProgress: clearBeatAnalysisProgress
          ? null
          : beatAnalysisProgress ?? this.beatAnalysisProgress,
      debugMode: debugMode ?? this.debugMode,
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  static const _androidMediaLibrary = MethodChannel(
    'linglun/android_media_library',
  );
  static const _audioSettingsKey = 'audio.processing.v1';
  static const _backgroundSettingsKey = 'visual.playbackBackground.v1';
  static const _debugModeKey = 'app.debugMode.v1';

  Player? _player;
  Timer? _playbackTimer;
  String? _sessionTrackId;
  Duration _sessionElapsed = Duration.zero;
  DateTime? _lastPlaybackTick;
  bool _sessionCounted = false;
  final _filterGraphBuilder = const MpvFilterGraphBuilder();
  final _random = math.Random();
  final _visualAnalyzer = PcmVisualAnalyzer();
  String? _beatAnalysisRequestId;
  int _beatAnalysisGeneration = 0;

  @override
  PlayerState build() {
    playbackMediaSession.bind(
      play: () {
        if (!state.isPlaying) togglePlay();
      },
      pause: () {
        if (state.isPlaying) togglePlay();
      },
      stop: stop,
      next: skipNext,
      previous: previous,
      seek: seek,
      playQueueIndex: playQueueIndex,
      setRepeatMode: setRepeatModeByName,
      setShuffleEnabled: setShuffleEnabled,
    );
    listenSelf((_, next) {
      unawaited(_publishMediaSession(next));
    });
    ref.onDispose(() {
      _playbackTimer?.cancel();
      final requestId = _beatAnalysisRequestId;
      if (requestId != null) {
        unawaited(_visualAnalyzer.cancel(requestId));
      }
      _visualAnalyzer.dispose();
      _player?.dispose();
      playbackMediaSession.unbind();
    });
    unawaited(_loadAudioSettings());
    unawaited(_loadBackgroundSettings());
    unawaited(_loadDebugMode());
    return PlayerState(
      queue: demoTracks,
      currentIndex: 0,
      isPlaying: false,
      position: Duration.zero,
      audioSettings: AudioProcessingSettings(),
      backgroundSettings: const PlaybackBackgroundSettings(),
    );
  }

  void togglePlay() {
    final track = state.currentTrack;
    if (track.path == null) {
      state = state.copyWith(isPlaying: !state.isPlaying);
      return;
    }

    final player = _ensurePlayer();
    if (state.isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  Future<void> playTrack(Track track) async {
    final index = state.queue.indexWhere((item) => item.id == track.id);
    if (index == -1) return;

    _cancelBeatAnalysis();
    state = state.copyWith(
      currentIndex: index,
      isPlaying: true,
      position: Duration.zero,
    );
    await _openCurrentTrack();
  }

  Future<void> _openCurrentTrack() async {
    final track = state.currentTrack;
    _stopPlaybackSession();

    if (track.path != null) {
      final player = _ensurePlayer();
      try {
        await _applyAudioProcessing(track);
        final source = await _playbackSource(track.path!);
        await player.open(Media(source));
        _startPlaybackSession(track);
        _startBeatAnalysis(track);
      } on Object catch (error, stackTrace) {
        debugPrint('伶伦：打开音频失败：${track.path}\n$error');
        debugPrintStack(stackTrace: stackTrace);
        state = state.copyWith(isPlaying: false);
        _cancelBeatAnalysis();
        _stopPlaybackSession();
      }
    }
  }

  /// 从用户当前浏览的列表建立一次性播放队列，并立即播放点击的曲目。
  /// 随机模式下只在建队列时洗牌一次，后续播放仍由同一个队列推进。
  Future<void> playFromList(
    Iterable<Track> tracks,
    Track selected, {
    bool shuffle = false,
  }) async {
    final uniqueTracks = <String, Track>{
      for (final track in tracks) track.id: track,
    };
    if (!uniqueTracks.containsKey(selected.id)) return;

    final queue = uniqueTracks.values.toList();
    var currentIndex = queue.indexWhere((track) => track.id == selected.id);
    if (shuffle) {
      queue.shuffle(_random);
      queue.remove(selected);
      queue.insert(0, selected);
      currentIndex = 0;
    }
    _cancelBeatAnalysis();
    state = state.copyWith(
      queue: queue,
      currentIndex: currentIndex,
      isPlaying: true,
      position: Duration.zero,
    );
    await _openCurrentTrack();
  }

  void setNormalizationEnabled(bool enabled) {
    updateAudioSettings(
      state.audioSettings.copyWith(normalizationEnabled: enabled),
    );
  }

  void updateAudioSettings(AudioProcessingSettings settings) {
    state = state.copyWith(audioSettings: settings);
    unawaited(_saveAudioSettings(settings));
    unawaited(_applyAudioProcessing(state.currentTrack));
  }

  void updateBackgroundSettings(PlaybackBackgroundSettings settings) {
    state = state.copyWith(backgroundSettings: settings);
    unawaited(_saveBackgroundSettings(settings));
  }

  void updateDebugMode(bool enabled) {
    state = state.copyWith(debugMode: enabled);
    unawaited(_saveDebugMode(enabled));
  }

  /// 用曲库扫描结果替换播放队列，同时保留当前播放项（如果仍存在）。
  void replaceQueue(List<Track> tracks) {
    final nextQueue = tracks.isEmpty ? demoTracks : tracks;
    final currentId = state.currentTrack.id;
    final nextIndex = nextQueue.indexWhere((track) => track.id == currentId);
    if (nextIndex == -1 && _player != null) {
      _cancelBeatAnalysis();
      _stopPlaybackSession();
      unawaited(_player!.stop());
    }
    state = state.copyWith(
      queue: nextQueue,
      currentIndex: nextIndex == -1 ? 0 : nextIndex,
      isPlaying: nextIndex == -1 ? false : state.isPlaying,
      position: nextIndex == -1 ? Duration.zero : state.position,
    );
  }

  void seek(Duration position) {
    final duration = state.currentTrack.duration;
    final upperBound = duration > Duration.zero ? duration : position;
    final bounded = position < Duration.zero
        ? Duration.zero
        : position > upperBound
        ? upperBound
        : position;
    state = state.copyWith(position: bounded);
    _player?.seek(bounded);
  }

  void stop() {
    _cancelBeatAnalysis();
    _stopPlaybackSession();
    unawaited(_player?.stop());
    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }

  void playQueueIndex(int index) {
    if (index < 0 || index >= state.queue.length) return;
    unawaited(playTrack(state.queue[index]));
  }

  void skipNext() {
    if (state.queue.length < 2) {
      if (state.repeatMode != RepeatMode.off) {
        playTrack(state.currentTrack);
      }
      return;
    }
    final sequentialIndex = state.currentIndex + 1;
    final nextIndex = sequentialIndex < state.queue.length
        ? sequentialIndex
        : state.repeatMode == RepeatMode.all
        ? 0
        : -1;
    if (nextIndex == -1) return;
    playTrack(state.queue[nextIndex]);
  }

  void previous() {
    if (state.queue.length < 2) return;
    final previousIndex = state.currentIndex == 0
        ? state.queue.length - 1
        : state.currentIndex - 1;
    playTrack(state.queue[previousIndex]);
  }

  void toggleShuffle() {
    if (state.shuffleEnabled) {
      state = state.copyWith(shuffleEnabled: false);
    } else {
      enableShuffleAndReshuffle();
    }
  }

  void setShuffleEnabled(bool enabled) {
    if (enabled == state.shuffleEnabled) return;
    if (enabled) {
      enableShuffleAndReshuffle();
    } else {
      state = state.copyWith(shuffleEnabled: false);
    }
  }

  /// 开启随机播放时立即重排当前队列，并保持正在播放的曲目为首项。
  void enableShuffleAndReshuffle() {
    if (state.shuffleEnabled) return;
    final current = state.currentTrack;
    final queue = [...state.queue]..shuffle(_random);
    queue.remove(current);
    queue.insert(0, current);
    state = state.copyWith(queue: queue, currentIndex: 0, shuffleEnabled: true);
  }

  void cycleRepeatMode() {
    final nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: nextMode);
  }

  void setRepeatModeByName(String mode) {
    final nextMode = RepeatMode.values.firstWhere(
      (item) => item.name == mode,
      orElse: () => RepeatMode.off,
    );
    state = state.copyWith(repeatMode: nextMode);
  }

  void _handleTrackCompleted() {
    _cancelBeatAnalysis();
    _stopPlaybackSession();
    if (state.repeatMode == RepeatMode.one ||
        (state.repeatMode == RepeatMode.all && state.queue.length == 1)) {
      unawaited(playTrack(state.currentTrack));
      return;
    }
    if (state.currentIndex == state.queue.length - 1 &&
        state.repeatMode == RepeatMode.off) {
      state = state.copyWith(isPlaying: false);
      return;
    }
    skipNext();
  }

  Player _ensurePlayer() {
    return _player ??= _createPlayer();
  }

  void _startBeatAnalysis(Track track) {
    if (track.path == null || track.beatEnvelope?.isComplete == true) {
      state = state.copyWith(clearBeatAnalysisProgress: true);
      return;
    }
    if (track.duration <= Duration.zero) return;

    final requestId = '${track.id}:${++_beatAnalysisGeneration}';
    _beatAnalysisRequestId = requestId;
    state = state.copyWith(beatAnalysisProgress: 0);
    unawaited(_runBeatAnalysis(track, requestId));
  }

  Future<void> _runBeatAnalysis(Track track, String requestId) async {
    final envelope = await _visualAnalyzer.analyze(
      track,
      requestId: requestId,
      onProgress: (progress) {
        if (_beatAnalysisRequestId != requestId) return;
        state = state.copyWith(beatAnalysisProgress: progress);
      },
      onEnvelope: (envelope) {
        if (_beatAnalysisRequestId != requestId) return;
        final index = state.queue.indexWhere((item) => item.id == track.id);
        if (index == -1) return;
        final currentTrack = state.queue[index];
        if (currentTrack.path != track.path ||
            currentTrack.modifiedAt != track.modifiedAt) {
          return;
        }
        final queue = [...state.queue];
        queue[index] = currentTrack.copyWith(beatEnvelope: envelope);
        state = state.copyWith(queue: queue);
      },
    );
    if (_beatAnalysisRequestId != requestId) return;
    _beatAnalysisRequestId = null;
    if (envelope == null) {
      state = state.copyWith(clearBeatAnalysisProgress: true);
      return;
    }

    final index = state.queue.indexWhere((item) => item.id == track.id);
    if (index == -1) {
      state = state.copyWith(clearBeatAnalysisProgress: true);
      return;
    }
    final currentTrack = state.queue[index];
    if (currentTrack.path != track.path ||
        currentTrack.modifiedAt != track.modifiedAt) {
      state = state.copyWith(clearBeatAnalysisProgress: true);
      return;
    }
    final queue = [...state.queue];
    queue[index] = queue[index].copyWith(beatEnvelope: envelope);
    // 先更新内存状态，让背景在分析完成的同一轮状态更新中开始 Pulse；
    // 数据库写入放在后面，避免磁盘慢写延迟视觉反馈。
    state = state.copyWith(queue: queue, clearBeatAnalysisProgress: true);
    try {
      final database = await sharedLinglunDatabase();
      await database.updateBeatEnvelope(track.id, envelope.encode());
    } on Object catch (error, stackTrace) {
      debugPrint('伶伦：保存 PCM 包络失败：${track.path}\n$error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _cancelBeatAnalysis() {
    final requestId = _beatAnalysisRequestId;
    _beatAnalysisRequestId = null;
    _beatAnalysisGeneration++;
    if (requestId != null) {
      unawaited(_visualAnalyzer.cancel(requestId));
    }
    if (state.beatAnalysisProgress != null) {
      state = state.copyWith(clearBeatAnalysisProgress: true);
    }
  }

  Future<void> _publishMediaSession(PlayerState next) {
    return playbackMediaSession.publish(
      queue: next.queue,
      currentIndex: next.currentIndex,
      playing: next.isPlaying,
      position: next.position,
      repeatMode: next.repeatMode.name,
      shuffleEnabled: next.shuffleEnabled,
    );
  }

  Future<String> _playbackSource(String path) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final uri = await _androidMediaLibrary.invokeMethod<String>(
          'uriForPath',
          {'path': path},
        );
        if (uri != null && uri.isNotEmpty) return uri;
      } on Object catch (error, stackTrace) {
        debugPrint('伶伦：查找 Android 媒体 URI 失败：$path\n$error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    return Uri.file(path).toString();
  }

  Player _createPlayer() {
    final player = Player();
    player.stream.playing.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    player.stream.position.listen((position) {
      state = state.copyWith(position: position);
    });
    player.stream.completed.listen((completed) {
      if (completed) {
        _handleTrackCompleted();
      }
    });
    player.stream.error.listen((error) {
      state = state.copyWith(isPlaying: false);
      debugPrint('伶伦：播放器错误：$error');
    });
    return player;
  }

  Future<void> _applyAudioProcessing(Track track) async {
    final player = _player;
    if (player == null) return;

    final platform = player.platform;
    if (platform is NativePlayer) {
      try {
        // ReplayGain 是播放链路中的响度处理，不等同于用户音量。
        // 根据扫描结果选择曲目或专辑模式，避免只有专辑增益时强制使用曲目模式。
        await platform.setProperty(
          'replaygain',
          state.normalizationEnabled ? (track.replayGainMode ?? 'track') : 'no',
        );
        await platform.setProperty('replaygain-preamp', '0');
        await platform.setProperty('replaygain-clip', 'yes');
        await platform.setProperty('replaygain-fallback', '0');
        await platform.setProperty(
          'af',
          _filterGraphBuilder.build(state.audioSettings) ?? '',
        );
      } on Object {
        // 音频处理不可用时保持原始播放链路，不能因此阻止歌曲播放。
      }
    }
  }

  Future<void> _loadAudioSettings() async {
    try {
      final database = await sharedLinglunDatabase();
      final value = await database.loadSetting(_audioSettingsKey);
      if (value == null || value.isEmpty) return;
      final settings = AudioProcessingSettings.decode(value);
      state = state.copyWith(audioSettings: settings);
      await _applyAudioProcessing(state.currentTrack);
    } on Object {
      // 设置读取失败时保留默认值，不能影响应用启动。
    }
  }

  Future<void> _saveAudioSettings(AudioProcessingSettings settings) async {
    try {
      final database = await sharedLinglunDatabase();
      await database.saveSetting(_audioSettingsKey, settings.encode());
    } on Object {
      // 设置持久化失败时仍保持当前进程内的设置。
    }
  }

  Future<void> _loadBackgroundSettings() async {
    try {
      final database = await sharedLinglunDatabase();
      final value = await database.loadSetting(_backgroundSettingsKey);
      if (value == null || value.isEmpty) return;
      state = state.copyWith(
        backgroundSettings: PlaybackBackgroundSettings.decode(value),
      );
    } on Object {
      // 设置读取失败时保留默认值，不能影响应用启动。
    }
  }

  Future<void> _saveBackgroundSettings(
    PlaybackBackgroundSettings settings,
  ) async {
    try {
      final database = await sharedLinglunDatabase();
      await database.saveSetting(_backgroundSettingsKey, settings.encode());
    } on Object {
      // 设置持久化失败时仍保持当前进程内的设置。
    }
  }

  Future<void> _loadDebugMode() async {
    try {
      final database = await sharedLinglunDatabase();
      final value = await database.loadSetting(_debugModeKey);
      if (value == null) return;
      state = state.copyWith(debugMode: value == 'true');
    } on Object {
      // 调试设置读取失败时保持关闭，不能影响正常播放。
    }
  }

  Future<void> _saveDebugMode(bool enabled) async {
    try {
      final database = await sharedLinglunDatabase();
      await database.saveSetting(_debugModeKey, enabled.toString());
    } on Object {
      // 调试设置保存失败时仍保持当前进程内状态。
    }
  }

  void _startPlaybackSession(Track track) {
    _stopPlaybackSession();
    _sessionTrackId = track.id;
    _sessionElapsed = Duration.zero;
    _lastPlaybackTick = DateTime.now();
    _sessionCounted = false;
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _tickPlaybackSession(track),
    );
  }

  void _tickPlaybackSession(Track track) {
    final lastTick = _lastPlaybackTick;
    final sessionTrackId = _sessionTrackId;
    final now = DateTime.now();
    _lastPlaybackTick = now;
    if (sessionTrackId != track.id || _sessionCounted || lastTick == null) {
      return;
    }
    if (!state.isPlaying || state.currentTrack.id != track.id) return;

    _sessionElapsed += now.difference(lastTick);
    final halfDuration = Duration(
      microseconds: track.duration.inMicroseconds ~/ 2,
    );
    final threshold = track.duration <= Duration.zero
        ? const Duration(seconds: 30)
        : halfDuration < const Duration(seconds: 30)
        ? halfDuration
        : const Duration(seconds: 30);
    if (threshold <= Duration.zero || _sessionElapsed < threshold) return;

    _sessionCounted = true;
    unawaited(_recordPlayback(track));
  }

  void _stopPlaybackSession() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _sessionTrackId = null;
    _lastPlaybackTick = null;
    _sessionElapsed = Duration.zero;
    _sessionCounted = false;
  }

  Future<void> _recordPlayback(Track track) async {
    try {
      final database = await sharedLinglunDatabase();
      final playedAt = DateTime.now();
      await database.recordPlayback(track.id, playedAt);
      final index = state.queue.indexWhere((item) => item.id == track.id);
      if (index != -1) {
        final queue = [...state.queue];
        queue[index] = queue[index].copyWith(
          playCount: queue[index].playCount + 1,
          lastPlayedAt: playedAt,
        );
        state = state.copyWith(queue: queue);
      }
    } on Object {
      // 统计失败不能影响播放。
    }
  }
}
