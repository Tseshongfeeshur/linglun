import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/animation.dart';
import 'package:linglun/src/features/player/domain/lyrics.dart';

/// 判断歌词词语是否满足 AMLL 的字符强调条件。
bool isAmlEmphasizedLyricWord(String text, Duration duration) {
  if (duration < const Duration(seconds: 1)) return false;
  if (isAmlCjkLyricWord(text)) return true;

  final trimmedLength = text.trim().length;
  return trimmedLength > 1 && trimmedLength <= 7;
}

bool isAmlCjkLyricWord(String text) => _amllCjkWordPattern.hasMatch(text);

final _amllCjkWordPattern = RegExp(
  r'^[\p{Unified_Ideograph}\u0800-\u9FFC]+$',
  unicode: true,
);

/// AMLL 分词后用于一次字符强调动画的连续词组。
class AmlLyricEmphasisGroup {
  const AmlLyricEmphasisGroup({
    required this.text,
    required this.start,
    required this.end,
    required this.isLastWord,
    required this.characters,
  });

  final String text;
  final Duration start;
  final Duration end;
  final bool isLastWord;
  final List<AmlLyricEmphasisCharacter> characters;
}

/// 组内字符的原文范围及其来源时间词。
class AmlLyricEmphasisCharacter {
  const AmlLyricEmphasisCharacter({
    required this.start,
    required this.end,
    required this.sourceAtomIndex,
  });

  final int start;
  final int end;
  final int sourceAtomIndex;
}

/// AMLL 分词后分别参与普通上浮和歌词遮罩的词片段。
class AmlLyricWordAtom {
  const AmlLyricWordAtom({
    required this.text,
    required this.start,
    required this.end,
    required this.textStart,
    required this.textEnd,
    required this.sourceAtomIndex,
  });

  final String text;
  final Duration start;
  final Duration end;
  final int textStart;
  final int textEnd;
  final int sourceAtomIndex;

  bool get isWhitespace => text.trim().isEmpty;
}

/// 复刻 AMLL 先拆空格和 CJK 字符，再合并连续非 CJK 词组的步骤。
List<AmlLyricWordAtom> buildAmlLyricWordAtoms(
  String text,
  List<LyricWord> words,
) {
  final ranges = _lyricWordRanges(text, words);
  final atoms = <AmlLyricWordAtom>[];
  for (var index = 0; index < words.length; index++) {
    final word = words[index];
    final fallbackEnd = index + 1 < words.length
        ? words[index + 1].start
        : word.start + const Duration(milliseconds: 350);
    final end = word.end ?? fallbackEnd;
    final split = _splitAmlLyricWord(
      word,
      textStart: ranges[index].$1,
      sourceEnd: end < word.start ? word.start : end,
    );
    for (final atom in split) {
      atoms.add(
        AmlLyricWordAtom(
          text: atom.text,
          start: atom.start,
          end: atom.end,
          textStart: atom.textStart,
          textEnd: atom.textEnd,
          sourceAtomIndex: atoms.length,
        ),
      );
    }
  }
  return List.unmodifiable(atoms);
}

/// 按 AMLL 的分组边界判定字符强调，不额外定义“无辉光强调”状态。
List<AmlLyricEmphasisGroup> buildAmlLyricEmphasisGroups(
  String text,
  List<LyricWord> words,
) {
  final atoms = buildAmlLyricWordAtoms(text, words);
  return buildAmlLyricEmphasisGroupsFromAtoms(words, atoms);
}

/// 从同一份绘制词片段生成强调组，保证字符范围与绘制缓存始终一致。
List<AmlLyricEmphasisGroup> buildAmlLyricEmphasisGroupsFromAtoms(
  List<LyricWord> words,
  List<AmlLyricWordAtom> atoms,
) {
  final groups = <AmlLyricEmphasisGroup>[];
  final mergeable = <AmlLyricWordAtom>[];
  void emit(List<AmlLyricWordAtom> chunk) {
    if (chunk.isEmpty) return;
    final mergedText = chunk.map((atom) => atom.text).join();
    final start = chunk
        .map((atom) => atom.start)
        .reduce((first, next) => first < next ? first : next);
    final end = chunk
        .map((atom) => atom.end)
        .reduce((first, next) => first > next ? first : next);
    var emphasized = chunk.any(
      (atom) => isAmlEmphasizedLyricWord(atom.text, atom.end - atom.start),
    );
    if (!isAmlCjkLyricWord(mergedText)) {
      emphasized =
          emphasized || isAmlEmphasizedLyricWord(mergedText, end - start);
    }
    if (!emphasized) return;

    final characters = <AmlLyricEmphasisCharacter>[];
    for (final atom in chunk) {
      if (atom.text.trim().isEmpty) continue;
      var cursor = atom.textStart;
      for (final grapheme in atom.text.characters) {
        if (grapheme.trim().isEmpty) {
          cursor += grapheme.length;
          continue;
        }
        final end = cursor + grapheme.length;
        characters.add(
          AmlLyricEmphasisCharacter(
            start: cursor,
            end: end,
            sourceAtomIndex: atom.sourceAtomIndex,
          ),
        );
        cursor = end;
      }
    }
    if (characters.isEmpty) return;

    final lastWord = words.isEmpty ? '' : words.last.text;
    groups.add(
      AmlLyricEmphasisGroup(
        text: mergedText,
        start: start,
        end: end,
        isLastWord: lastWord.isNotEmpty && mergedText.contains(lastWord),
        characters: List.unmodifiable(characters),
      ),
    );
  }

  void flush() {
    if (mergeable.isEmpty) return;
    emit(List<AmlLyricWordAtom>.of(mergeable));
    mergeable.clear();
  }

  for (final atom in atoms) {
    if (atom.text.trim().isEmpty) {
      flush();
    } else if (isAmlCjkLyricWord(atom.text)) {
      flush();
      emit([atom]);
    } else {
      mergeable.add(atom);
    }
  }
  flush();
  return List.unmodifiable(groups);
}

