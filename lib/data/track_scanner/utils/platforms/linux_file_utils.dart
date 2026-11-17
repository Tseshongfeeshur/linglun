import 'dart:io';

import 'package:haudiotagger/haudiotagger.dart';
import 'package:path/path.dart' as p;
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';

class LinuxFileUtils extends PlatformFileUtils {
  @override
  Stream<DiscoverEvent> discover(Set<String> rootPaths) async* {
    // TODO: 确保打断后能停止
    Set<String> paths = {};
    for (final String path in rootPaths) {
      final dir = Directory(path);
      List<FileDiscoveredError> errors = [];

      await for (final item
          in dir.list(followLinks: false, recursive: true).handleError((
            Object e,
          ) {
            if (e is FileSystemException) {
              errors.add(
                FileDiscoveredError(path: e.path ?? path, detail: e.message),
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
          yield FileDiscoveredError(path: item.path, detail: e.toString());
          continue;
        }
        if (stat.type == FileSystemEntityType.notFound) {
          yield FileDiscoveredError(
            path: item.path,
            detail: 'file stat unavailable',
          );
          continue;
        }
        if (!paths.contains(item.absolute.path)) {
          paths.add(item.absolute.path);
          yield FileDiscovered(
            uri: item.absolute.path,
            name: p.basename(item.path),
            sizeBytes: stat.size,
            editTime: stat.modified,
          );
        }
      }
      for (final error in errors) {
        yield error;
      }
    }
    yield FileDiscoveredFinish();
  }

  @override
  Future<Tag?> parse(FileDiscovered item) async {
    return await Haudiotagger.read(item.uri);
  }
}
