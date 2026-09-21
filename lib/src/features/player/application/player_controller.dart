import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;

import 'dart:async';
import 'dart:math' as math;

import '../../../core/database/app_database.dart';
import '../domain/track.dart';

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

/// 当前播放器状态。后续将由 libmpv 事件流驱动，而不是由页面自行维护。
class PlayerState {
  const PlayerState({
    required this.queue,
    required this.currentIndex,
    required this.isPlaying,
    required this.position,
    required this.normalizationEnabled,
  });

  final List<Track> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final bool normalizationEnabled;

  Track get currentTrack => queue[currentIndex];

  PlayerState copyWith({
    List<Track>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    bool? normalizationEnabled,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      normalizationEnabled: normalizationEnabled ?? this.normalizationEnabled,
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  Player? _player;
  bool _normalizationEnabled = true;

  @override
  PlayerState build() {
    ref.onDispose(() => _player?.dispose());
    return PlayerState(
      queue: demoTracks,
      currentIndex: 0,
      isPlaying: false,
      position: Duration.zero,
      normalizationEnabled: true,
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

    if (track.path != null) {
      final player = _ensurePlayer();
      await player.open(Media(Uri.file(track.path!).toString()));
      await _applyReplayGain(track);
      unawaited(_recordPlayback(track));
    }
  }

  void setNormalizationEnabled(bool enabled) {
    _normalizationEnabled = enabled;
    state = state.copyWith(normalizationEnabled: enabled);
    final track = state.currentTrack;
    unawaited(_applyReplayGain(track));
  }

  /// 用曲库扫描结果替换播放队列，同时保留当前播放项（如果仍存在）。
  void replaceQueue(List<Track> tracks) {
    if (tracks.isEmpty) return;
    final currentId = state.currentTrack.id;
    final nextIndex = tracks.indexWhere((track) => track.id == currentId);
    state = state.copyWith(
      queue: tracks,
      currentIndex: nextIndex == -1 ? 0 : nextIndex,
    );
  }

  void seek(Duration position) {
    state = state.copyWith(position: position);
  }

  void skipNext() {
    final nextIndex = (state.currentIndex + 1) % state.queue.length;
    playTrack(state.queue[nextIndex]);
  }

  void previous() {
    final previousIndex =
        (state.currentIndex - 1 + state.queue.length) % state.queue.length;
    playTrack(state.queue[previousIndex]);
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
      if (completed) skipNext();
    });
    player.stream.error.listen((error) {
      state = state.copyWith(isPlaying: false);
      // 先停止当前状态，后续接入统一错误提示和日志服务。
      assert(error.isNotEmpty);
    });
    return player;
  }

  Future<void> _applyReplayGain(Track track) async {
    final gain = _normalizationEnabled ? (track.replayGainDb ?? 0) : 0;
    // ReplayGain 是 dB 增益；转换为 mpv 的百分比音量并限制上限，避免异常标签造成过载。
    final volume = (100 * math.pow(10, gain / 20)).clamp(0, 100).toDouble();
    await _ensurePlayer().setVolume(volume);
  }

  Future<void> _recordPlayback(Track track) async {
    try {
      final database = await sharedLinglunDatabase();
      await database.recordPlayback(track.id, DateTime.now());
    } on Object {
      // 统计失败不能影响播放。
    }
  }
}
