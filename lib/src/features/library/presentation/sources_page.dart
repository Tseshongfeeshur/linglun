import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/library_controller.dart';

/// 展示曲库扫描来源，包括用户添加的目录和 XDG 音乐目录。
class SourcesPage extends ConsumerWidget {
  const SourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
      children: [
        Text('歌曲来源', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '曲库会从以下位置读取本地音频文件。',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 24),
        if (state.directories.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.folder_off_outlined),
              title: Text('尚未配置歌曲来源'),
              subtitle: Text('可以在曲库页添加音乐目录。'),
            ),
          )
        else
          for (final directory in state.directories)
            Builder(
              builder: (context) {
                final trackCount = state.tracks
                    .where(
                      (track) => _belongsToDirectory(track.path, directory),
                    )
                    .length;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Icon(
                    _isXdgMusicDirectory(directory)
                        ? Icons.library_music_outlined
                        : Icons.folder_outlined,
                  ),
                  title: Text(directory),
                  subtitle: Text(
                    '${_isXdgMusicDirectory(directory) ? 'XDG 标准音乐目录' : '用户添加的目录'} · $trackCount 首歌曲',
                  ),
                  trailing: state.isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                );
              },
            ),
        if (state.isScanning) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(
            state.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  bool _belongsToDirectory(String? trackPath, String directory) {
    if (trackPath == null || trackPath.isEmpty) return false;
    final normalizedTrack = trackPath.replaceAll('\\', '/');
    final normalizedDirectory = directory
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'/$'), '');
    return normalizedTrack == normalizedDirectory ||
        normalizedTrack.startsWith('$normalizedDirectory/');
  }

  bool _isXdgMusicDirectory(String path) {
    return path.endsWith('/Music') || path.endsWith('/音乐');
  }
}
