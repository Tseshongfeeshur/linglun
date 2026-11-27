import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:linglun/data/database/database.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/parse_event.dart';
import 'package:linglun/data/track_scanner/utils/collation_of.dart';

class Repo {
  final LinglunDatabase db;
  new(this.db);

  Future<void> update(List<ParseEvent> events) async {
    for (var e in events) {
      switch (e) {
        case TrackParsed():
          // 创建一个事务
          await db.transaction(() async {
            var artistIds = <int>[];
            int? albumId;
            int trackId;

            // 先查艺术家是否全部入库
            for (var i = 0; i < e.artists.length; i++) {
              final oldArtist =
                  await (db.select(db.artists)
                        ..where((tbl) => tbl.name.equals(e.artists[i])))
                      .getSingleOrNull();
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

            // 再查专辑是否入库
            if (e.album != null) {
              final albumKey = '${e.album}\u0000${e.albumArtist}';
              final oldAlbum =
                  await (db.select(db.albums)
                        ..where((tbl) => tbl.albumKey.equals(albumKey)))
                      .getSingleOrNull();
              // 若还没有该专辑
              if (oldAlbum == null) {
                final newAlbum = await db
                    .into(db.albums)
                    .insert(
                      AlbumsCompanion.insert(
                        albumKey: albumKey,
                        title: e.album!,
                        titleGroup: e.albumCollation.group,
                        titleSort: e.albumCollation.sort,
                      ),
                    );
                albumId = newAlbum;
              } else {
                albumId = oldAlbum.id;
              }
            }

            // 才能插入曲目
            final oldTrack =
                await (db.select(db.tracks)
                      ..where((tbl) => tbl.sourceKey.equals(e.sourceKey)))
                    .getSingleOrNull();
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
          });
        case TrackSkipped():
          await db.transaction(() async {
            final old =
                await (db.select(db.tracks)
                      ..where((tbl) => tbl.sourceKey.equals(e.sourceKey)))
                    .getSingleOrNull();
            // 如果曲库中有
            if (old != null) {
              await (db.update(
                db.tracks,
              )..where((tbl) => tbl.id.equals(old.id))).write(
                TracksCompanion(uri: Value(e.uri), removed: Value(e.removed)),
              );
            }
          });
        case TrackParsedError() || TrackParsedFinish():
          // 不应传入
          continue;
      }
    }
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
      if (row.albumId != null) {
        albumRow = await (db.select(
          db.albums,
        )..where((tbl) => tbl.id.equals(row.albumId!))).getSingleOrNull();
      }

      // 构建对象
      result.add(
        TrackInfo(
          sourceKey: row.sourceKey,
          title: row.title,
          titleCollation: Collation(group: row.titleGroup, sort: row.titleSort),
          artists: artistRows.map((i) => i.name).toList(),
          artistsCollation: artistRows.isEmpty
              ? collationOfNullable(null)
              : Collation(
                  group: artistRows.first.nameGroup,
                  sort: artistRows.first.nameSort,
                ),
          album: albumRow?.title,
          albumCollation: albumRow == null
              ? collationOfNullable(null)
              : Collation(group: albumRow.titleGroup, sort: albumRow.titleSort),
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
}
