import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/core/database/app_database.dart';

void main() {
  test('数据库可以保存设置和年度播放事件', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.saveSetting('test.setting', '{"enabled":true}');
    expect(await database.loadSetting('test.setting'), '{"enabled":true}');

    await database.recordPlayback('track-1', DateTime.utc(2026, 9, 22, 12));
    await database.recordPlayback('track-2', DateTime.utc(2025, 9, 22, 12));

    expect(await database.yearlyPlayCounts(), {2025: 1, 2026: 1});
  });
}
