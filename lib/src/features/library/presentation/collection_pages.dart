import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/library_controller.dart';
import '../../player/application/player_controller.dart';
import '../../player/domain/track.dart';

/// 展示按专辑归类的曲目，作为播放页和专辑视觉设计的基础列表。
class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(libraryControllerProvider).tracks;
    final albums = _groupBy(tracks, (track) => track.album);
    return _CollectionPage(
      title: '专辑',
      emptyText: '扫描本地歌曲后，这里会显示专辑。',
      groups: albums,
      ref: ref,
    );
  }
}

/// 展示按艺术家归类的曲目。
class ArtistsPage extends ConsumerWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(libraryControllerProvider).tracks;
    final artists = _groupBy(tracks, (track) => track.artist);
    return _CollectionPage(
      title: '艺术家',
      emptyText: '扫描本地歌曲后，这里会显示艺术家。',
      groups: artists,
      ref: ref,
    );
  }
}

/// 展示当前播放队列，后续可扩展为持久化播放列表。
class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playerControllerProvider).queue;
    return _CollectionPage(
      title: '播放列表',
      emptyText: '当前没有可播放的歌曲。',
      groups: {'当前队列': queue},
      ref: ref,
    );
  }
}

class _CollectionPage extends StatelessWidget {
  const _CollectionPage({
    required this.title,
    required this.emptyText,
    required this.groups,
    required this.ref,
  });

  final String title;
  final String emptyText;
  final Map<String, List<Track>> groups;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final hasTracks = groups.values.any((tracks) => tracks.isNotEmpty);
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          hasTracks ? '按 $title 浏览本地音乐。' : emptyText,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 24),
        if (!hasTracks)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(emptyText),
            ),
          )
        else
          for (final entry in groups.entries)
            _CollectionGroup(title: entry.key, tracks: entry.value, ref: ref),
      ],
    );
  }
}

class _CollectionGroup extends StatelessWidget {
  const _CollectionGroup({
    required this.title,
    required this.tracks,
    required this.ref,
  });

  final String title;
  final List<Track> tracks;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${tracks.length} 首',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final track in tracks)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: _CollectionCover(track: track),
              title: Text(track.title),
              subtitle: Text(track.artist),
              trailing: IconButton(
                tooltip: '播放',
                onPressed: () => ref
                    .read(playerControllerProvider.notifier)
                    .playTrack(track),
                icon: const Icon(Icons.play_arrow),
              ),
              onTap: () =>
                  ref.read(playerControllerProvider.notifier).playTrack(track),
            ),
        ],
      ),
    );
  }
}

class _CollectionCover extends StatelessWidget {
  const _CollectionCover({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 42,
        height: 42,
        child: track.coverBytes == null
            ? ColoredBox(
                color: Color(track.coverColor),
                child: const Icon(Icons.music_note, color: Colors.white70),
              )
            : Image.memory(
                track.coverBytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: Color(track.coverColor),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

Map<String, List<Track>> _groupBy(
  Iterable<Track> tracks,
  String Function(Track) keyOf,
) {
  final groups = <String, List<Track>>{};
  for (final track in tracks) {
    groups.putIfAbsent(keyOf(track), () => []).add(track);
  }
  return Map.fromEntries(
    groups.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
  );
}
