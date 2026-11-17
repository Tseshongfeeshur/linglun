import 'package:haudiotagger/haudiotagger.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

class AndroidFileUtils extends PlatformFileUtils {
  @override
  Stream<DiscoverEvent> discover(Set<String> rootPaths) async* {
    final safUtil = SafUtil();
    List<String> paths = rootPaths.toList();

    while (paths.isNotEmpty) {
      final path = paths.last;
      paths.removeLast();

      List<SafDocumentFile> files = [];
      try {
        files = await safUtil.list(path);
      } catch (e) {
        yield FileDiscoveredError(path: path, detail: e.toString());
        continue;
      }

      for (var item in files) {
        if (item.isDir) {
          paths.add(item.uri);
          continue;
        }
        yield FileDiscovered(
          uri: item.uri,
          name: item.name,
          sizeBytes: item.length,
          editTime: DateTime.fromMillisecondsSinceEpoch(item.lastModified),
        );
      }
    }
    yield FileDiscoveredFinish();
  }

  @override
  Future<Tag?> parse(FileDiscovered item) async {
    final safStream = SafStream();
    return await Haudiotagger.readFromBytes(
      await safStream.readFileBytes(item.uri),
    );
  }

  @override
  Future<String?> getUri() async {
    final safUtil = SafUtil();
    final result = await safUtil.pickDirectory(
      writePermission: true,
      persistablePermission: true,
    );
    return result?.uri;
  }
}
