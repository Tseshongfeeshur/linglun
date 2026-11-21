import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/scan_state.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/android_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/linux_file_utils.dart';

/// 一次扫描的进度。autoDispose：扫描弹窗关闭（没人监听了）后自动销毁，
/// 而 startScan 在每个事件处检查 ref.mounted——这就是"取消"的实现方式。
/// 注意取消是在"下一个事件到来时"才生效，不是立即停止
/// （discover 卡在某个慢目录时不会马上停）。
class _ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() {
    return ScanState();
  }

  Future<void> startScan(
    Set<String> urisToDiscover,
    List<TrackInfo> existing,
  ) async {
    final trackScanner = TrackScanner();

    // TODO: 平台选择在这里和 track_sources.dart 的 initState 里各写了一份。
    // 抽成一个工厂函数（如 createPlatformFileUtils()），并在不支持的平台上
    // 返回 null / 抛出明确的异常，而不是 throw 一个字符串
    // （这里是 async 函数，抛出的错误没人接，会变成未处理异常）。
    PlatformFileUtils utils;
    if (Platform.isLinux) {
      utils = LinuxFileUtils();
    } else if (Platform.isAndroid) {
      utils = AndroidFileUtils();
    } else {
      throw 'platform not supported';
    }

    // 两阶段接力：先把发现阶段跑完，再把发现的文件交给解析阶段。
    // TODO: 没有防止重复调用 startScan（状态会交错），也不会在开始时重置状态；
    // 目前靠"每次弹窗新建一个 autoDispose 的 provider"规避。
    final discoverStream = trackScanner.discover(utils, urisToDiscover);
    await for (final event in discoverStream) {
      if (!ref.mounted) break;
      state = state.applyDiscover(event);
    }

    // TODO: 弹窗已关闭（!ref.mounted）时应直接 return，而不是继续走 parse：
    // 现在会以空列表启动 parse 流，再在第一个事件处 break。
    var tracksToParse = <FileDiscovered>[];
    if (ref.mounted) {
      tracksToParse = state.discoverResult;
    }

    final parseStream = trackScanner.parse(utils, tracksToParse, existing);
    await for (final ParseEvent event in parseStream) {
      if (!ref.mounted) break;
      state = state.applyParse(event);
    }
  }
}

// 注意 autoDispose：同一时间只应有一个扫描弹窗在监听它。
final scanProvider = NotifierProvider.autoDispose<_ScanNotifier, ScanState>(
  _ScanNotifier.new,
);
