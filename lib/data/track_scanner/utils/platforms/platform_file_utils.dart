import 'dart:io';

import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/platforms/android_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/linux_file_utils.dart';

/// 平台相关的文件操作：遍历目录、读标签、选择目录。
/// 各平台一个实现，TrackScanner 只保留一份平台无关的逻辑。
abstract class PlatformFileUtils {
  // 递归列出 rootUris 下的所有文件（不过滤扩展名，过滤在 TrackScanner 里做），
  // 以 FileDiscoveredFinish 结束；单个目录/文件出错只发 FileDiscoveredError，不中断。
  Stream<DiscoverEvent> discover(Set<String> rootUris);
  // 读取标签；读不了就抛异常（由 TrackScanner 转成 TrackParsedError）。
  Future<SimpleTag> parse(FileDiscovered item);
  // 弹出系统的"选择文件夹"；返回目录的路径/URI，取消返回 null。
  Future<String?> pickDirectory();
  // 系统的"音乐目录"（用于来源页的默认勾选项）；没有则 path 为 null。
  Future<({String name, String? path})> getPlatformMusicPath();
  // 从 Uri 拿到显示/排序友好的 SourceKey。
  String? getSourceKeyFromUri(String uri);
}

PlatformFileUtils createPlatformFileUtils() {
  if (Platform.isLinux) {
    return LinuxFileUtils();
  } else if (Platform.isAndroid) {
    return AndroidFileUtils();
  } else {
    throw UnsupportedError(
      'platform not supported: ${Platform.operatingSystem}',
    );
  }
}
