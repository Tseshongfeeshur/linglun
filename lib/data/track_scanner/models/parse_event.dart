// ===== 解析阶段（读标签，较慢）的事件 =====
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/discover_event.dart';

sealed class ParseEvent {}

/// 新增或已变化的曲目（也用于"库里有、这次没发现"的曲目，此时 removed == true）。
class TrackParsed extends ParseEvent {
  /// 曲目的"身份"，用来在多次扫描之间认出同一个文件：
  /// Linux 为绝对路径；Android 为 SAF 的 document id（与通过哪个目录授权无关）。
  /// 注意它和 uri 不是一回事——uri 可能因授权方式不同而变化。
  final String sourceKey;

  final String title;
  final Collation titleCollation;

  // artists 不可空，无艺术家时为空列表。
  // artistCollations 是每位艺术家的 collation，因为需要入库。
  final List<String> artists;
  final List<Collation> artistCollations;

  final String? album;
  final Collation albumCollation;
  final String? albumArtist;
  final Collation? albumArtistCollation;

  /// 读取/播放用的地址：Linux 是文件路径，Android 是 content:// URI。
  final String uri;
  final String fileName;

  // 字节数。平台取不到时可能是 -1（扫描器的"是否未变"判断依赖这个约定）。
  final int sizeBytes;
  final int durationMs;
  final DateTime editTime;

  new({
    required this.sourceKey,
    required this.title,
    required this.titleCollation,
    required this.artists,
    required this.artistCollations,
    this.album,
    required this.albumCollation,
    this.albumArtist,
    this.albumArtistCollation,
    required this.uri,
    required this.fileName,
    required this.sizeBytes,
    required this.durationMs,
    required this.editTime,
  }) : assert((albumArtist == null) == (albumArtistCollation == null));
}

/// 与库里记录一致、无需重新解析的曲目（沿用旧记录）。
class TrackSkipped extends ParseEvent {
  /// 曲目的"身份"，用来在多次扫描之间认出同一个文件：
  /// Linux 为绝对路径；Android 为 SAF 的 document id（与通过哪个目录授权无关）。
  /// 注意它和 uri 不是一回事——uri 可能因授权方式不同而变化。
  final String sourceKey;

  /// 读取/播放用的地址：Linux 是文件路径，Android 是 content:// URI。
  final String uri;
  final String fileName;

  new({required this.sourceKey, required this.uri, required this.fileName});
}

/// 被移除的曲目。
class TrackMissed extends ParseEvent {
  /// 曲目的"身份"，用来在多次扫描之间认出同一个文件：
  /// Linux 为绝对路径；Android 为 SAF 的 document id（与通过哪个目录授权无关）。
  /// 注意它和 uri 不是一回事——uri 可能因授权方式不同而变化。
  final String sourceKey;
  final String fileName;

  new({required this.sourceKey, required this.fileName});
}

class TrackParsedError extends ParseEvent {
  final FileDiscovered file;
  final String detail;
  new({required this.file, required this.detail});
}

class TrackParsedFinish extends ParseEvent {}
