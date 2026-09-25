import 'package:pinyin/pinyin.dart';

import '../../player/domain/track.dart';

/// 曲库列表支持的排序字段。
enum LibrarySortField {
  title('标题'),
  artist('歌手'),
  album('专辑'),
  playCount('播放次数'),
  duration('音轨时长'),
  addedAt('添加时间'),
  modifiedAt('修改时间');

  const LibrarySortField(this.label);

  final String label;
}

/// 统一生成曲库排序结果，保证页面显示顺序和点击后建立的队列一致。
List<Track> sortLibraryTracks(
  Iterable<Track> tracks, {
  required LibrarySortField field,
  required bool descending,
}) {
  final sorted = tracks.toList();
  sorted.sort((left, right) {
    final result = _compareTrackValue(left, right, field);
    if (result != 0) return descending ? -result : result;
    // 相同排序值时使用稳定的文件标识作为确定性次序，避免重建队列时跳动。
    return left.id.compareTo(right.id);
  });
  return sorted;
}

int _compareTrackValue(Track left, Track right, LibrarySortField field) {
  return switch (field) {
    LibrarySortField.title => _compareText(left.title, right.title),
    LibrarySortField.artist => _compareText(left.artist, right.artist),
    LibrarySortField.album => _compareText(left.album, right.album),
    LibrarySortField.playCount => left.playCount.compareTo(right.playCount),
    LibrarySortField.duration => left.duration.compareTo(right.duration),
    LibrarySortField.addedAt => _compareDate(left.addedAt, right.addedAt),
    LibrarySortField.modifiedAt => _compareDate(
      left.modifiedAt,
      right.modifiedAt,
    ),
  };
}

int _compareText(String left, String right) {
  final leftKey = _sortKey(left);
  final rightKey = _sortKey(right);
  return leftKey.compareTo(rightKey);
}

String _sortKey(String value) {
  // 统一使用无声调拼音，中文和拉丁文字可以进入同一套字典序比较。
  return PinyinHelper.getPinyin(
    value.trim().toLowerCase(),
    separator: ' ',
    format: PinyinFormat.WITHOUT_TONE,
  );
}

int _compareDate(DateTime? left, DateTime? right) {
  if (left == null && right == null) return 0;
  if (left == null) return -1;
  if (right == null) return 1;
  return left.compareTo(right);
}
