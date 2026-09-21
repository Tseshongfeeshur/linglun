import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';

class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final track = playerState.currentTrack;
    final duration = track.duration.inMilliseconds.toDouble();
    final position = playerState.position.inMilliseconds
        .clamp(0, track.duration.inMilliseconds)
        .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
        children: [
          _Cover(color: Color(track.coverColor)),
          const SizedBox(width: 12),
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  track.artist,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            tooltip: '上一首',
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton.filled(
            onPressed: ref.read(playerControllerProvider.notifier).togglePlay,
            tooltip: playerState.isPlaying ? '暂停' : '播放',
            icon: Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            onPressed: ref.read(playerControllerProvider.notifier).skipNext,
            tooltip: '下一首',
            icon: const Icon(Icons.skip_next),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 260,
            child: Slider(
              value: duration == 0 ? 0 : position,
              max: duration == 0 ? 1 : duration,
              onChanged: (value) => ref
                  .read(playerControllerProvider.notifier)
                  .seek(Duration(milliseconds: value.round())),
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: '播放队列',
            icon: const Icon(Icons.queue_music),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note, color: Colors.white70, size: 20),
    );
  }
}
