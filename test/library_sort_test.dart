import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/library/domain/library_sort.dart';
import 'package:linglun/src/features/player/domain/track.dart';

void main() {
  final tracks = [
    Track(
      id: 'z',
      title: '阿房宫',
      artist: '乙',
      album: '专辑二',
      duration: const Duration(seconds: 180),
      playCount: 2,
      addedAt: DateTime(2026, 1),
      modifiedAt: DateTime(2026, 3),
    ),
    Track(
      id: 'a',
      title: '白日梦',
      artist: '甲',
      album: '专辑一',
      duration: const Duration(seconds: 120),
      playCount: 5,
      addedAt: DateTime(2026, 2),
      modifiedAt: DateTime(2026, 4),
    ),
  ];

  test('中文标题按无声调拼音排序，并支持降序', () {
    expect(
      sortLibraryTracks(
        tracks,
        field: LibrarySortField.title,
        descending: false,
      ).map((track) => track.id),
      ['a', 'z'],
    );
    expect(
      sortLibraryTracks(
        tracks,
        field: LibrarySortField.title,
        descending: true,
      ).map((track) => track.id),
      ['z', 'a'],
    );
  });

  test('支持播放次数、时长和文件时间排序', () {
    expect(
      sortLibraryTracks(
        tracks,
        field: LibrarySortField.playCount,
        descending: true,
      ).first.id,
      'a',
    );
    expect(
      sortLibraryTracks(
        tracks,
        field: LibrarySortField.duration,
        descending: false,
      ).first.id,
      'a',
    );
    expect(
      sortLibraryTracks(
        tracks,
        field: LibrarySortField.modifiedAt,
        descending: true,
      ).first.id,
      'a',
    );
  });
}
