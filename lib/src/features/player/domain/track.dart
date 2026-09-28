import 'dart:typed_data';

import 'lyrics.dart';
import 'lyrics_source.dart';
import 'visual_analysis.dart';

/// 曲库中最小的可播放单元。
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.artists = const [],
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
    this.addedAt,
    this.modifiedAt,
    this.coverColor = 0xFF263238,
    this.fluidPalette,
    this.beatEnvelope,
  });

  final String id;
  final String title;
  final String artist;

  /// 扫描后拆分出的艺术家列表。为空时兼容旧数据并从 artist 现场拆分。
  final List<String> artists;
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
  final DateTime? addedAt;
  final DateTime? modifiedAt;
  final int coverColor;
  final FluidPalette? fluidPalette;
  final BeatEnvelope? beatEnvelope;

  List<String> get artistNames =>
      artists.isEmpty ? splitArtistNames(artist) : artists;

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
    List<String>? artists,
    String? album,
    Duration? duration,
    String? path,
    int? playCount,
    DateTime? lastPlayedAt,
    DateTime? addedAt,
    DateTime? modifiedAt,
    BeatEnvelope? beatEnvelope,
  }) {
    return Track(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artists: artists ?? this.artists,
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
      addedAt: addedAt ?? this.addedAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      coverColor: coverColor,
      fluidPalette: fluidPalette,
      beatEnvelope: beatEnvelope ?? this.beatEnvelope,
    );
  }
}

/// 按本地音乐标签中常见的多人分隔符拆分艺术家名称。
List<String> splitArtistNames(String value) {
  final names = value
      .split(RegExp(r'\s*[/、;&]\s*'))
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  return names.isEmpty ? const ['未知艺术家'] : names;
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
