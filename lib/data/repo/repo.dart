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

  Future<List<TrackInfo>> _loadTracks() async {
    final trackRows = await db.select(db.tracks).get();

    final artistRows = await db.select(db.artists).get();
    final artistMap = Map.fromEntries(artistRows.map((i) => MapEntry(i.id, i)));

    final albumRows = await db.select(db.albums).get();
    final albumMap = Map.fromEntries(albumRows.map((i) => MapEntry(i.id, i)));

    final trackArtistRows = await (db.select(
      db.trackArtists,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.position)])).get();
    var trackArtistMap = <int, List<int>>{};
    for (final i in trackArtistRows) {
      trackArtistMap.putIfAbsent(i.trackId, () => []).add(i.artistId);
    }

    final result = trackRows.map((row) {
      final artistIds = trackArtistMap[row.id];
      final album = albumMap[row.albumId];

      return TrackInfo(
        sourceKey: row.sourceKey,
        title: row.title,
        titleCollation: Collation(group: row.titleGroup, sort: row.titleSort),
        artists: artistIds?.map((i) => artistMap[i]!.name).toList() ?? [],

        artistCollation: artistIds == null
            ? collationOfNullable(null)
            : Collation(
                group: artistMap[artistIds[0]]!.nameGroup,
                sort: artistMap[artistIds[0]]!.nameSort,
              ),
        album: album?.title,
        albumCollation: album == null
            ? collationOfNullable(null)
            : Collation(group: album.titleGroup, sort: album.titleSort),
        albumArtist: album == null
            ? null
            : artistMap[album.albumArtistId]?.name,
        uri: row.uri,
        fileName: row.fileName,
        sizeBytes: row.sizeBytes,
        durationMs: row.durationMs,
        editTime: row.editTime,
        trackGainUpdated: row.trackGainUpdated,
        playCount: row.playCount,
        addTime: row.addTime,
        removed: row.removed,
      );
    }).toList();

    return result;
  }

  Stream<List<TrackInfo>> watchTracks() {
    final dataStream = db
        .customSelect(
          'SELECT 1',
          readsFrom: {db.tracks, db.artists, db.albums, db.trackArtists},
        )
        .watch()
        .asyncMap((_) => _loadTracks());
    return dataStream;
  }
}
