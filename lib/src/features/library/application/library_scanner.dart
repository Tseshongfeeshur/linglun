import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as path_util;
// ignore: implementation_imports
import 'package:audio_metadata_reader/src/metadata/base.dart'
    show
        ApeMetadata,
        Mp3Metadata,
        Mp4Metadata,
        ParserTag,
        PictureType,
        RiffMetadata,
        VorbisMetadata;

import '../../player/domain/track.dart';
import '../../player/domain/lyrics_source.dart';
import '../../player/domain/lyrics.dart';

const supportedAudioExtensions = {
  '.mp3',
  '.flac',
  '.m4a',
  '.aac',
  '.ogg',
  '.opus',
  '.wav',
  '.aif',
  '.aiff',
  '.oga',
  '.webm',
};

const _oggExtensions = {'.ogg', '.oga', '.opus'};
const _opusGranuleRate = 48000;

class _OggPage {
  const _OggPage({
    required this.headerType,
    required this.granule,
    required this.serial,
    required this.payload,
  });

  final int headerType;
  final int granule;
  final int serial;
  final Uint8List payload;
}

/// 递归扫描目录并将音频文件转换成应用层的曲目模型。
class LibraryScanner {
  Future<List<Track>> scan(Iterable<String> rootPaths) async {
    final scanTime = DateTime.now();
    final files = <File>[];
    final visited = <String>{};

    for (final rootPath in rootPaths) {
      final root = Directory(rootPath);
      if (!root.existsSync()) continue;

      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final extension = _extension(entity.path);
        if (!supportedAudioExtensions.contains(extension)) continue;
        final normalizedPath = path_util.normalize(
          File(entity.path).absolute.path,
        );
        if (visited.add(normalizedPath)) files.add(File(normalizedPath));
      }
    }

    final tracks = <Track>[];
    for (final file in files) {
      final track = await _readTrack(file, addedAt: scanTime);
      if (track != null) tracks.add(track);
    }

