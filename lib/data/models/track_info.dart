class TextKey {
  final String group; // 分组键，如 'A'、'か'、'ㄱ'、'#'
  final String sort; // 组内排序键

  const new({required this.group, required this.sort});

  TextKey copyWith({String? group, String? sort}) {
    return TextKey(group: group ?? this.group, sort: sort ?? this.sort);
  }
}

class TrackInfo {
  // final int id;
  final String sourceKey;

  final String title;
  final TextKey titleKey;

  final List<String>? artists;
  final List<TextKey> artistsKeys;

  final String? album;
  final TextKey albumKey;

  final String uri;
  final String fileName;

  final int sizeBytes;
  final int durationMs;
  final DateTime editTime;
  final bool trackGainUpdated;

  final int playCount;
  final DateTime addTime;
  final bool removed;

  const new({
    required this.sourceKey,
    required this.title,
    required this.titleKey,
    this.artists,
    required this.artistsKeys,
    this.album,
    required this.albumKey,
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

  TrackInfo copyWith({
    String? sourceKey,
    String? title,
    TextKey? titleKey,
    List<String>? artists,
    List<TextKey>? artistsKeys,
    String? album,
    TextKey? albumKey,
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
      titleKey: titleKey ?? this.titleKey,
      artists: artists ?? this.artists,
      artistsKeys: artistsKeys ?? this.artistsKeys,
      album: album ?? this.album,
      albumKey: albumKey ?? this.albumKey,
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
