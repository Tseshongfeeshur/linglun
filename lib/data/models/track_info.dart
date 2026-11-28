/// 一个名字（标题 / 歌手 / 专辑）的分组键与组内排序键。
/// 扫描时一次算好，规则见 data/utils/collation_of.dart。
class Collation {
  final String group; // 分组键，如 'A'、'か'、'ㄱ'、'#'
  final String sort; // 组内排序键

  const new({required this.group, required this.sort});

  Collation copyWith({String? group, String? sort}) {
    return Collation(group: group ?? this.group, sort: sort ?? this.sort);
  }
}

/// 曲库里的一首歌（不可变）。扫描器产出，Riverpod 里整体替换。
class TrackInfo {
  /// 曲目的"身份"，用来在多次扫描之间认出同一个文件：
  /// Linux 为绝对路径；Android 为 SAF 的 document id（与通过哪个目录授权无关）。
  /// 注意它和 uri 不是一回事——uri 可能因授权方式不同而变化。
  final String sourceKey;

  final String title;
  final Collation titleCollation;

  // artists 不可空，无艺术家时为空列表。
  // artistCollation 依据为首位歌手，仅供歌曲排序使用。
  final List<String> artists;
  final Collation artistCollation;

  final String? album;
  final Collation albumCollation;
  final String? albumArtist;

  /// 读取/播放用的地址：Linux 是文件路径，Android 是 content:// URI。
  final String uri;
  final String fileName;

  // 字节数。平台取不到时可能是 -1（扫描器的"是否未变"判断依赖这个约定）。
  final int sizeBytes;
  final int durationMs;
  final DateTime editTime;
  // 是否已把播放增益写回文件标签（库里只存这个标志，不存增益值）。
  final bool trackGainUpdated;

  // 完整播放结束才 +1；文件变化重新解析时沿用旧值。
  final int playCount;
  // 首次扫描入库的时间；重新解析时沿用旧值。
  final DateTime addTime;
  // 库里有、但磁盘上这次没找到：保留记录（以免丢掉 playCount 等数据）并标记。
  final bool removed;

  const new({
    required this.sourceKey,
    required this.title,
    required this.titleCollation,
    required this.artists,
    required this.artistCollation,
    this.album,
    required this.albumCollation,
    this.albumArtist,
    required this.uri,
    required this.fileName,
    required this.sizeBytes,
    required this.durationMs,
    required this.editTime,
    required this.trackGainUpdated,
    required this.playCount,
    required this.addTime,
    required this.removed,
  });

  // TODO: 可空字段（album）用 `x ?? this.x` 实现，
  // 无法通过 copyWith 把它们重置为 null（ScanState.copyWith 同理）。
  // 真需要时可改用哨兵值，或单独写 withoutAlbum() 之类的方法。
  TrackInfo copyWith({
    String? sourceKey,
    String? title,
    Collation? titleCollation,
    List<String>? artists,
    Collation? artistCollation,
    String? album,
    Collation? albumCollation,
    String? albumArtist,
    String? uri,
    String? fileName,
    int? sizeBytes,
    int? durationMs,
    DateTime? editTime,
    bool? trackGainUpdated,
    int? playCount,
    DateTime? addTime,
    bool? removed,
  }) {
    return TrackInfo(
      sourceKey: sourceKey ?? this.sourceKey,
      title: title ?? this.title,
      titleCollation: titleCollation ?? this.titleCollation,
      artists: artists ?? this.artists,
      artistCollation: artistCollation ?? this.artistCollation,
      album: album ?? this.album,
      albumCollation: albumCollation ?? this.albumCollation,
      albumArtist: albumArtist ?? this.albumArtist,
      uri: uri ?? this.uri,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationMs: durationMs ?? this.durationMs,
      editTime: editTime ?? this.editTime,
      trackGainUpdated: trackGainUpdated ?? this.trackGainUpdated,
      playCount: playCount ?? this.playCount,
      addTime: addTime ?? this.addTime,
      removed: removed ?? this.removed,
    );
  }
}
