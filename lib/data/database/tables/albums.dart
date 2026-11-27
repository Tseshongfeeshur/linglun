import 'package:drift/drift.dart';
import 'package:linglun/data/database/tables/artists.dart';

class Albums extends Table {
  // ====== 标识 ======
  IntColumn get id => integer().autoIncrement()();

  /// 识别依据（= '$标题\u0000$专辑艺术家标签内容'，同名不同艺术家专辑非同专辑）
  TextColumn get albumKey => text().unique()();

  /// ====== 标题 ======
  TextColumn get title => text()();

  /// 标题对应的分组
  TextColumn get titleGroup => text()();

  /// 排序依据
  TextColumn get titleSort => text()();

  IntColumn get albumArtistId =>
      integer().nullable().references(Artists, #id)();
}
