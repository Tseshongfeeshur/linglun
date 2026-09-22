import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class LibraryTracks extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text()();
  BlobColumn get coverBytes => blob().nullable()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();
  IntColumn get durationMs => integer()();
  IntColumn get coverColor => integer()();
  TextColumn get lyrics => text().nullable()();
  TextColumn get lyricsFormat => text().nullable()();
  TextColumn get lyricsSourcesJson => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  RealColumn get replayGainDb => real().nullable()();
  TextColumn get replayGainMode => text().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LibraryDirectories extends Table {
  TextColumn get directoryPath => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {directoryPath};
}

class PlaybackEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  DateTimeColumn get playedAt => dateTime()();
}

/// 保存版本化的应用设置，避免音频处理参数只存在于当前进程内。
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [LibraryTracks, LibraryDirectories, PlaybackEvents, AppSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(libraryTracks, libraryTracks.lyrics);
        await m.addColumn(libraryTracks, libraryTracks.replayGainDb);
        await m.addColumn(libraryTracks, libraryTracks.playCount);
        await m.addColumn(libraryTracks, libraryTracks.lastPlayedAt);
      }
      if (from < 3) {
        await m.addColumn(libraryTracks, libraryTracks.lyricsFormat);
        await m.createTable(playbackEvents);
      }
      if (from < 4) {
        await m.addColumn(libraryTracks, libraryTracks.coverBytes);
      }
      if (from < 5) {
        await m.addColumn(libraryTracks, libraryTracks.metadataJson);
      }
      if (from < 6) {
        await m.createTable(appSettings);
      }
      if (from < 7) {
        await m.addColumn(libraryTracks, libraryTracks.replayGainMode);
      }
      if (from < 8) {
        await m.addColumn(libraryTracks, libraryTracks.lyricsSourcesJson);
      }
    },
  );

  Future<List<LibraryTrack>> loadTracks() => select(libraryTracks).get();

  Future<List<LibraryDirectory>> loadDirectories() =>
      select(libraryDirectories).get();

  Future<String?> loadSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((setting) => setting.key.equals(key))).getSingleOrNull();
    return row?.valueJson;
  }

  Future<void> saveSetting(String key, String valueJson) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: key,
        valueJson: valueJson,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> replaceLibrary({
    required List<LibraryTracksCompanion> tracks,
    required List<String> directories,
  }) async {
    await transaction(() async {
      await delete(libraryTracks).go();
      await delete(libraryDirectories).go();
      await batch((batch) {
        batch.insertAll(libraryTracks, tracks);
        batch.insertAll(
          libraryDirectories,
          directories
              .map(
                (directory) => LibraryDirectoriesCompanion.insert(
                  directoryPath: directory,
                  addedAt: DateTime.now(),
                ),
              )
              .toList(),
        );
      });
    });
  }

  Future<void> recordPlayback(String id, DateTime playedAt) async {
    await transaction(() async {
      await into(
        playbackEvents,
      ).insert(PlaybackEventsCompanion.insert(trackId: id, playedAt: playedAt));
      await customUpdate(
        'UPDATE library_tracks SET play_count = play_count + 1, '
        'last_played_at = ? WHERE id = ?',
        variables: [Variable.withDateTime(playedAt), Variable.withString(id)],
        updates: {libraryTracks},
      );
    });
  }

  /// 返回每个年份的播放事件数量，为年度总结保留准确的历史数据。
  Future<Map<int, int>> yearlyPlayCounts() async {
    final rows = await customSelect(
      "SELECT CAST(strftime('%Y', played_at) AS INTEGER) AS year, "
      'COUNT(*) AS count FROM playback_events GROUP BY year',
      readsFrom: {playbackEvents},
    ).get();
    return {
      for (final row in rows) row.read<int>('year'): row.read<int>('count'),
    };
  }
}

Future<AppDatabase> openLinglunDatabase() async {
  final directory = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(path.join(directory.path, 'data'));
  await databaseDirectory.create(recursive: true);
  final file = File(path.join(databaseDirectory.path, 'linglun.sqlite'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}

Future<AppDatabase>? _sharedDatabase;

Future<AppDatabase> sharedLinglunDatabase() {
  return _sharedDatabase ??= openLinglunDatabase();
}
