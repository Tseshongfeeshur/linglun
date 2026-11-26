import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/models/discover_event.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/utils/read_simple_tag.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

/// Android 实现：走 SAF（存储访问框架）目录授权，不用
/// MANAGE_EXTERNAL_STORAGE，也不走 MediaStore。
/// 读标签直接把 content:// URI 交给 TagLib，避免把大文件整个读进内存。
class AndroidFileUtils extends PlatformFileUtils {
  @override
  Stream<DiscoverEvent> discover(Set<String> rootUris) async* {
    final safUtil = SafUtil();
    // 用一个栈（List 末尾 push/pop）做非递归的深度优先遍历，避免深层目录递归。
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

        // SAF 文档 URI 形如 content://<authority>/tree/<treeId>/document/<docId>，
        // pathSegments = [tree, <treeId>, document, <docId>]。
        // sourceKey 取 <docId>（如 "primary:Music/a.mp3"）：它与"通过哪个目录授权/
        // 浏览到这里"无关，所以同时选了父目录和子目录时同一文件的 sourceKey 相同，
        // 可据此去重（而 uri 不同）。
        final sourceKey = getSourceKeyFromUri(item.uri);

        yield FileDiscovered(
          uri: item.uri,
          sourceKey: sourceKey,
          name: item.name,
          // 注意：SAF 对未知大小可能给 -1、lastModified 可能为 0，
          // TrackScanner.parse 的增量判断依赖这两个约定。
          sizeBytes: item.length,
          editTime: DateTime.fromMillisecondsSinceEpoch(item.lastModified),
        );
      }
    }
    yield FileDiscoveredFinish();
  }

  @override
  Future<SimpleTag> parse(FileDiscovered item) async {
    return readSimpleTag(item.uri);
  }

  @override
  Future<String?> getDirectory() async {
    final safUtil = SafUtil();
    // writePermission：为日后"写回标签/增益"准备。
    // TODO: persistablePermission 是否真的让授权在重启后保留尚未验证；
    // 若重启后 list 报权限错误，需要提示用户重新选择目录。
    final result = await safUtil.pickDirectory(
      writePermission: true,
      persistablePermission: true,
    );
    return result?.uri;
  }

  @override
  Future<({String name, String? path})> getPlatformMusicPath() async {
    // Android 没有可直接遍历的"系统音乐目录"（统一走 SAF 授权），
    // 返回 null，来源页就不显示这一项。
    return (name: '', path: null);
  }

  @override
  String getSourceKeyFromUri(String uri) {
    final segments = Uri.parse(uri).pathSegments;
    var docIdIndex = segments.indexOf('document') + 1;
    if (docIdIndex == 0) return uri;
    return segments[docIdIndex];
  }
}