    tracks.sort((a, b) {
      final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (byTitle != 0) return byTitle;
      return (a.path ?? '').toLowerCase().compareTo(
        (b.path ?? '').toLowerCase(),
      );
    });
    return tracks;
  }

  Future<Track?> _readTrack(File file, {required DateTime addedAt}) async {
    try {
      final modifiedAt = (await file.stat()).modified;
      final detailed = readAllMetadata(file, getImage: true);
      final metadata = _summaryMetadata(file, detailed);
      final preciseDuration = _readOpusOggDuration(file);
      if (preciseDuration != null) {
        // Opus 的 Ogg 粒度位置使用固定的 48 kHz 时钟，不能使用
        // OpusHead 中记录的输入采样率替代。第三方元数据解析器在此处
        // 会把 44.1 kHz 当成时钟，导致同一文件的时长被放大。
        metadata.duration = preciseDuration;
      }
      final fallbackTitle = _fileNameWithoutExtension(file.path);
      final sidecarLyrics = await _readSidecarLyrics(file);
      final sources = <LyricsSource>[
        ...sidecarLyrics,
        ..._embeddedLyrics(detailed, metadata.lyrics),
      ];
      final selectedLyrics = selectLyricsSource(sources);
      final replayGain = _replayGainInfo(detailed);
      return Track(
        id: file.path,
        path: file.path,
        coverBytes: _coverBytes(detailed),
        title: _clean(metadata.title) ?? fallbackTitle,
        artist: _clean(metadata.artist) ?? '未知艺术家',
        album: _clean(metadata.album) ?? '未知专辑',
        duration: metadata.duration ?? Duration.zero,
        lyrics: selectedLyrics?.content,
        // 内嵌歌词没有外挂文件扩展名，交给解析器根据内容自动识别语法。
        lyricsFormat: selectedLyrics?.extension,
        lyricsSources: sources,
        replayGainDb: replayGain.db,
        replayGainMode: replayGain.mode,
        coverColor: _colorForPath(file.path),
        addedAt: addedAt,
        modifiedAt: modifiedAt,
        metadata: _metadataMap(
          file,
          detailed,
          metadata,
          addedAt: addedAt,
          modifiedAt: modifiedAt,
        ),
      );
    } on Object {
      // 损坏或暂不支持的文件不应中断整个曲库扫描。
      return null;
    }
  }

  /// 从 Ogg 页尾粒度位置读取 Opus 的精确时长。
  ///
  /// Opus 在 Ogg 容器中的 granule position 始终以 48 kHz 为单位；输入
  /// 采样率只描述编码前的音频，不能用于换算容器时长。这里只处理首个
  /// 逻辑流为 Opus 的 Ogg 文件，其他格式继续使用元数据读取器的结果。
  Duration? _readOpusOggDuration(File file) {
    if (!_oggExtensions.contains(_extension(file.path))) return null;

    RandomAccessFile? reader;
    try {
      reader = file.openSync();
      final firstPage = _readOggPage(reader, readPayload: true);
      if (firstPage == null || !_isOpusHead(firstPage.payload)) return null;

      final streamSerial = firstPage.serial;
      var lastGranule = _validOggGranule(firstPage.granule);
      while (true) {
        final page = _readOggPage(reader, readPayload: false);
        if (page == null) break;
        if (page.serial == streamSerial) {
          final granule = _validOggGranule(page.granule);
          if (granule != null) lastGranule = granule;
          if (page.headerType & 0x04 != 0) break;
        }
      }

      if (lastGranule == null) return null;
      return Duration(
        microseconds:
            (lastGranule * Duration.microsecondsPerSecond / _opusGranuleRate)
                .round(),
      );
    } on Object {
      // 个别损坏的 Ogg 文件仍应保留第三方解析器给出的时长。
      return null;
    } finally {
      reader?.closeSync();
    }
  }

  _OggPage? _readOggPage(RandomAccessFile reader, {required bool readPayload}) {
    final header = reader.readSync(27);
    if (header.length != 27 || !_hasBytes(header, [0x4F, 0x67, 0x67, 0x53])) {
      return null;
    }
    if (header[4] != 0) return null;

    final segmentCount = header[26];
    final segmentTable = reader.readSync(segmentCount);
    if (segmentTable.length != segmentCount) return null;
    var payloadLength = 0;
    for (final segmentLength in segmentTable) {
      payloadLength += segmentLength;
    }

    final payload = readPayload ? reader.readSync(payloadLength) : Uint8List(0);
    if (readPayload && payload.length != payloadLength) return null;
    if (!readPayload && payloadLength > 0) {
      reader.setPositionSync(reader.positionSync() + payloadLength);
    }

    return _OggPage(
      headerType: header[5],
      granule: _readLittleEndianUint64(header, 6),
      serial: _readLittleEndianUint32(header, 14),
      payload: payload,
    );
  }

  bool _isOpusHead(Uint8List payload) {
    const signature = [0x4F, 0x70, 0x75, 0x73, 0x48, 0x65, 0x61, 0x64];
    return payload.length >= signature.length && _hasBytes(payload, signature);
  }

  bool _hasBytes(List<int> value, List<int> expected) {
    if (value.length < expected.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (value[index] != expected[index]) return false;
    }
    return true;
  }

  int _readLittleEndianUint32(List<int> bytes, int offset) {
    var value = 0;
    for (var index = 0; index < 4; index++) {
      value |= bytes[offset + index] << (index * 8);
    }
    return value;
  }

  int _readLittleEndianUint64(List<int> bytes, int offset) {
    var value = 0;
    for (var index = 0; index < 8; index++) {
      value |= bytes[offset + index] << (index * 8);
    }
    return value;
  }

  int? _validOggGranule(int value) {
    // UINT64_MAX 表示当前页没有可用的 granule position。
    return value == 0xFFFFFFFFFFFFFFFF ? null : value;
  }

  AudioMetadata _summaryMetadata(File file, ParserTag detailed) {
    final metadata = switch (detailed) {
      VorbisMetadata m => AudioMetadata(
        file: file,
        album: m.album.firstOrNull,
        artist: m.artist.firstOrNull,
        duration: m.duration,
        lyrics: m.lyric,
        sampleRate: m.sampleRate,
        title: m.title.firstOrNull,
        bitrate: m.bitrate,
        trackNumber: m.trackNumber.firstOrNull,
        trackTotal: m.trackTotal,
        discNumber: m.discNumber,
        totalDisc: m.discTotal,
        year: m.date.firstOrNull,
      ),
      Mp3Metadata m => AudioMetadata(
        file: file,
        album: m.album,
        artist: m.leadPerformer ?? m.bandOrOrchestra ?? m.originalArtist,
        duration: m.duration,
        lyrics: m.lyric,
        sampleRate: m.samplerate,
        title: m.songName,
        bitrate: m.bitrate,
        trackNumber: m.trackNumber,
        trackTotal: m.trackTotal,
        discNumber: m.discNumber,
        totalDisc: m.totalDics,
        year: m.originalReleaseYear == null && m.year == null
            ? null
            : DateTime(m.originalReleaseYear ?? m.year!),
      ),
      Mp4Metadata m => AudioMetadata(
        file: file,
        album: m.album,
        artist: m.artist,
        duration: m.duration,
        lyrics: m.lyrics,
        sampleRate: m.sampleRate,
        title: m.title,
        bitrate: m.bitrate,
        trackNumber: m.trackNumber,
        trackTotal: m.totalTracks,
        discNumber: m.discNumber,
        totalDisc: m.totalDiscs,
        year: m.year,
      ),
      ApeMetadata m => AudioMetadata(
        file: file,
        album: m.album,
        artist: m.artist,
        duration: m.duration,
        lyrics: m.lyric,
        sampleRate: m.sampleRate,
        title: m.title,
        bitrate: m.bitrate,
        trackNumber: m.trackNumber,
        trackTotal: m.trackTotal,
        discNumber: m.discNumber,
        totalDisc: m.discTotal,
        year: m.date,
      ),
      RiffMetadata m => AudioMetadata(
        file: file,
        album: m.album,
        artist: m.artist,
        duration: m.duration,
        sampleRate: m.samplerate,
        title: m.title,
        bitrate: m.bitrate,
        trackNumber: m.trackNumber,
        year: m.year,
      ),
    };

    switch (detailed) {
      case VorbisMetadata m:
        metadata.albumArtist = m.albumArtist.firstOrNull;
        metadata.genres = m.genres;
        metadata.pictures = m.pictures;
        break;
      case Mp3Metadata m:
        metadata.genres = m.genres;
        metadata.pictures = m.pictures;
        break;
      case Mp4Metadata m:
        metadata.genres = m.genre == null ? [] : [m.genre!];
        metadata.pictures = m.picture == null ? [] : [m.picture!];
        break;
      case ApeMetadata m:
        metadata.genres = m.genres;
        metadata.pictures = m.pictures;
        break;
      case RiffMetadata m:
        metadata.genres = m.genre == null ? [] : [m.genre!];
        metadata.pictures = m.pictures;
        break;
    }
    return metadata;
  }

  Future<List<LyricsSource>> _readSidecarLyrics(File audioFile) async {
    const extensions = [
      '.lrc',
      '.elrc',
      '.qrc',
      '.yrc',
      '.krc',
      '.ttml',
      '.xml',
      '.ass',
      '.ssa',
      '.srt',
      '.vtt',
      '.txt',
    ];
    final stem = path_util
        .basenameWithoutExtension(audioFile.path)
        .toLowerCase();
    final candidates = <String, File>{};
    try {
      await for (final entity in audioFile.parent.list(followLinks: false)) {
        if (entity is! File) continue;
        final entityStem = path_util
            .basenameWithoutExtension(entity.path)
            .toLowerCase();
        if (entityStem != stem) continue;
        final extension = path_util.extension(entity.path).toLowerCase();
        if (extensions.contains(extension)) {
          candidates[extension] = entity;
        }
      }
    } on Object {
      // 外挂歌词目录无权限时保留内嵌歌词，不能丢弃整首歌曲。
    }

    final sources = <LyricsSource>[];
    for (final extension in extensions) {
      final file = candidates[extension];
      if (file == null) continue;
      try {
        sources.add(
          LyricsSource(
            content: await file.readAsString(),
            kind: LyricsSourceKind.sidecar,
            extension: extension,
          ),
        );
      } on Object {
        // 单个歌词文件损坏或不可读时继续尝试其他来源。
      }
    }
    return sources;
  }

  ({double? db, String? mode}) _replayGainInfo(ParserTag metadata) {
    String? trackValue;
    String? albumValue;
    switch (metadata) {
      case VorbisMetadata m:
        trackValue = m.replayGainTrackGain.firstOrNull;
        albumValue = m.replayGainAlbumGain.firstOrNull;
      case Mp3Metadata m:
        trackValue = _customMetadataValue(
          m.customMetadata,
          'REPLAYGAIN_TRACK_GAIN',
        );
        albumValue = _customMetadataValue(
          m.customMetadata,
          'REPLAYGAIN_ALBUM_GAIN',
        );
      case Mp4Metadata():
        break;
      case RiffMetadata():
        break;
      case ApeMetadata m:
        trackValue = _customMetadataValue(m.unknowns, 'REPLAYGAIN_TRACK_GAIN');
        albumValue = _customMetadataValue(m.unknowns, 'REPLAYGAIN_ALBUM_GAIN');
    }
    final trackDb = _parseGainDb(trackValue);
    if (trackDb != null) return (db: trackDb, mode: 'track');
    final albumDb = _parseGainDb(albumValue);
    return (db: albumDb, mode: albumDb == null ? null : 'album');
  }

  double? _parseGainDb(String? value) {
    if (value == null) return null;
    final match = RegExp(r'[+-]?\d+(?:\.\d+)?').firstMatch(value);
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  List<LyricsSource> _embeddedLyrics(
    ParserTag detailed,
    String? genericLyrics,
  ) {
    final candidates = <LyricsSource>[];

    void add(String? value, {String tagName = 'LYRIC', String? language}) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      if (candidates.any(
        (candidate) =>
            candidate.content == text && candidate.tagName == tagName,
      )) {
        return;
      }
      final normalizedTag = tagName.toUpperCase();
      candidates.add(
        LyricsSource(
          content: text,
          kind: LyricsSourceKind.embedded,
          tagName: tagName,
          language: language ?? _lyricsLanguage(tagName),
          role: _lyricsRole(normalizedTag),
        ),
      );
    }

    add(genericLyrics);
    switch (detailed) {
      case VorbisMetadata m:
        add(m.lyric, tagName: 'LYRIC');
        _addLyricTags(m.unknowns, add);
        break;
      case Mp3Metadata m:
        add(m.lyric, tagName: 'LYRIC');
        _addLyricTags(m.customMetadata, add);
        break;
      case Mp4Metadata m:
        add(m.lyrics, tagName: 'LYRIC');
        break;
      case ApeMetadata m:
        add(m.lyric, tagName: 'LYRIC');
        _addLyricTags(m.unknowns, add);
        break;
      case RiffMetadata m:
        _addLyricTags(m.unknowns, add);
        break;
    }
    return candidates;
  }

  void _addLyricTags(
    Map<String, String> values,
    void Function(String?, {String tagName, String? language}) add,
  ) {
    for (final entry in values.entries) {
      final normalized = entry.key.toUpperCase().replaceAll(
        RegExp(r'[\s_.:-]'),
        '',
      );
      if (_isLyricsTag(normalized)) {
        add(entry.value, tagName: entry.key);
      }
    }
  }

  bool _isLyricsTag(String key) {
    return key == 'LYRIC' ||
        key.startsWith('LYRICS') ||
        key.startsWith('SYNCEDLYRICS') ||
        key.startsWith('UNSYNCEDLYRICS') ||
        key.startsWith('USLT') ||
        key.startsWith('SYLT') ||
        key.startsWith('LRC') ||
        key.startsWith('QRC') ||
        key.startsWith('YRC') ||
        key.startsWith('KRC') ||
        key.startsWith('TTML');
  }

  LyricRole _lyricsRole(String normalizedTag) {
    if (normalizedTag.contains('TRANSLAT') ||
        normalizedTag.contains('译') ||
        normalizedTag.contains('翻译')) {
      return LyricRole.translation;
    }
    if (normalizedTag.contains('ROMAN') || normalizedTag.contains('ROMAJI')) {
      return LyricRole.alternate;
    }
    return LyricRole.original;
  }

  String? _lyricsLanguage(String tagName) {
    final match = RegExp(
      r'(?:^|[\s._:-])([a-z]{2,3}(?:[-_][a-z]{2})?)(?:$|[\s._:-])',
      caseSensitive: false,
    ).firstMatch(tagName);
    return match?.group(1)?.toLowerCase();
  }

  Map<String, String> _metadataMap(
    File file,
    ParserTag detailed,
    AudioMetadata generic, {
    required DateTime addedAt,
    required DateTime modifiedAt,
  }) {
    final values = <String, String>{'文件路径': file.path};

    void add(String key, Object? value) {
      final text = _formatMetadataValue(value);
      if (text != null) values[key] = text;
    }

    add('文件格式', _extension(file.path).replaceFirst('.', '').toUpperCase());
    add('标题', generic.title);
    add('艺术家', generic.artist);
    add('专辑', generic.album);
    add('专辑艺术家', generic.albumArtist);
    add('时长', generic.duration);
    add('采样率', generic.sampleRate == null ? null : '${generic.sampleRate} Hz');
    add('比特率', generic.bitrate == null ? null : '${generic.bitrate} bit/s');
    add('加入曲库时间', addedAt);
    add('文件修改时间', modifiedAt);

    switch (detailed) {
      case VorbisMetadata m:
        add('标签类型', 'Vorbis 注释 / Ogg');
        add('版本', m.version);
        add('曲目号', m.trackNumber);
        add('总曲目数', m.trackTotal);
        add('碟片号', m.discNumber);
        add('总碟片数', m.discTotal);
        add('流派', m.genres);
        add('发行日期', m.date);
        add('表演者', m.performer);
        add('作曲者', m.composer);
        add('评论', m.comment);
        add('描述', m.description);
        add('语言', m.language);
        add('编码器', m.encoder);
        add('编码工具', m.encodedUsing);
        add('编码选项', m.encoderOptions);
        add('厂商', m.vendor);
        add('版权', m.copyright);
        add('ReplayGain 曲目增益', m.replayGainTrackGain);
        add('ReplayGain 专辑增益', m.replayGainAlbumGain);
        add('内嵌歌词', m.lyric);
        for (final entry in m.unknowns.entries) {
          add(entry.key, entry.value);
        }
        break;
      case Mp3Metadata m:
        add('标签类型', 'ID3 / MP3');
        add('曲目号', m.trackNumber);
        add('总曲目数', m.trackTotal);
        add('碟片号', m.discNumber);
        add('总碟片数', m.totalDics);
        add('流派', m.genres);
        add('作曲者', m.composer);
        add('编码器', m.encoderSoftware);
        add('发行年份', m.year);
        add('内嵌歌词', m.lyric);
        for (final entry in m.customMetadata.entries) {
          add(entry.key, entry.value);
        }
        break;
      case Mp4Metadata m:
        add('标签类型', 'MP4 / M4A');
        add('曲目号', m.trackNumber);
        add('总曲目数', m.totalTracks);
        add('碟片号', m.discNumber);
        add('总碟片数', m.totalDiscs);
        add('流派', m.genre);
        add('发行日期', m.year);
        add('内嵌歌词', m.lyrics);
        break;
      case ApeMetadata m:
        add('标签类型', 'APEv2');
        add('曲目号', m.trackNumber);
        add('总曲目数', m.trackTotal);
        add('碟片号', m.discNumber);
        add('总碟片数', m.discTotal);
        add('流派', m.genres);
        add('表演者', m.performer);
        add('作曲者', m.composer);
        add('评论', m.comment);
        add('编码器', m.encodedBy);
        add('内嵌歌词', m.lyric);
        for (final entry in m.unknowns.entries) {
          add(entry.key, entry.value);
        }
        break;
      case RiffMetadata m:
        add('标签类型', 'RIFF / WAV');
        add('曲目号', m.trackNumber);
        add('流派', m.genre);
        add('编码器', m.encoder);
        add('出版者', m.publisher);
        add('评论', m.comment);
        for (final entry in m.unknowns.entries) {
          add(entry.key, entry.value);
        }
        break;
    }

    final pictures = _pictures(detailed);
    add(
      '封面',
      pictures.isEmpty
          ? '未读取到内嵌封面'
          : pictures
                .map(
                  (picture) =>
                      '${picture.pictureType}，${picture.mimetype}，${picture.bytes.length} 字节',
                )
                .join('\n'),
    );
    return values;
  }

  String? _formatMetadataValue(Object? value) {
    if (value == null) return null;
    if (value is Iterable) {
      final items = value
          .map(_formatMetadataValue)
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
      return items.isEmpty ? null : items.join(' / ');
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Uint8List? _coverBytes(ParserTag metadata) {
    final pictures = _pictures(metadata)
        .where((picture) => picture.bytes.isNotEmpty)
        .toList();
    if (pictures.isEmpty) return null;
    return pictures
        .firstWhere(
          (picture) => picture.pictureType == PictureType.coverFront,
          orElse: () => pictures.first,
        )
        .bytes;
  }

  List<Picture> _pictures(ParserTag metadata) {
    return switch (metadata) {
      VorbisMetadata m => m.pictures,
      Mp3Metadata m => m.pictures,
      ApeMetadata m => m.pictures,
      Mp4Metadata m => m.picture == null ? const [] : [m.picture!],
      RiffMetadata m => m.pictures,
    };
  }

  String? _customMetadataValue(Map<String, String> metadata, String key) {
    for (final entry in metadata.entries) {
      if (entry.key.toUpperCase() == key) return entry.value;
    }
    return null;
  }

  String _extension(String path) {
    final extension = path_util.extension(path).toLowerCase();
    return extension;
  }

  String _fileNameWithoutExtension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }

  int _colorForPath(String path) {
    final value = path.codeUnits.fold<int>(
      17,
      (hash, code) => hash * 31 + code,
    );
    final colors = const [0xFF315A61, 0xFF5F4B62, 0xFF806044, 0xFF3C536D];
    return colors[value.abs() % colors.length];
  }
}
