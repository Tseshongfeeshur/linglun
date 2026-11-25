import 'package:drift/drift.dart';
import 'package:linglun/data/database/tables/artists.dart';
import 'package:linglun/data/database/tables/tracks.dart';

class TrackArtists extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get artistId => integer().references(Artists, #id)();

  /// 该艺术家在该曲目中排第几
  IntColumn get position => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {trackId, artistId};
}
