import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:haudiotagger/haudiotagger.dart';

import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/track_scanner/utils/string_to_latin.dart';
import 'package:linglun/data/track_scanner/utils/artist_splitter.dart';

sealed class ScanEvent {}

class TracksDiscovered {
  final List<String> paths;
  final List<String> errorPaths;
  new({required this.paths, required this.errorPaths});
}

class TrackScanned extends ScanEvent {
  final TrackInfo track;
  new({required this.track});
}

class TrackSkipped extends ScanEvent {
  final String path;
  new({required this.path});
}

class TrackScannedError extends ScanEvent {
  final String path;
  final String detail;
  new({required this.path, required this.detail});
}

class TrackScannedFinish extends ScanEvent {
  final List<TrackInfo> tracks;
  new({required this.tracks});
}

class TrackScanner {
  static const _extensions = {'.mp3', '.flac', '.m4a', '.ogg', '.opus', '.wav'};

  Future<TracksDiscovered> discover(List<String> rootPaths) async {
    // TODO: 确保打断后能停止
    final Set<String> paths = {};
    final List<String> errorPaths = [];

    for (final String path in rootPaths) {
      final dir = Directory(path);
      await for (final item
          in dir.list(followLinks: false, recursive: true).handleError((
            Object e,
          ) {
            if (e is FileSystemException) {
              errorPaths.add(e.path ?? '');
            } else {
              throw e;
            }
          })) {
        if (item is! File) continue;

        final ext = p.extension(item.path).toLowerCase();
        if (!_extensions.contains(ext)) continue;

        paths.add(item.absolute.path);
      }
    }

    return TracksDiscovered(paths: paths.toList(), errorPaths: errorPaths);
  }

  Stream<ScanEvent> scan(List<String> paths, List<TrackInfo> existing) async* {
    // TODO: 确保打断后能停止
    // TODO: 需要处理条目存在但文件被移除的情况，添加 removed 字段
    List<TrackInfo> tracks = [];

    Map<String, TrackInfo> existingMap = {
      for (final TrackInfo element in existing) element.path: element,
    };

    for (final String path in paths) {
      final File file = File(path);
      final TrackInfo? existingTrack = existingMap[path];
      FileStat? stat;
      Tag? tag;

      try {
        stat = await file.stat();
        if (existingTrack != null) {
          if (existingTrack.editTime == stat.modified &&
              existingTrack.sizeBytes == stat.size) {
            tracks.add(existingTrack);
            yield TrackSkipped(path: file.path);
            continue;
          }
        }
        tag = await Haudiotagger.read(file.path);
      } catch (e) {
        yield TrackScannedError(path: file.path, detail: e.toString());
        continue;
      }

      String title = (() {
        String str = tag?.title ?? '';
        if (str.isEmpty) str = p.basenameWithoutExtension(file.path);
        return str;
      })();
      List<String>? artists = (() {
        String str = tag?.trackArtist ?? '';
        if (str.isEmpty) return null;
        return splitArtists(str);
      })();
      String? album = (() {
        String? str = tag?.album ?? '';
        if (str.isEmpty) str = null;
        return str;
      })();

      final track = TrackInfo(
        title: title,
        titleInLatin: title.toLatin(),
        artists: artists,
        artistsInLatin: artists?.join('/').toLatin() ?? '#',
        album: album,
        albumInLatin: album?.toLatin() ?? '#',
        path: path,
        sizeBytes: stat.size,
        durationMs: 1000 * (tag?.duration ?? 0),
        trackGainUpdated: false,
        editTime: stat.modified,
        playCount: existingTrack?.playCount ?? 0,
        addTime: existingTrack?.addTime ?? DateTime.now(),
      );
      tracks.add(track);
      yield TrackScanned(track: track);
    }
    yield TrackScannedFinish(tracks: tracks);
  }
}
