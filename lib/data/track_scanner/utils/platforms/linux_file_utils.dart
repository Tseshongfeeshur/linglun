import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/utils/artist_splitter.dart';
import 'package:path/path.dart' as p;
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';

class LinuxFileUtils extends PlatformFileUtils {
  @override
  Stream<DiscoverEvent> discover(Set<String> rootUris) async* {
    for (final uri in rootUris) {
      final dir = Directory(uri);
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
    final result = await Process.run('sh', [
      '-c',
      '. "\$HOME/.config/user-dirs.dirs"; printf "%s" "\$XDG_MUSIC_DIR"',
    ]);

    if (result.exitCode != 0) return (name: 'XDG 音乐目录', path: null);

    final path = (result.stdout as String).trim();
    return (name: 'XDG 音乐目录', path: path.isNotEmpty ? path : null);
  }
}
