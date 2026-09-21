import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/domain/lyrics.dart';

void main() {
  test('解析普通 LRC 和逐字时间标签', () {
    final document = parseLyrics(
      '[00:01.00]第一行\n[00:02.50]<00:02.50>你<00:02.80>好',
    );

    expect(document.lines, hasLength(2));
    expect(document.lines.last.text, '你好');
    expect(document.lines.last.isWordSynchronized, isTrue);
    expect(document.lines.last.words, hasLength(2));
  });

  test('解析 SRT、VTT 和 ASS 起始时间', () {
    expect(
      parseLyricsFile(
        '1\n00:00:01,500 --> 00:00:03,000\n你好',
        extension: '.srt',
      ).lines.single.start,
      const Duration(seconds: 1, milliseconds: 500),
    );
    expect(
      parseLyricsFile(
        'WEBVTT\n\n00:01:01.250 --> 00:01:02.000\n你好',
        extension: '.vtt',
      ).lines.single.start,
      const Duration(minutes: 1, seconds: 1, milliseconds: 250),
    );
    expect(
      parseLyricsFile(
        'Dialogue: 0,0:00:02.50,0:00:04.00,Default,,0,0,0,,你好',
        extension: '.ass',
      ).lines.single.start,
      const Duration(seconds: 2, milliseconds: 500),
    );
  });
}
