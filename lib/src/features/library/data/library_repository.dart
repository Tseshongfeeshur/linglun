import '../../../core/database/app_database.dart';
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
    return database.replaceLibrary(
      tracks: tracks
          .where((track) => track.path != null)
          .map(
            (track) => LibraryTracksCompanion.insert(
              id: track.id,
              filePath: track.path!,
              title: track.title,
              artist: track.artist,
              album: track.album,
              durationMs: track.duration.inMilliseconds,
              coverColor: track.coverColor,
              updatedAt: DateTime.now(),
            ),
          )
          .toList(),
      directories: directories,
    );
  }

  Track _toTrack(LibraryTrack row) {
    return Track(
      id: row.id,
      path: row.filePath,
      title: row.title,
      artist: row.artist,
      album: row.album,
      duration: Duration(milliseconds: row.durationMs),
      coverColor: row.coverColor,
    );
  }
}
