import 'package:drift/drift.dart';

class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();

  /// 姓名对应的分组
  TextColumn get nameGroup => text()();

  /// 排序依据
  TextColumn get nameSort => text()();
}
