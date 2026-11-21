import 'package:path/path.dart' as p;
import 'package:linglun/data/track_scanner/track_scanner.dart';

/// 一次扫描的进度与结果快照（不可变）。发现阶段与解析阶段各自累积事件，
/// 扫描弹窗据此显示进度和结果；"更新曲库"时取 parseSkips + parseUpdates。
class ScanState {
  final List<FileDiscovered> discoverResult;
  final List<FileDiscoveredError> discoverErrors;
  final bool discoverFinished;

  // 新增/已变化的曲目，以及被标记为 removed 的曲目
  // （removed == true 的也在这里，界面统计"已更新"时要把它们排除）。
  final List<TrackParsed> parseUpdates;
  final List<TrackSkipped> parseSkips;
  final List<TrackParsedError> parseErrors;
  final bool parseFinished;

  // 正在处理的文件名，仅用于界面显示。
  final String? current;

  new({
    this.discoverResult = const [],
    this.discoverErrors = const [],
    this.discoverFinished = false,

    this.parseUpdates = const [],
    this.parseSkips = const [],
    this.parseErrors = const [],
    this.parseFinished = false,

    this.current,
  });

  ScanState copyWith({
    List<FileDiscovered>? discoverResult,
    List<FileDiscoveredError>? discoverErrors,
    bool? discoverFinished,

    List<TrackParsed>? parseUpdates,
    List<TrackSkipped>? parseSkips,
    List<TrackParsedError>? parseErrors,
    bool? parseFinished,

    String? current,
  }) {
    return ScanState(
      discoverResult: discoverResult ?? this.discoverResult,
      discoverErrors: discoverErrors ?? this.discoverErrors,
      discoverFinished: discoverFinished ?? this.discoverFinished,

      parseUpdates: parseUpdates ?? this.parseUpdates,
      parseSkips: parseSkips ?? this.parseSkips,
      parseErrors: parseErrors ?? this.parseErrors,
      parseFinished: parseFinished ?? this.parseFinished,

      // TODO(已知): `??` 无法把 current 重置回 null（TrackInfo.copyWith 同理）。
      current: current ?? this.current,
    );
  }

  // TODO(已知，暂缓): 每来一个事件就复制整个列表（[...list, event]），
  // 单次扫描整体是 O(n²)，且每个事件都会通知界面重建。曲目上万时才会有感觉；
  // 到时可改成批量（每 N 个事件/每 50ms 合并一次）。
  ScanState applyDiscover(DiscoverEvent event) {
    switch (event) {
      case FileDiscovered():
        return copyWith(
          discoverResult: [...discoverResult, event],
          current: event.name,
        );
      case FileDiscoveredError():
        return copyWith(
          discoverErrors: [...discoverErrors, event],
          // TODO: Android 的 uri 是 content://...，p.basename 取到的是百分号编码的
          // document id（如 primary%3AMusic%2F...），显示前应 Uri.decodeComponent
          // 并取最后一段。
          current: p.basename(event.uri),
        );
      case FileDiscoveredFinish():
        return copyWith(discoverFinished: true);
    }
  }

  ScanState applyParse(ParseEvent event) {
    switch (event) {
      case TrackParsed():
        return copyWith(
          parseUpdates: [...parseUpdates, event],
          current: event.track.fileName,
        );
      case TrackSkipped():
        return copyWith(
          parseSkips: [...parseSkips, event],
          current: event.track.fileName,
        );
      case TrackParsedError():
        return copyWith(
          parseErrors: [...parseErrors, event],
          current: event.file.name,
        );
      case TrackParsedFinish():
        return copyWith(parseFinished: true);
    }
  }
}
