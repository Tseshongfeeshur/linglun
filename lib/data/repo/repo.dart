import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:linglun/data/database/database.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/parse_event.dart';
import 'package:linglun/data/track_scanner/utils/collation_of.dart';

class Repo {
  final LinglunDatabase db;
  new(this.db);

  Future<void> update(
    List<TrackParsed> parsed,
    List<TrackSkipped> skipped,
  ) async {
    await db.transaction(() async {
      for (final e in parsed) {
        // 创建一个事务
        var artistIds = <int>[];
        int? albumArtistId;
        int? albumId;
        int trackId;

        // 先查艺术家是否全部入库
        for (var i = 0; i < e.artists.length; i++) {
          final oldArtist = await (db.select(
            db.artists,
          )..where((tbl) => tbl.name.equals(e.artists[i]))).getSingleOrNull();
          // 若还没有该艺术家
          if (oldArtist == null) {
            final newArtist = await db
                .into(db.artists)
                .insert(
                  ArtistsCompanion.insert(
                    name: e.artists[i],
                    nameGroup: e.artistCollations[i].group,
                    nameSort: e.artistCollations[i].sort,
                  ),
                );
            artistIds.add(newArtist);
          } else {
            artistIds.add(oldArtist.id);
          }
        }
        // 专辑艺术家
        if (e.albumArtist != null) {
          final albumArtist = await (db.select(
            db.artists,
          )..where((tbl) => tbl.name.equals(e.albumArtist!))).getSingleOrNull();
          // 若还没有该艺术家
          if (albumArtist == null) {
            final newArtist = await db
                .into(db.artists)
                .insert(
                  ArtistsCompanion.insert(
                    name: e.albumArtist!,
                    nameGroup: e.albumArtistCollation!.group,
                    nameSort: e.albumArtistCollation!.sort,
                  ),
                );
            albumArtistId = newArtist;
          } else {
            albumArtistId = albumArtist.id;
          }
        }

        // 再查专辑是否入库
        if (e.album != null) {
          final albumKey = '${e.album}\u0000${e.albumArtist ?? ''}';
          final oldAlbum = await (db.select(
            db.albums,
          )..where((tbl) => tbl.albumKey.equals(albumKey))).getSingleOrNull();
          // 若还没有该专辑
          if (oldAlbum == null) {
            final newAlbum = await db
                .into(db.albums)
                .insert(
                  AlbumsCompanion.insert(
                    albumArtistId: Value(albumArtistId),
                    albumKey: albumKey,
                    title: e.album!,
                    titleGroup: e.albumCollation.group,
                    titleSort: e.albumCollation.sort,
                  ),
                );
            albumId = newAlbum;
          } else {
            // TODO: 如果专辑艺术家变了好像根本就走不到这儿，所以按没变处理
            albumId = oldAlbum.id;
          }
        }

        // 才能插入曲目
        final oldTrack = await (db.select(
          db.tracks,
        )..where((tbl) => tbl.sourceKey.equals(e.sourceKey))).getSingleOrNull();
        // 如果库中还没有
        if (oldTrack == null) {
          final newTrack = await db
              .into(db.tracks)
              .insert(
                TracksCompanion.insert(
                  uri: e.uri,
                  sourceKey: e.sourceKey,
                  fileName: e.fileName,
                  title: e.title,
                  titleGroup: e.titleCollation.group,
                  titleSort: e.titleCollation.sort,
                  albumId: Value(albumId),
                  sizeBytes: e.sizeBytes,
                  durationMs: e.durationMs,
                  editTime: e.editTime,
                  trackGainUpdated: false,
                  playCount: 0,
                  addTime: DateTime.now(),
                  removed: false,
                ),
              );
          trackId = newTrack;
        } else {
          // 若库中已有则更新
          await (db.update(
            db.tracks,
          )..where((tbl) => tbl.id.equals(oldTrack.id))).write(
            TracksCompanion(
              uri: Value(e.uri),
              sourceKey: Value(e.sourceKey),
              fileName: Value(e.fileName),
              title: Value(e.title),
              titleGroup: Value(e.titleCollation.group),
              titleSort: Value(e.titleCollation.sort),
              albumId: Value(albumId),
              sizeBytes: Value(e.sizeBytes),
              durationMs: Value(e.durationMs),
              editTime: Value(e.editTime),
              trackGainUpdated: const Value(false),
              removed: const Value(false),
            ),
          );
          trackId = oldTrack.id;
        }

        // 最后关联艺术家
        final oldArtistRows =
            await ((db.select(db.trackArtists)
                    ..where((tbl) => tbl.trackId.equals(trackId)))
                  ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
                .get();
        final oldArtistIds = oldArtistRows.map((i) => i.artistId).toList();
        // 如果有变化
        if (!listEquals(oldArtistIds, artistIds)) {
          // 删掉
          for (final row in oldArtistRows) {
            await db.delete(db.trackArtists).delete(row);
          }
          // 重建
          for (var i = 0; i < artistIds.length; i++) {
            await db
                .into(db.trackArtists)
                .insert(
                  TrackArtistsCompanion.insert(
                    trackId: trackId,
                    artistId: artistIds[i],
                    position: i,
                  ),
                );
          }
        }
      }

      for (final e in skipped) {
        final old = await (db.select(
          db.tracks,
        )..where((tbl) => tbl.sourceKey.equals(e.sourceKey))).getSingleOrNull();
        // 如果曲库中有
        if (old != null) {
          await (db.update(
            db.tracks,
          )..where((tbl) => tbl.id.equals(old.id))).write(
            TracksCompanion(uri: Value(e.uri), removed: Value(e.removed)),
          );
        }
      }
    });
  }

  Future<List<TrackInfo>> getTracks() async {
    var result = <TrackInfo>[];

    // 先拿出所有曲目
    final trackRows = await db.select(db.tracks).get();

    for (final row in trackRows) {
      final trackId = row.id;

      // 先读出艺术家
      final artistIds =
          (await ((db.select(db.trackArtists)
                      ..where((tbl) => tbl.trackId.equals(trackId)))
                    ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
                  .get())
              .map((i) => i.artistId);
      final artistRows = await (db.select(
        db.artists,
      )..where((tbl) => tbl.id.isIn(artistIds))).get();

      // 再读出专辑
      Album? albumRow;
      Artist? albumArtistRow;
      if (row.albumId != null) {
        albumRow = await (db.select(
          db.albums,
        )..where((tbl) => tbl.id.equals(row.albumId!))).getSingleOrNull();
        // 专辑艺术家
        albumArtistRow = await (db.select(
          db.artists,
        )..where((tbl) => tbl.id.equals(albumRow!.id))).getSingleOrNull();
      }

      // 构建对象
      result.add(
        TrackInfo(
          sourceKey: row.sourceKey,
          title: row.title,
          titleCollation: Collation(group: row.titleGroup, sort: row.titleSort),
          artists: artistRows.map((i) => i.name).toList(),
          artistCollation: artistRows.isEmpty
              ? collationOfNullable(null)
              : Collation(
                  group: artistRows.first.nameGroup,
                  sort: artistRows.first.nameSort,
                ),
          album: albumRow?.title,
          albumCollation: albumRow == null
              ? collationOfNullable(null)
              : Collation(group: albumRow.titleGroup, sort: albumRow.titleSort),
          albumArtist: albumArtistRow?.name,
          uri: row.uri,
          fileName: row.fileName,
          sizeBytes: row.sizeBytes,
          durationMs: row.durationMs,
          editTime: row.editTime,
          trackGainUpdated: row.trackGainUpdated,
          playCount: row.playCount,
          addTime: row.addTime,
          removed: row.removed,
        ),
      );
    }
    return result;
  }

  Stream<List<TrackInfo>> watchTracks() async* {
    final trackRowsStream = db.select(db.tracks).watch();

    await for (final trackRow in trackRowsStream) {
      final artistRows = await db.select(db.artists).get();
      final albumRows = await db.select(db.albums).get();
      final trackArtistRows = await (db.select(
        db.trackArtists,
      )..orderBy([(tbl) => OrderingTerm.asc(tbl.position)])).get();

      yield trackRow
          .map(
            (row) => TrackInfo(
              sourceKey: row.sourceKey,
              title: row.title,
              titleCollation: Collation(
                group: row.titleGroup,
                sort: row.titleSort,
              ),
              artists: trackArtistRows
                  .where((i) => i.trackId == row.id)
                  .map((i) => i.artistId)
                  .map(
                    (i) =>
                        artistRows.firstWhere((artistRow) => artistRow.id == i),
                  )
                  .map((i) => i.name)
                  .toList(),
              artistCollation: artistRows.isEmpty
                  ? collationOfNullable(null)
                  : Collation(
                      group: trackArtistRows
                          .where((i) => i.trackId == row.id)
                          .map((i) => i.artistId)
                          .map(
                            (i) => artistRows.firstWhere(
                              (artistRow) => artistRow.id == i,
                            ),
                          )
                          .first
                          .nameGroup,
                      sort: trackArtistRows
                          .where((i) => i.trackId == row.id)
                          .map((i) => i.artistId)
                          .map(
                            (i) => artistRows.firstWhere(
                              (artistRow) => artistRow.id == i,
                            ),
                          )
                          .first
                          .nameGroup,
                    ),
              album: albumRows.firstWhere((i) => i.id == row.albumId).title,
              albumCollation: Collation(
                group: albumRows
                    .firstWhere((i) => i.id == row.albumId)
                    .titleGroup,
                sort: albumRows
                    .firstWhere((i) => i.id == row.albumId)
                    .titleSort,
              ),
              uri: row.uri,
              fileName: row.fileName,
              sizeBytes: row.sizeBytes,
              durationMs: row.durationMs,
              editTime: row.editTime,
              trackGainUpdated: row.trackGainUpdated,
              playCount: row.playCount,
              addTime: row.addTime,
              removed: row.removed,
            ),
          )
          .toList();
    }
  }
}
