import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/presentation/lyric_emphasis.dart';

void main() {
  const threshold = Duration(seconds: 1);

  test('强调时长边界与 AMLL 一致', () {
    expect(
      isAmlEmphasizedLyricWord('中文', const Duration(milliseconds: 999)),
      isFalse,
    );
    expect(isAmlEmphasizedLyricWord('中文', threshold), isTrue);
    expect(isAmlEmphasizedLyricWord('sugar', threshold), isTrue);
  });

  test('CJK 词只要求至少一秒，不限制词长', () {
    expect(isAmlEmphasizedLyricWord('中文歌词超过七字', threshold), isTrue);
  });

  test('非 CJK 长度使用 UTF-16 字符数并限定为二至七', () {
    expect(isAmlEmphasizedLyricWord(' I ', threshold), isFalse);
    expect(isAmlEmphasizedLyricWord('  OK  ', threshold), isTrue);
    expect(isAmlEmphasizedLyricWord('1234567', threshold), isTrue);
    expect(isAmlEmphasizedLyricWord('12345678', threshold), isFalse);
    expect(isAmlEmphasizedLyricWord('😀', threshold), isTrue);
    expect(isAmlEmphasizedLyricWord('e\u0301', threshold), isTrue);
  });

  test('CJK 判断与 AMLL 的整词正则相同', () {
    expect(isAmlEmphasizedLyricWord('中 ', threshold), isFalse);
    expect(isAmlEmphasizedLyricWord('A中', threshold), isTrue);
  });
}
