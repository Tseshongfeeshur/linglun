import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class LibraryTracks extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();
  IntColumn get durationMs => integer()();
  IntColumn get coverColor => integer()();
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

@DriftDatabase(tables: [LibraryTracks, LibraryDirectories])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Future<List<LibraryTrack>> loadTracks() => select(libraryTracks).get();

  Future<List<LibraryDirectory>> loadDirectories() =>
      select(libraryDirectories).get();

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
}

Future<AppDatabase> openLinglunDatabase() async {
  final directory = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(path.join(directory.path, 'data'));
  await databaseDirectory.create(recursive: true);
  final file = File(path.join(databaseDirectory.path, 'linglun.sqlite'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}
