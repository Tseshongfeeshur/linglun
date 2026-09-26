import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/domain/lyrics.dart';
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

  test('相邻的无空格非 CJK 片段先合并，再按合并词判定', () {
    final groups = buildAmlLyricEmphasisGroups('sunrise', [
      LyricWord(
        start: Duration.zero,
        end: const Duration(milliseconds: 600),
        text: 'sun',
      ),
      LyricWord(
        start: const Duration(milliseconds: 600),
        end: const Duration(milliseconds: 1200),
        text: 'rise',
      ),
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.text, 'sunrise');
    expect(groups.single.characters, hasLength(7));
    expect(groups.single.isLastWord, isTrue);
  });

  test('不满足判定的普通词保留逐词片段但不建立字符强调组', () {
    final atoms = buildAmlLyricWordAtoms('wonderfully', [
      LyricWord(
        start: Duration.zero,
        end: const Duration(milliseconds: 900),
        text: 'wonderfully',
      ),
    ]);
    final groups = buildAmlLyricEmphasisGroupsFromAtoms([
      LyricWord(
        start: Duration.zero,
        end: const Duration(milliseconds: 900),
        text: 'wonderfully',
      ),
    ], atoms);

    expect(atoms, hasLength(1));
    expect(atoms.single.text, 'wonderfully');
    expect(groups, isEmpty);
  });

  test('同一分词结果供普通上浮和强调组使用', () {
    final words = [
      LyricWord(
        start: Duration.zero,
        end: const Duration(milliseconds: 600),
        text: 'sun',
      ),
      LyricWord(
        start: const Duration(milliseconds: 600),
        end: const Duration(milliseconds: 1200),
        text: 'rise',
      ),
    ];
    final atoms = buildAmlLyricWordAtoms('sunrise', words);
    final groups = buildAmlLyricEmphasisGroupsFromAtoms(words, atoms);

    expect(atoms.map((atom) => atom.text), ['sun', 'rise']);
    expect(groups, hasLength(1));
    expect(groups.single.text, 'sunrise');
    expect(groups.single.characters, hasLength(7));
    expect(
      groups.single.characters
          .map((character) => character.sourceAtomIndex)
          .toSet(),
      {0, 1},
    );
  });

  test('空白打断连续词组，且只强调自身满足条件的词', () {
    final groups = buildAmlLyricEmphasisGroups('sun rise', [
      LyricWord(
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'sun',
      ),
      LyricWord(
        start: const Duration(seconds: 1),
        end: const Duration(seconds: 1),
        text: ' ',
      ),
      LyricWord(
        start: const Duration(seconds: 1),
        end: const Duration(milliseconds: 1900),
        text: 'rise',
      ),
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.text, 'sun');
  });

  test('CJK 连续片段按字符分组并分别判定时间', () {
    final groups = buildAmlLyricEmphasisGroups('中文', [
      LyricWord(
        start: Duration.zero,
        end: const Duration(seconds: 2),
        text: '中文',
      ),
    ]);

    expect(groups.map((group) => group.text), ['中', '文']);
    expect(groups.every((group) => group.characters.length == 1), isTrue);
    expect(
      buildAmlLyricEmphasisGroups('中文', [
        LyricWord(
          start: Duration.zero,
          end: const Duration(milliseconds: 999),
          text: '中文',
        ),
      ]),
      isEmpty,
    );
  });

  test('强调曲线使用 AMLL 32 帧采样插值', () {
    expect(sampleAmlEmphasisCurve(0), 0);
    expect(sampleAmlEmphasisCurve(1), 0);
    expect(sampleAmlEmphasisFloat(0), 0);
    expect(sampleAmlEmphasisFloat(1), closeTo(0, 1e-12));
    expect(sampleAmlEmphasisFloat(.5), closeTo(1, .003));
  });
}
