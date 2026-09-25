import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;

import 'dart:async';
import 'dart:math' as math;

import '../../../core/database/app_database.dart';
import '../domain/audio_processing.dart';
import '../domain/track.dart';

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
    this.shuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
  });

  final List<Track> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final AudioProcessingSettings audioSettings;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;

  bool get normalizationEnabled => audioSettings.normalizationEnabled;

  Track get currentTrack => queue[currentIndex];

  PlayerState copyWith({
    List<Track>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    AudioProcessingSettings? audioSettings,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      audioSettings: audioSettings ?? this.audioSettings,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  static const _audioSettingsKey = 'audio.processing.v1';

  Player? _player;
  Timer? _playbackTimer;
  String? _sessionTrackId;
  Duration _sessionElapsed = Duration.zero;
  DateTime? _lastPlaybackTick;
  bool _sessionCounted = false;
  final _filterGraphBuilder = const MpvFilterGraphBuilder();
  final _random = math.Random();

  @override
  PlayerState build() {
    ref.onDispose(() {
      _playbackTimer?.cancel();
      _player?.dispose();
    });
    unawaited(_loadAudioSettings());
    return PlayerState(
      queue: demoTracks,
      currentIndex: 0,
      isPlaying: false,
      position: Duration.zero,
      audioSettings: AudioProcessingSettings(),
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
        await player.open(Media(Uri.file(track.path!).toString()));
        _startPlaybackSession(track);
      } on Object {
        state = state.copyWith(isPlaying: false);
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

  /// 用曲库扫描结果替换播放队列，同时保留当前播放项（如果仍存在）。
  void replaceQueue(List<Track> tracks) {
    final nextQueue = tracks.isEmpty ? demoTracks : tracks;
    final currentId = state.currentTrack.id;
    final nextIndex = nextQueue.indexWhere((track) => track.id == currentId);
    if (nextIndex == -1 && _player != null) {
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

  void _handleTrackCompleted() {
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
      // 先停止当前状态，后续接入统一错误提示和日志服务。
      assert(error.isNotEmpty);
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
