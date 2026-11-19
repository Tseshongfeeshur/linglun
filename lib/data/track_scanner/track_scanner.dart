import 'dart:async';

import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:path/path.dart' as p;

import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/utils/string_to_latin.dart';
import 'package:linglun/data/track_scanner/utils/artist_splitter.dart';

const _extensions = {
  '.mp3',
  '.flac',
  '.m4a',
  '.ogg',
  '.opus',
  '.wav',
  '.aac',
  '.wma',
  '.ape',
};

sealed class DiscoverEvent {}

class FileDiscovered extends DiscoverEvent {
  final String uri;
  final String sourceKey;
  final String name;
  final int sizeBytes;
  final DateTime editTime;

  new({
    required this.uri,
    required this.sourceKey,
    required this.name,
    required this.sizeBytes,
    required this.editTime,
  });
}

class FileDiscoveredError extends DiscoverEvent {
  final String uri;
  final String detail;

  new({required this.uri, required this.detail});
}

class FileDiscoveredFinish extends DiscoverEvent {}

sealed class ParseEvent {}

class TrackParsed extends ParseEvent {
  final TrackInfo track;
  new({required this.track});
}

class TrackSkipped extends ParseEvent {
  final TrackInfo track;
  new({required this.track});
}

class TrackParsedError extends ParseEvent {
  final FileDiscovered file;
  final String detail;
  new({required this.file, required this.detail});
}

class TrackParsedFinish extends ParseEvent {}

class TrackScanner {
  Stream<DiscoverEvent> discover(
    PlatformFileUtils utils,
    Set<String> rootUris,
  ) async* {
    final keys = <String>{};
    final list = utils.discover(rootUris);
    await for (final item in list) {
      switch (item) {
        case FileDiscovered():
          final ext = p.extension(item.name).toLowerCase();
          if (!_extensions.contains(ext)) continue;
          if (keys.contains(item.sourceKey)) continue;

          keys.add(item.sourceKey);
          yield item;
        case FileDiscoveredError():
          yield item;
        case FileDiscoveredFinish():
          yield item;
      }
    }
  }

  Stream<ParseEvent> parse(
    PlatformFileUtils utils,
    List<FileDiscovered> files,
    List<TrackInfo> existing,
  ) async* {
    var existingMap = <String, TrackInfo>{
      for (final TrackInfo element in existing) element.sourceKey: element,
    };

    for (final item in files) {
      SimpleTag tag;
      final existingTrack = existingMap[item.sourceKey];

      try {
        if (existingTrack != null) {
          existingMap.remove(item.sourceKey);
          if ((existingTrack.editTime == item.editTime &&
                  existingTrack.sizeBytes == item.sizeBytes) &&
              (existingTrack.editTime.millisecondsSinceEpoch != 0 &&
                  existingTrack.sizeBytes != -1)) {
            yield TrackSkipped(track: existingTrack.copyWith(uri: item.uri));
            continue;
          }
        }
        tag = await utils.parse(item);
      } catch (e) {
        yield TrackParsedError(file: item, detail: e.toString());
        continue;
      }

      var title = (() {
        var str = tag.title ?? '';
        if (str.isEmpty) str = p.basenameWithoutExtension(item.name);
        return str;
      })();
      var artists = (() {
        var str = tag.artists ?? '';
        if (str.isEmpty) return null;
        return splitArtists(str);
      })();
      var album = (() {
        String? str = tag.album ?? '';
        if (str.isEmpty) str = null;
        return str;
      })();

      final track = TrackInfo(
        sourceKey: item.sourceKey,
        title: title,
        titleInLatin: title.toLatin(),
        artists: artists,
        artistsInLatin: artists?.join('/').toLatin() ?? '#',
        album: album,
        albumInLatin: album?.toLatin() ?? '#',
        uri: item.uri,
        fileName: item.name,
        sizeBytes: item.sizeBytes,
        durationMs: tag.durationMs ?? 0,
        trackGainUpdated: false,
        editTime: item.editTime,
        playCount: existingTrack?.playCount ?? 0,
        addTime: existingTrack?.addTime ?? DateTime.now(),
        removed: false,
      );
      yield TrackParsed(track: track);
    }
    for (var item in existingMap.values) {
      yield TrackParsed(track: item.copyWith(removed: true));
    }
    yield TrackParsedFinish();
  }
}
