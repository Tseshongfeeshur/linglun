import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:haudiotagger/haudiotagger.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/utils/string_to_latin.dart';

const extensions = {'.mp3', '.flac', '.m4a', '.ogg', '.opus', '.wav'};

Future<({List<File> files, List<String> errorPaths})> discover(
  String rootPath,
) async {
  final dir = Directory(rootPath);

  final List<File> files = [];
  final List<String> errorPaths = [];

  await for (final item
      in dir.list(followLinks: false, recursive: true).handleError((Object e) {
        if (e is FileSystemException) {
          errorPaths.add(e.path ?? '未知路径');
        } else {
          throw e;
        }
      })) {
    if (item is! File) continue;

    final ext = p.extension(item.path).toLowerCase();
    if (!extensions.contains(ext)) continue;

    files.add(item);
  }

  return (files: files, errorPaths: errorPaths);
}

Future<({List<TrackInfo> tracks, Map<String, String> errorFiles})> scan(
  List<File> files,
) async {
  final RegExp artistSpliter = RegExp(r'[;/&、]');
  List<TrackInfo> tracks = [];
  Map<String, String> errorFiles = {};

  for (final File file in files) {
    final String path = file.path;
    FileStat? stat;
    Tag? tag;
    try {
      stat = await file.stat();
      tag = await Haudiotagger.read(file.path);
    } catch (e) {
      errorFiles.addAll({file.path: e.toString()});
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
      return str.split(artistSpliter).map((str) => str.trim()).toList();
    })();

    tracks.add(
      TrackInfo(
        title: title,
        titleInLatin: title.toLatin(),
        artists: artists,
        artistsInLatin: tag?.trackArtist?.toLatin() ?? '#',
        album: tag?.album,
        albumInLatin: tag?.album?.toLatin() ?? '#',
        path: path,
        sizeBytes: stat.size,
        durationMs: 1000 * (tag?.duration ?? 0),
        trackGainUpdated: false,
        editTime: stat.modified,
        playCount: 0,
        addTime: DateTime.now(),
      ),
    );
  }

  return (tracks: tracks, errorFiles: errorFiles);
}

Future<int> main() async {
  if (Platform.isLinux) {
    String homePath = Platform.environment['HOME'] ?? '/root';
    String trackPath = p.join(homePath, 'Music');

    // TODO: Just For Test
    trackPath = p.join(trackPath, 'test');

    final stopwatch = Stopwatch()..start();

    final discoverResult = await discover(trackPath);
    final trackToScan = discoverResult.files;
    final discoverErr = discoverResult.errorPaths;

    final scanResult = await scan(trackToScan);
    final tracks = scanResult.tracks;
    final scanErr = scanResult.errorFiles;

    stopwatch.stop();

    for (final item in tracks) {
      print(
        '${item.title}, ${item.artists}, ${item.album}, ${item.path}, ${item.sizeBytes}, ${item.durationMs.ms}\n',
      );
    }
    print(discoverErr);
    print(scanErr);
    print(stopwatch.elapsed);
  }
  return 0;
}
