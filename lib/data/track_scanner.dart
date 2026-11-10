import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:haudiotagger/haudiotagger.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/data/utils/get_platform_music_path.dart';
import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/utils/string_to_latin.dart';
import 'package:linglun/data/utils/artist_splitter.dart';

sealed class ScanEvent {}

class TracksDiscovered {
  final List<String> paths;
  final List<String> errorPaths;
  TracksDiscovered({required this.paths, required this.errorPaths});
}

class TrackScanned extends ScanEvent {
  final TrackInfo track;
  TrackScanned({required this.track});
}

class TrackScannedError extends ScanEvent {
  final String path;
  final String detail;
  TrackScannedError({required this.path, required this.detail});
}

class TrackScannedFinish extends ScanEvent {
  final List<TrackInfo> tracks;
  TrackScannedFinish({required this.tracks});
}

class TrackScanner {
  static const extensions = {'.mp3', '.flac', '.m4a', '.ogg', '.opus', '.wav'};

  Future<TracksDiscovered> discover(List<String> rootPaths) async {
    final Set<String> paths = {};
    final List<String> errorPaths = [];

    for (final String path in rootPaths) {
      final dir = Directory(path);
      await for (final item
          in dir.list(followLinks: false, recursive: true).handleError((
            Object e,
          ) {
            if (e is FileSystemException) {
              errorPaths.add(e.path ?? null.toString());
            } else {
              throw e;
            }
          })) {
        if (item is! File) continue;

        final ext = p.extension(item.path).toLowerCase();
        if (!extensions.contains(ext)) continue;

        paths.add(item.absolute.path);
      }
    }

    return TracksDiscovered(paths: paths.toList(), errorPaths: errorPaths);
  }

  Stream<ScanEvent> scan(List<String> paths) async* {
    List<TrackInfo> tracks = [];
    for (final String path in paths) {
      final File file = File(path);
      FileStat? stat;
      Tag? tag;

      try {
        stat = await file.stat();
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
        playCount: 0,
        addTime: DateTime.now(),
      );
      tracks.add(track);
      yield TrackScanned(track: track);
    }
    yield TrackScannedFinish(tracks: tracks);
  }
}

Future<int> main() async {
  if (Platform.isLinux) {
    TrackScanner trackScanner = TrackScanner();

    final String musicPath = await getPlatformMusicPath();

    final stopwatch = Stopwatch()..start();

    final discoverResult = await trackScanner.discover([musicPath]);
    final tracksToScan = discoverResult.paths;
    final tracksDiscoverErr = discoverResult.errorPaths;

    print(
      'Discovered ${tracksToScan.length} paths, ${discoverResult.errorPaths.length} errors',
    );

    int scannedCounter = 0;
    final scanStream = trackScanner.scan(tracksToScan);

    await for (final ScanEvent event in scanStream) {
      switch (event) {
        case TrackScanned():
          scannedCounter++;
          print(
            'Scanned $scannedCounter/${tracksToScan.length}: ${event.track.title} - ${event.track.artists} ${event.track.durationMs.ms}',
          );
        case TrackScannedError():
          scannedCounter++;
          print(
            'Scanned $scannedCounter/${tracksToScan.length} Error: ${event.path}, Detail: ${event.detail}',
          );
        case TrackScannedFinish():
          stopwatch.stop();
          print(
            'ScanningFinish: $scannedCounter/${tracksToScan.length}, Time: ${stopwatch.elapsed}',
          );
      }
    }
  }
  return 0;
}
