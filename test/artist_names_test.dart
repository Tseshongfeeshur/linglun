import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/domain/track.dart';

void main() {
  test('艺术家标签会按约定分隔符拆分并清理空白', () {
    expect(splitArtistNames('甲 / 乙、丙; 丁 & 戊'), ['甲', '乙', '丙', '丁', '戊']);
  });

  test('空艺术家会回退为未知艺术家', () {
    expect(splitArtistNames(' / 、 ; & '), ['未知艺术家']);
  });
}
