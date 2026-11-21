import 'package:flutter_taglib/flutter_taglib.dart' hide Picture;
import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/artist_splitter.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
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
        // TODO: 变量 docId 实际是"下标"而不是 id，名字有误导性；indexOf 找不到时
        // 回退到写死的 3，若 segments 不足 4 段会 RangeError，把整个 discover 流
        // 搞崩。应改成：找不到就 yield FileDiscoveredError 并跳过该项。
        final segments = Uri.parse(item.uri).pathSegments;
        var docId = segments.indexOf('document') + 1;
        if (docId == 0) docId = 3;

        yield FileDiscovered(
          uri: item.uri,
          sourceKey: segments[docId],
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
    // TODO: 这个 parse 与 LinuxFileUtils.parse 几乎逐行重复（只有 open 的参数不同）。
    // 抽成一个共用函数（如 readSimpleTag(String pathOrUri)）放到 platform 目录下，
    // 下面这类"复制粘贴后改错一边"的 bug 就不会出现。
    final file = await TagLibFile.openAsync(item.uri);
    if (file == null) {
      throw 'failed to open file';
    }

    SimpleTag? tag;
    try {
      // FIXME: title/artists/album 的判断写反了——这里是"为空才取值、非空反而是
      // null"，与 LinuxFileUtils 相反。后果：Android 上有标签的曲目标题全部
      // 回退成文件名、歌手/专辑全变"未知"；而空标签会被存进去，空歌手经
      // splitArtists('') 得到 []，进而 artistsKeys 为空，排序/详情页 .first 崩溃。
      // 应为 `file.title.isEmpty ? null : file.title`（artist/album 同理）。
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
}
