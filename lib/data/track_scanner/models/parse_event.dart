// ===== 解析阶段（读标签，较慢）的事件 =====
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/discover_event.dart';

sealed class ParseEvent {}

/// 新增或已变化的曲目（也用于"库里有、这次没发现"的曲目，此时 removed == true）。
class TrackParsed extends ParseEvent {
  final TrackInfo track;
  new({required this.track});
}

/// 与库里记录一致、无需重新解析的曲目（沿用旧记录）。
class TrackSkipped extends ParseEvent {
  final TrackInfo track;
  new({required this.track});
}

class TrackParsedError extends ParseEvent {
  final FileDiscovered file;
  final String detail;
  new({required this.file, required this.detail});
}

class TrackParsedFinish extends ParseEvent {}
