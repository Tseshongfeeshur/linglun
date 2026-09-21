import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
// ignore: implementation_imports
import 'package:audio_metadata_reader/src/metadata/base.dart'
    show
        ApeMetadata,
        Mp3Metadata,
        Mp4Metadata,
        ParserTag,
        RiffMetadata,
        VorbisMetadata;

import '../../player/domain/track.dart';

const supportedAudioExtensions = {
  '.mp3',
  '.flac',
  '.m4a',
  '.aac',
  '.ogg',
  '.opus',
  '.wav',
};

/// 递归扫描目录并将音频文件转换成应用层的曲目模型。
class LibraryScanner {
  Future<List<Track>> scan(Iterable<String> rootPaths) async {
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
        if (visited.add(entity.path)) files.add(entity);
      }
    }

    final tracks = <Track>[];
    for (final file in files) {
      final track = await _readTrack(file);
      if (track != null) tracks.add(track);
    }

    tracks.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return tracks;
  }

  Future<Track?> _readTrack(File file) async {
    try {
      final metadata = readMetadata(file, getImage: true);
      final detailed = readAllMetadata(file, getImage: true);
      final fallbackTitle = _fileNameWithoutExtension(file.path);
      final sidecarLyrics = await _readSidecarLyrics(file);
      return Track(
        id: file.path,
        path: file.path,
        coverBytes: metadata.pictures.isEmpty
            ? null
            : metadata.pictures.first.bytes,
        title: _clean(metadata.title) ?? fallbackTitle,
        artist: _clean(metadata.artist) ?? '未知艺术家',
        album: _clean(metadata.album) ?? '未知专辑',
        duration: metadata.duration ?? Duration.zero,
        lyrics: sidecarLyrics?.content ?? metadata.lyrics,
        lyricsFormat: sidecarLyrics?.extension ?? 'lrc',
        replayGainDb: _replayGainDb(detailed),
        coverColor: _colorForPath(file.path),
      );
    } on Object {
      // 损坏或暂不支持的文件不应中断整个曲库扫描。
      return null;
    }
  }

  Future<({String content, String extension})?> _readSidecarLyrics(
    File audioFile,
  ) async {
    final basePath = audioFile.path.substring(
      0,
      audioFile.path.lastIndexOf('.'),
    );
    for (final extension in const ['.lrc', '.elrc', '.ass', '.srt', '.vtt']) {
      final file = File('$basePath$extension');
      if (await file.exists()) {
        return (content: await file.readAsString(), extension: extension);
      }
    }
    return null;
  }

  double? _replayGainDb(ParserTag metadata) {
    String? value;
    switch (metadata) {
      case VorbisMetadata m:
        value =
            m.replayGainTrackGain.firstOrNull ??
            m.replayGainAlbumGain.firstOrNull;
      case Mp3Metadata m:
        value =
            m.customMetadata['REPLAYGAIN_TRACK_GAIN'] ??
            m.customMetadata['REPLAYGAIN_ALBUM_GAIN'];
      case Mp4Metadata():
        value = null;
      case RiffMetadata():
        value = null;
      case ApeMetadata():
        value = null;
    }
    if (value == null) return null;
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9+\-.]'), ''));
  }

  String _extension(String path) =>
      path.substring(path.lastIndexOf('.')).toLowerCase();

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
