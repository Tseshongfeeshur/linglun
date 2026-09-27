import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_util;

import '../../player/presentation/artist_label.dart';

/// 扫描期间阻止误触其他播放操作，并展示扫描器当前处理位置。
class ScanProgressDialog extends StatelessWidget {
  const ScanProgressDialog({
    required this.path,
    required this.stage,
    this.artists = const [],
    super.key,
  });

  final String? path;
  final String? stage;
  final List<String> artists;

  @override
  Widget build(BuildContext context) {
    final fileName = path == null || path!.isEmpty
        ? '正在准备文件列表'
        : path_util.basename(path!);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 14),
                  Text('扫描歌曲', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                stage ?? '准备扫描歌曲',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (artists.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '艺术家：',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: Colors.white60),
                    ),
                    Expanded(
                      child: ArtistLabel(
                        artists: artists,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              SelectableText(
                path ?? '正在查找音频文件…',
                maxLines: 3,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
