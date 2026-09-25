import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/library_controller.dart';
import '../domain/library_sort.dart';
import '../../player/application/player_controller.dart';
import '../../player/domain/track.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String _query = '';
  LibrarySortField _sortField = LibrarySortField.title;
  bool _descending = false;

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryControllerProvider);
    final sourceTracks = libraryState.tracks;
    final filteredTracks = sourceTracks.where((track) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return '${track.title} ${track.artist} ${track.album}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final tracks = sortLibraryTracks(
      filteredTracks,
      field: _sortField,
      descending: _descending,
    );

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
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
          sliver: SliverToBoxAdapter(
            child: _SortBar(
              field: _sortField,
              descending: _descending,
              onFieldChanged: (value) => setState(() => _sortField = value),
              onDirectionChanged: () =>
                  setState(() => _descending = !_descending),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          sliver: SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) =>
                _TrackTile(track: tracks[index], queue: tracks),
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
  const _TrackTile({required this.track, required this.queue});

  final Track track;
  final List<Track> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrent = playerState.currentTrack.id == track.id;
    final minutes = track.duration.inMinutes;
    final seconds = (track.duration.inSeconds % 60).toString().padLeft(2, '0');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (details) =>
          _showTrackMenu(context, track, details.globalPosition),
      onLongPress: () => _showTrackMenu(context, track, null),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: _Cover(track: track),
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
              onPressed: () => ref
                  .read(playerControllerProvider.notifier)
                  .playFromList(
                    queue,
                    track,
                    shuffle: playerState.shuffleEnabled,
                  ),
              tooltip: '播放',
              icon: Icon(
                isCurrent && playerState.isPlaying
                    ? Icons.equalizer
                    : Icons.play_arrow,
              ),
            ),
          ],
        ),
        onTap: () => ref
            .read(playerControllerProvider.notifier)
            .playFromList(queue, track, shuffle: playerState.shuffleEnabled),
      ),
    );
  }

  Future<void> _showTrackMenu(
    BuildContext context,
    Track track,
    Offset? position,
  ) async {
    // 桌面端右键菜单提供元数据入口，长按同时兼容触控板和测试环境。
    final selected = await showMenu<bool>(
      context: context,
      position: position == null
          ? const RelativeRect.fromLTRB(300, 220, 0, 0)
          : RelativeRect.fromLTRB(
              position.dx,
              position.dy,
              position.dx,
              position.dy,
            ),
      items: [
        const PopupMenuItem<bool>(
          value: true,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.info_outline),
            title: Text('音轨详情'),
          ),
        ),
      ],
    );
    if (selected != true || !context.mounted) return;

    // 等菜单路由彻底退出后再创建详情路由，避免两个模态路由叠加。
    await showDialog<void>(
      context: context,
      builder: (_) => _TrackDetailsDialog(track: track),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.field,
    required this.descending,
    required this.onFieldChanged,
    required this.onDirectionChanged,
  });

  final LibrarySortField field;
  final bool descending;
  final ValueChanged<LibrarySortField> onFieldChanged;
  final VoidCallback onDirectionChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('排序'),
        const SizedBox(width: 8),
        DropdownButton<LibrarySortField>(
          value: field,
          onChanged: (value) {
            if (value != null) onFieldChanged(value);
          },
          items: [
            for (final value in LibrarySortField.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDirectionChanged,
          tooltip: descending ? '切换为升序' : '切换为降序',
          icon: Icon(descending ? Icons.arrow_downward : Icons.arrow_upward),
        ),
        Text(descending ? '降序' : '升序'),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.track});

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
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white70,
                  size: 20,
                ),
              )
            : Image.memory(
                track.coverBytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: Color(track.coverColor),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                  ),
                ),
              ),
      ),
    );
  }
}

class _TrackDetailsDialog extends StatelessWidget {
  const _TrackDetailsDialog({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final lyricDocument = track.lyricsDocument;
    final hasLyrics = lyricDocument.plainLyrics.trim().isNotEmpty;
    final values = <String, String>{
      '标题': track.title,
      '艺术家': track.artist,
      '专辑': track.album,
      '时长': track.duration.toString().split('.').first,
      '播放次数': '${track.playCount}',
      if (track.replayGainDb != null)
        'ReplayGain':
            '${track.replayGainDb!.toStringAsFixed(2)} dB（${track.replayGainMode ?? '未知'}）',
      ...track.metadata,
      if (track.lyricsSources.isNotEmpty)
        '读取到的歌词来源': track.lyricsSources
            .map((source) => source.label)
            .join('\n'),
      '歌词语法格式': hasLyrics ? lyricDocument.syntaxLabel : '未读取到歌词',
      '歌词时间戳格式': hasLyrics ? lyricDocument.timingLabel : '未读取到歌词',
      '解析后纯歌词': hasLyrics ? lyricDocument.plainLyrics : '未读取到歌词',
    };
    return AlertDialog(
      title: const Text('音轨详情'),
      content: SizedBox(
        width: 620,
        height: 440,
        child: ListView.separated(
          itemCount: values.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final entry = values.entries.elementAt(index);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
                  Expanded(child: SelectableText(entry.value)),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