List<(int, int)> _lyricWordRanges(String text, List<LyricWord> words) {
  final ranges = <(int, int)>[];
  var cursor = 0;
  for (final word in words) {
    var start = text.indexOf(word.text, cursor);
    if (start < 0) start = cursor;
    start = start.clamp(0, text.length);
    final end = (start + word.text.length).clamp(start, text.length);
    ranges.add((start, end));
    cursor = end;
  }
  return ranges;
}

List<_AmlTimedAtom> _splitAmlLyricWord(
  LyricWord word, {
  required int textStart,
  required Duration sourceEnd,
}) {
  final parts = RegExp(r'\s+|\S+').allMatches(word.text);
  final timedLength = word.text.replaceAll(RegExp(r'\s'), '').length;
  final timePerUnit =
      (sourceEnd.inMicroseconds - word.start.inMicroseconds) /
      (timedLength == 0 ? 1 : timedLength);
  var textOffset = 0;
  var timedOffset = 0;
  final atoms = <_AmlTimedAtom>[];

  Duration timeAt(int offset) => Duration(
    microseconds: word.start.inMicroseconds + (offset * timePerUnit).round(),
  );

  void addAtom(String part, int partStart, int unitOffset, int unitLength) {
    atoms.add(
      _AmlTimedAtom(
        text: part,
        start: timeAt(unitOffset),
        end: timeAt(unitOffset + unitLength),
        textStart: partStart,
        textEnd: partStart + part.length,
      ),
    );
  }

  for (final match in parts) {
    final part = match.group(0)!;
    final partStart = textStart + textOffset;
    textOffset += part.length;
    if (part.trim().isEmpty) {
      addAtom(part, partStart, timedOffset, 0);
      continue;
    }
    if (isAmlCjkLyricWord(part) && part.length > 1) {
      var partOffset = 0;
      for (final codeUnit in part.codeUnits) {
        final grapheme = String.fromCharCode(codeUnit);
        addAtom(grapheme, partStart + partOffset, timedOffset + partOffset, 1);
        partOffset++;
      }
      timedOffset += part.length;
    } else {
      addAtom(part, partStart, timedOffset, part.length);
      timedOffset += part.length;
    }
  }
  return atoms;
}

class _AmlTimedAtom {
  const _AmlTimedAtom({
    required this.text,
    required this.start,
    required this.end,
    required this.textStart,
    required this.textEnd,
  });

  final String text;
  final Duration start;
  final Duration end;
  final int textStart;
  final int textEnd;
}

/// 按 AMLL 生成的 32 帧关键帧进行线性插值。
double sampleAmlEmphasisCurve(double progress) =>
    _sampleAmlFrames(progress, (value) => _amllEmphasisEase(value));

/// AMLL 字符浮动动画的 32 帧正弦关键帧。
double sampleAmlEmphasisFloat(double progress) =>
    _sampleAmlFrames(progress, (value) => math.sin(math.pi * value));

double _sampleAmlFrames(double progress, double Function(double) sample) {
  const frameCount = 32;
  final framePosition = progress.clamp(0.0, 1.0) * frameCount;
  final lowerFrame = framePosition.floor();
  if (lowerFrame >= frameCount) return sample(1);

  final upperFrame = lowerFrame + 1;
  final lowerValue = lowerFrame == 0 ? 0.0 : sample(lowerFrame / frameCount);
  final upperValue = sample(upperFrame / frameCount);
  final fraction = framePosition - lowerFrame;
  return lowerValue + (upperValue - lowerValue) * fraction;
}

double _amllEmphasisEase(double value) {
  if (value < .5) {
    return const Cubic(.2, .4, .58, 1).transform(value * 2);
  }
  return 1 - const Cubic(.3, 0, .58, 1).transform((value - .5) * 2);
}
