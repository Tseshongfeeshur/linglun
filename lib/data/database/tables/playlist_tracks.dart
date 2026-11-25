import 'package:drift/drift.dart';
import 'package:linglun/data/database/tables/playlists.dart';
import 'package:linglun/data/database/tables/tracks.dart';

class PlaylistTracks extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();

  /// 该曲目在该歌单中排第几
  IntColumn get position => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {playlistId, trackId};
}
