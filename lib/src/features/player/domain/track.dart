import 'dart:typed_data';

import 'lyrics.dart';
import 'lyrics_source.dart';

/// 曲库中最小的可播放单元。
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.path,
    this.coverBytes,
    this.lyrics,
    this.lyricsFormat,
    this.lyricsSources = const [],
    this.replayGainDb,
    this.replayGainMode,
    this.metadata = const {},
    this.playCount = 0,
    this.lastPlayedAt,
    this.coverColor = 0xFF263238,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? path;
  final Uint8List? coverBytes;
  final String? lyrics;
  final String? lyricsFormat;
  final List<LyricsSource> lyricsSources;
  final double? replayGainDb;

  /// 记录当前增益来自曲目标签还是专辑标签，供 mpv 选择正确模式。
  final String? replayGainMode;

  /// 扫描时读取到的原始元数据，供音轨详情展示。
  final Map<String, String> metadata;
  final int playCount;
  final DateTime? lastPlayedAt;
  final int coverColor;

  /// 统一的歌词文档，供各个界面直接消费，避免渲染层重复解析原始文本。
  LyricsDocument get lyricsDocument {
    final sources = lyricsSources.isEmpty && lyrics != null
        ? [
            LyricsSource(
              content: lyrics!,
              kind: LyricsSourceKind.embedded,
              extension: lyricsFormat,
            ),
          ]
        : lyricsSources;
    return parseLyricsSources(sources);
  }

  Track copyWith({
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? path,
    int? playCount,
    DateTime? lastPlayedAt,
  }) {
    return Track(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      path: path ?? this.path,
      coverBytes: coverBytes,
      lyrics: lyrics,
      lyricsFormat: lyricsFormat,
      lyricsSources: lyricsSources,
      replayGainDb: replayGainDb,
      replayGainMode: replayGainMode,
      metadata: metadata,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      coverColor: coverColor,
    );
  }
}

const demoTracks = [
  Track(
    id: 'demo-1',
    title: '雾中回声',
    artist: '伶伦 Demo',
    album: '未命名的夜晚',
    duration: Duration(minutes: 4, seconds: 18),
    coverColor: 0xFF315A61,
  ),
  Track(
    id: 'demo-2',
    title: '远山来信',
    artist: '伶伦 Demo',
    album: '未命名的夜晚',
    duration: Duration(minutes: 3, seconds: 42),
    coverColor: 0xFF5F4B62,
  ),
  Track(
    id: 'demo-3',
    title: '月光下的留白',
    artist: '林间回响',
    album: '薄暮',
    duration: Duration(minutes: 5, seconds: 7),
    coverColor: 0xFF806044,
  ),
  Track(
    id: 'demo-4',
    title: '潮汐之后',
    artist: '林间回响',
    album: '薄暮',
    duration: Duration(minutes: 3, seconds: 56),
    coverColor: 0xFF3C536D,
  ),
];
