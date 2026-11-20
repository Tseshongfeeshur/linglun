import 'package:flutter_taglib/flutter_taglib.dart' hide Picture;
import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/artist_splitter.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

class AndroidFileUtils extends PlatformFileUtils {
  @override
  Stream<DiscoverEvent> discover(Set<String> rootUris) async* {
    final safUtil = SafUtil();
    var uris = rootUris.toList();

    while (uris.isNotEmpty) {
      final uri = uris.last;
      uris.removeLast();

      var files = <SafDocumentFile>[];
      try {
        files = await safUtil.list(uri);
      } catch (e) {
        yield FileDiscoveredError(uri: uri, detail: e.toString());
        continue;
      }

      for (var item in files) {
        if (item.isDir) {
          uris.add(item.uri);
          continue;
        }

        final segments = Uri.parse(item.uri).pathSegments;
        var docId = segments.indexOf('document') + 1;
        if (docId == 0) docId = 3;

        yield FileDiscovered(
          uri: item.uri,
          sourceKey: segments[docId],
          name: item.name,
          sizeBytes: item.length,
          editTime: DateTime.fromMillisecondsSinceEpoch(item.lastModified),
        );
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
        title: file.title.isEmpty ? file.title : null,
        artists: file.artist.isEmpty ? splitArtists(file.artist) : null,
        album: file.album.isEmpty ? file.album : null,
        durationMs: file.duration.inMilliseconds,
      );
    } finally {
      file.close();
    }

    return tag;
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

  @override
  Future<({String name, String? path})> getPlatformMusicPath() async {
    return (name: '', path: null);
  }
}
