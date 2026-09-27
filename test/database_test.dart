import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/core/database/app_database.dart';

void main() {
  test('数据库可以保存设置和年度播放事件', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final columns = await database
        .customSelect('PRAGMA table_info(library_tracks)')
        .get();
    final columnNames = columns.map((row) => row.read<String>('name')).toSet();
    expect(
      columnNames,
      containsAll(['fluid_palette_json', 'beat_envelope_json']),
    );

    await database.saveSetting('test.setting', '{"enabled":true}');
    expect(await database.loadSetting('test.setting'), '{"enabled":true}');

    await database.recordPlayback('track-1', DateTime.utc(2026, 9, 22, 12));
    await database.recordPlayback('track-2', DateTime.utc(2025, 9, 22, 12));

    expect(await database.yearlyPlayCounts(), {2025: 1, 2026: 1});
  });

  test('旧数据库版本号正确但缺少流体背景列时会自动修复', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('''
            CREATE TABLE library_tracks (
              id TEXT NOT NULL PRIMARY KEY,
              file_path TEXT NOT NULL,
              cover_bytes BLOB,
              title TEXT NOT NULL,
              artist TEXT NOT NULL,
              album TEXT NOT NULL,
              duration_ms INTEGER NOT NULL,
              cover_color INTEGER NOT NULL,
              lyrics TEXT,
              lyrics_format TEXT,
              lyrics_sources_json TEXT,
              metadata_json TEXT,
              replay_gain_db REAL,
              replay_gain_mode TEXT,
              play_count INTEGER NOT NULL DEFAULT 0,
              last_played_at INTEGER,
              added_at INTEGER,
              modified_at INTEGER,
              updated_at INTEGER NOT NULL
            )
          ''');
          database.userVersion = 10;
        },
      ),
    );
    addTearDown(database.close);

    final columns = await database
        .customSelect('PRAGMA table_info(library_tracks)')
        .get();
    final columnNames = columns.map((row) => row.read<String>('name')).toSet();
    expect(
      columnNames,
      containsAll(['fluid_palette_json', 'beat_envelope_json']),
    );
  });
}
