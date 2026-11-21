import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/utils/artist_splitter.dart';
import 'package:path/path.dart' as p;
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';

/// Linux 实现：直接用 dart:io 遍历目录，路径即 uri，也即 sourceKey。
class LinuxFileUtils extends PlatformFileUtils {
  @override
  Stream<DiscoverEvent> discover(Set<String> rootUris) async* {
    for (final uri in rootUris) {
      final dir = Directory(uri);
      // 遍历中遇到无权限的子目录时 list 流会发出错误。这里不让它中断整个遍历，
      // 而是先记下来：handleError 的回调里不能 yield，所以等当前根目录遍历完
      // 再统一发出（因此错误不是实时出现在进度界面上的）。
      var errors = <FileDiscoveredError>[];

      await for (final item
          in dir.list(followLinks: false, recursive: true).handleError((
            Object e,
          ) {
            if (e is FileSystemException) {
              errors.add(
                FileDiscoveredError(uri: e.path ?? uri, detail: e.message),
              );
            } else {
              throw e;
            }
          })) {
        // TODO: followLinks:false 时，符号链接（指向文件或目录的）会以 Link 类型
        // 出现，被这里过滤掉——即软链接的歌曲/目录不会被扫描（~/Music 里常有
        // 指向 NAS/其他盘的软链接）。要支持就得处理 Link（并防止环）。
        if (item is! File) continue;

        FileStat? stat;
        try {
          stat = await item.stat();
        } catch (e) {
          yield FileDiscoveredError(uri: item.path, detail: e.toString());
          continue;
        }
        if (stat.type == FileSystemEntityType.notFound) {
          yield FileDiscoveredError(
            uri: item.path,
            detail: 'file stat unavailable',
          );
          continue;
        }
        yield FileDiscovered(
          uri: item.absolute.path,
          sourceKey: item.absolute.path,
          name: p.basename(item.path),
          sizeBytes: stat.size,
          editTime: stat.modified,
        );
      }
      for (final error in errors) {
        yield error;
      }
    }
    yield FileDiscoveredFinish();
  }

  @override
  Future<SimpleTag> parse(FileDiscovered item) async {
    // 与 AndroidFileUtils.parse 重复，抽取共用函数的 TODO 见那边。
    final file = await TagLibFile.openAsync(item.uri);
    if (file == null) {
      throw 'failed to open file';
    }

    SimpleTag? tag;
    try {
      tag = SimpleTag(
        title: file.title.isEmpty ? null : file.title,
        artists: file.artist.isEmpty ? null : splitArtists(file.artist),
        album: file.album.isEmpty ? null : file.album,
        durationMs: file.duration.inMilliseconds,
      );
    } finally {
      file.close();
    }

    return tag;
  }

  @override
  Future<String?> getUri() {
    return FilePicker.getDirectoryPath();
  }

  @override
  Future<({String name, String? path})> getPlatformMusicPath() async {
    // 在 sh 里 source ~/.config/user-dirs.dirs（其中的 $HOME 会被展开），
    // 再打印 XDG_MUSIC_DIR。
    // TODO: 文件不存在或没定义该变量时直接返回 null，可回退到 ~/Music；
    // 也可以自己解析这个文件，省掉起一个 shell 进程。
    final result = await Process.run('sh', [
      '-c',
      '. "\$HOME/.config/user-dirs.dirs"; printf "%s" "\$XDG_MUSIC_DIR"',
    ]);

    if (result.exitCode != 0) return (name: 'XDG 音乐目录', path: null);

    final path = (result.stdout as String).trim();
    return (name: 'XDG 音乐目录', path: path.isNotEmpty ? path : null);
  }
}
