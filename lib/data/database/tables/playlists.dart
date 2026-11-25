import 'package:drift/drift.dart';

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 歌单名称
  TextColumn get label => text().unique()();

  DateTimeColumn get createTime => dateTime()();
}
