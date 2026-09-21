import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;

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
  });

  final List<Track> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;

  Track get currentTrack => queue[currentIndex];

  PlayerState copyWith({
    List<Track>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  Player? _player;

  @override
  PlayerState build() {
    ref.onDispose(() => _player?.dispose());
    return PlayerState(
      queue: demoTracks,
      currentIndex: 0,
      isPlaying: false,
      position: Duration.zero,
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
      await _ensurePlayer().open(Media(Uri.file(track.path!).toString()));
    }
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
}
