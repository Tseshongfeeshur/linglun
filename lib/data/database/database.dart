import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:linglun/data/database/tables/albums.dart';
import 'package:linglun/data/database/tables/artists.dart';
import 'package:linglun/data/database/tables/playlist_tracks.dart';
import 'package:linglun/data/database/tables/playlists.dart';
import 'package:linglun/data/database/tables/track_artists.dart';
import 'package:linglun/data/database/tables/tracks.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Tracks, Albums, Artists, TrackArtists, Playlists, PlaylistTracks],
)
class AppDatabase extends _$AppDatabase {
  new([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'linglun_db');
  }
}
