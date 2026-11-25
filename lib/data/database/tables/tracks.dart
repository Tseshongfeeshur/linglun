import 'package:drift/drift.dart';
import 'package:linglun/data/database/tables/albums.dart';

class Tracks extends Table {
  // ====== 标识 ======
  IntColumn get id => integer().autoIncrement()();

  /// 用来访问文件
  TextColumn get uri => text()();

  /// 文件唯一标识符
  TextColumn get sourceKey => text().unique()();
  TextColumn get fileName => text()();

  /// ====== 标题 ======
  TextColumn get title => text()();

  /// 标题对应的分组
  TextColumn get titleGroup => text()();

  /// 排序依据
  TextColumn get titleSort => text()();

  /// ====== 专辑 ======
  IntColumn get albumId => integer().nullable().references(Albums, #id)();

  // ====== 详细信息 ======
  /// 文件尺寸
  IntColumn get sizeBytes => integer()();

  /// 音频时长
  IntColumn get durationMs => integer()();

  /// 文件上次编辑时间
  DateTimeColumn get editTime => dateTime()();

  // ====== 用户数据 ======
  /// 该歌曲是否已完成增益计算
  BoolColumn get trackGainUpdated => boolean()();
  IntColumn get playCount => integer()();

  /// 用户将歌曲添加进表的时间
  DateTimeColumn get addTime => dateTime()();
  BoolColumn get removed => boolean()();
}
