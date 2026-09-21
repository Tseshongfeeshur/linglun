import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  PlayerState build() {
    return PlayerState(
      queue: demoTracks,
      currentIndex: 0,
      isPlaying: false,
      position: Duration.zero,
    );
  }

  void togglePlay() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void playTrack(Track track) {
    final index = state.queue.indexWhere((item) => item.id == track.id);
    if (index == -1) return;

    state = state.copyWith(
      currentIndex: index,
      isPlaying: true,
      position: Duration.zero,
    );
  }

  void seek(Duration position) {
    state = state.copyWith(position: position);
  }

  void skipNext() {
    final nextIndex = (state.currentIndex + 1) % state.queue.length;
    state = state.copyWith(
      currentIndex: nextIndex,
      position: Duration.zero,
      isPlaying: true,
    );
  }
}
