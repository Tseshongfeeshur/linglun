import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/library_controller.dart';
import '../../player/application/player_controller.dart';
import '../../player/domain/track.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryControllerProvider);
    final sourceTracks = libraryState.tracks;
    final tracks = sourceTracks.where((track) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return '${track.title} ${track.artist} ${track.album}'
          .toLowerCase()
          .contains(query);
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, libraryState)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text('所有歌曲', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 10),
                Text(
                  '${sourceTracks.length} 首',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          sliver: SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) => _TrackTile(track: tracks[index]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, LibraryState libraryState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('曲库', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  '你的本地音乐，从这里开始。',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 270,
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: '搜索歌曲、艺术家或专辑',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: libraryState.isScanning
                ? null
                : () => ref.read(libraryControllerProvider.notifier).scan(),
            tooltip: '刷新曲库',
            icon: libraryState.isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: libraryState.isScanning
                ? null
                : () => ref
                      .read(libraryControllerProvider.notifier)
                      .pickDirectoryAndScan(),
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('添加目录'),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends ConsumerWidget {
  const _TrackTile({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrent = playerState.currentTrack.id == track.id;
    final minutes = track.duration.inMinutes;
    final seconds = (track.duration.inSeconds % 60).toString().padLeft(2, '0');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      leading: _Cover(color: Color(track.coverColor)),
      title: Text(
        track.title,
        style: TextStyle(
          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isCurrent ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text('${track.artist}  ·  ${track.album}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$minutes:$seconds',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () =>
                ref.read(playerControllerProvider.notifier).playTrack(track),
            tooltip: '播放',
            icon: Icon(
              isCurrent && playerState.isPlaying
                  ? Icons.equalizer
                  : Icons.play_arrow,
            ),
          ),
        ],
      ),
      onTap: () => ref.read(playerControllerProvider.notifier).playTrack(track),
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
