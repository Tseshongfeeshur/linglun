import '../../../core/database/app_database.dart';

import 'package:drift/drift.dart';

import '../../player/domain/track.dart';

class LibraryRepository {
  LibraryRepository(this.database);

  final AppDatabase database;

  Future<({List<Track> tracks, List<String> directories})> load() async {
    final rows = await database.loadTracks();
    final directories = await database.loadDirectories();
    return (
      tracks: rows.map(_toTrack).toList(),
      directories: directories.map((row) => row.directoryPath).toList(),
    );
  }

  Future<void> replaceLibrary({
    required List<Track> tracks,
    required List<String> directories,
  }) {
    return _replaceLibrary(tracks: tracks, directories: directories);
  }

  Future<void> _replaceLibrary({
    required List<Track> tracks,
    required List<String> directories,
  }) async {
    // 扫描会重建文件索引，但播放统计必须跨扫描保留。
    final previous = {
      for (final row in await database.loadTracks()) row.id: row,
    };

    await database.replaceLibrary(
      tracks: tracks.where((track) => track.path != null).map((track) {
        final old = previous[track.id];
        return LibraryTracksCompanion.insert(
          id: track.id,
          filePath: track.path!,
          coverBytes: Value(track.coverBytes),
          title: track.title,
          artist: track.artist,
          album: track.album,
          durationMs: track.duration.inMilliseconds,
          coverColor: track.coverColor,
          lyrics: Value(track.lyrics),
          lyricsFormat: Value(track.lyricsFormat),
          replayGainDb: Value(track.replayGainDb),
          playCount: Value(old?.playCount ?? track.playCount),
          lastPlayedAt: Value(old?.lastPlayedAt ?? track.lastPlayedAt),
          updatedAt: DateTime.now(),
        );
      }).toList(),
      directories: directories,
    );
  }

  Track _toTrack(LibraryTrack row) {
    return Track(
      id: row.id,
      path: row.filePath,
      coverBytes: row.coverBytes,
      title: row.title,
      artist: row.artist,
      album: row.album,
      duration: Duration(milliseconds: row.durationMs),
      lyrics: row.lyrics,
      lyricsFormat: row.lyricsFormat,
      replayGainDb: row.replayGainDb,
      playCount: row.playCount,
      lastPlayedAt: row.lastPlayedAt,
      coverColor: row.coverColor,
    );
  }
}
