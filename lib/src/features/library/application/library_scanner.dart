import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

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
      final track = _readTrack(file);
      if (track != null) tracks.add(track);
    }

    tracks.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return tracks;
  }

  Track? _readTrack(File file) {
    try {
      final metadata = readMetadata(file, getImage: false);
      final fallbackTitle = _fileNameWithoutExtension(file.path);
      return Track(
        id: file.path,
        path: file.path,
        title: _clean(metadata.title) ?? fallbackTitle,
        artist: _clean(metadata.artist) ?? '未知艺术家',
        album: _clean(metadata.album) ?? '未知专辑',
        duration: metadata.duration ?? Duration.zero,
        coverColor: _colorForPath(file.path),
      );
    } on Object {
      // 损坏或暂不支持的文件不应中断整个曲库扫描。
      return null;
    }
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
