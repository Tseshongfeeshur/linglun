import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/domain/lyrics.dart';
import 'package:linglun/src/features/player/domain/lyrics_source.dart';
import 'package:linglun/src/features/player/domain/track.dart';

void main() {
  test('解析普通 LRC 和逐字时间标签', () {
    final document = parseLyrics(
      '[00:01.00]第一行\n[00:02.50]<00:02.50>你<00:02.80>好',
    );

    expect(document.lines, hasLength(2));
    expect(document.lines.last.text, '你好');
    expect(document.lines.last.isWordSynchronized, isTrue);
    expect(document.lines.last.words, hasLength(2));
    expect(document.syntax, LyricsSyntax.lrc);
    expect(document.timing, LyricsTiming.word);
  });

  test('解析方括号 Enhanced LRC 的逐字时间、行尾结束时间和翻译', () {
    final document = parseLyrics('''
[00:06.160]Salt [00:06.860]air[00:07.912]
[00:06.160]咸涩的空气[00:09.000]
[00:09.005]And [00:09.325]the [00:09.525]rust [00:09.837]on [00:10.317]your [00:10.693]door[00:11.493]
[00:09.005]你门上的斑斑锈迹[00:11.760]
''');

    expect(document.syntax, LyricsSyntax.lrc);
    expect(document.timing, LyricsTiming.word);
    expect(document.lines, hasLength(2));
    expect(document.lines.first.text, 'Salt air');
    expect(document.lines.first.translation, '咸涩的空气');
    expect(document.lines.first.words, hasLength(2));
    expect(
      document.lines.first.words.first.start,
      const Duration(milliseconds: 6160),
    );
    expect(
      document.lines.first.words.last.end,
      const Duration(milliseconds: 7912),
    );
    expect(document.lines.last.text, 'And the rust on your door');
    expect(document.lines.last.translation, '你门上的斑斑锈迹');
  });

  test('解析只包含逐字时间标签的 Enhanced LRC', () {
    final document = parseLyrics('<00:01.00>你<00:01.30>好');

    expect(document.lines, hasLength(1));
    expect(document.lines.single.start, const Duration(seconds: 1));
    expect(document.lines.single.text, '你好');
    expect(document.lines.single.words, hasLength(2));
    expect(document.timing, LyricsTiming.word);
  });

  test('Enhanced LRC 保留中文逐字歌词之间的空格', () {
    final document = parseLyrics('<00:01.00>你<00:01.30> <00:01.50>好');

    expect(document.lines.single.text, '你 好');
    expect(document.lines.single.words.map((word) => word.text), ['你', '好']);
  });

  test('自动识别没有行级时间标签的内嵌 Enhanced LRC', () {
    final document = parseLyricsFile('''
<00:01.00>你<00:01.30>好
<00:01.00>You<00:01.30>好
''');

    expect(document.syntax, LyricsSyntax.lrc);
    expect(document.timing, LyricsTiming.word);
    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, '你好');
    expect(document.lines.single.translation, 'You好');
    expect(document.plainLyrics, '你好\nYou好');
  });

  test('相同起始时间的下行合并为翻译并保持逐字时间', () {
    final document = parseLyricsFile('''
[00:01.00]<00:01.00>你<00:01.30>好
[00:01.00]<00:01.00>You<00:01.30>好
''');

    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, '你好');
    expect(document.lines.single.translation, 'You好');
    expect(document.lines.single.words, hasLength(2));
    expect(document.lines.single.translationWords, hasLength(2));
  });

  test('同起始时间翻译不会覆盖原文显式结束时间', () {
    final document = parseLyrics('''
[00:00.00]原文[00:01.00]
[00:00.00]译文
[00:10.00]下一句[00:11.00]
''');

    expect(document.lines, hasLength(2));
    expect(document.lines.first.translation, '译文');
    expect(document.lines.first.end, const Duration(seconds: 1));
  });

  test('相同结束时间的下行合并为翻译', () {
    final document = parseLyricsFile('''
1
00:00:01,000 --> 00:00:03,000
原文

2
00:00:02,000 --> 00:00:03,000
译文
''', extension: '.srt');

    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, '原文');
    expect(document.lines.single.translation, '译文');
  });

  test('同结束时间的翻译可跨过不相关歌词合并', () {
    final document = parseLyricsFile('''
1
00:00:01,000 --> 00:00:03,000
原文

2
00:00:02,000 --> 00:00:04,000
中间歌词

3
00:00:02,500 --> 00:00:03,000
译文
''', extension: '.srt');

    expect(document.lines, hasLength(2));
    expect(document.lines.first.text, '原文');
    expect(document.lines.first.translation, '译文');
    expect(document.lines.last.text, '中间歌词');
  });

  test('解析 QRC 的绝对逐字时间并合并翻译', () {
    final document = parseLyricsFile('''
[1000,2000]你(1000,500)好(1500,500)
[1000,2000]You(1000,500) too(1500,500)
''', extension: '.qrc');

    expect(document.syntax, LyricsSyntax.qrc);
    expect(document.timing, LyricsTiming.word);
    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, '你好');
    expect(document.lines.single.translation, 'You too');
    expect(document.lines.single.words.first.start, const Duration(seconds: 1));
    expect(document.lines.single.translationWords, hasLength(2));
  });

  test('解析 YRC 的绝对逐字时间并合并翻译', () {
    final document = parseLyricsFile('''
[1000,2000](1000,500,0)你(1500,500,0)好
[1000,2000](1000,500,0)You(1500,500,0) too
''', extension: '.yrc');

    expect(document.syntax, LyricsSyntax.yrc);
    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, '你好');
    expect(document.lines.single.translation, 'You too');
    expect(document.lines.single.words.first.start, const Duration(seconds: 1));
  });

  test('解析 KRC 的行内相对逐字时间', () {
    final document = parseLyricsFile(
      '[1000,2000]<0,500,0>你<500,500,0>好',
      extension: '.krc',
    );

    expect(document.syntax, LyricsSyntax.krc);
    expect(document.timing, LyricsTiming.word);
    expect(document.lines.single.text, '你好');
    expect(document.lines.single.words.first.start, const Duration(seconds: 1));
    expect(
      document.lines.single.words.last.start,
      const Duration(milliseconds: 1500),
    );
  });

  test('等价的逐字 LRC、QRC、YRC、KRC 与 TTML 归一化结果一致', () {
    final samples = [
      parseLyricsFile(
        '[00:01.00]<00:01.00>你<00:01.50>好<00:02.00>',
        extension: '.lrc',
      ),
      parseLyricsFile('[1000,1000]你(1000,500)好(1500,500)', extension: '.qrc'),
      parseLyricsFile(
        '[1000,1000](1000,500,0)你(1500,500,0)好',
        extension: '.yrc',
      ),
      parseLyricsFile('[1000,1000]<0,500,0>你<500,500,0>好', extension: '.krc'),
      parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml"><body><div>
  <p begin="1s" end="2s"><span begin="0s" end="0.5s">你</span><span begin="0.5s" end="1s">好</span></p>
</div></body></tt>
'''),
    ];

    for (final document in samples) {
      expect(document.timing, LyricsTiming.word);
      expect(document.lines, hasLength(1));
      final line = document.lines.single;
      expect(line.text, '你好');
      expect(line.start, const Duration(seconds: 1));
      expect(line.end, const Duration(seconds: 2));
      expect(line.words.map((word) => word.text), ['你', '好']);
      expect(line.words.map((word) => word.start), [
        const Duration(seconds: 1),
        const Duration(milliseconds: 1500),
      ]);
      expect(line.words.map((word) => word.end), [
        const Duration(milliseconds: 1500),
        const Duration(seconds: 2),
      ]);
    }
  });

  test('KRC 首个词时间之前的无时间前缀不会丢失', () {
    final document = parseLyricsFile(
      '[1000,2000]前缀<0,500,0>正文',
      extension: '.krc',
    );

    expect(document.lines.single.text, '前缀正文');
    expect(document.lines.single.words.single.text, '正文');
  });

  test('相同时间的下行歌词优先识别为翻译', () {
    final document = parseLyrics(
      '[00:01.00][甲]你好\n[00:01.00][乙]世界\n[00:02.00]世界',
    );

    expect(document.lines, hasLength(2));
    expect(document.lines.first.speaker, '甲');
    expect(document.lines.first.translation, '世界');
    expect(document.lines.first.translationWords, isEmpty);
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

  test('自动识别 TTML 的逐行、逐字和翻译', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml" xml:lang="en">
  <body><div>
    <p begin="1s" end="3s"> <span begin="1s" end="1.5s">Hel</span><span begin="1.5s">lo</span> </p>
    <p begin="1s" end="3s" xml:lang="zh" role="translation">你好</p>
  </div></body>
</tt>
''');

    expect(document.syntax, LyricsSyntax.ttml);
    expect(document.timing, LyricsTiming.word);
    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, 'Hello');
    expect(document.lines.single.translation, '你好');
    expect(document.lines.single.words, hasLength(2));
  });

  test('TTML 显式翻译段落先于原文时仍保持主副行语义', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml" xml:lang="en">
  <body><div>
    <p begin="1s" end="3s" xml:lang="zh" role="translation">你好</p>
    <p begin="1s" end="3s">Hello</p>
  </div></body>
</tt>
''');

    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, 'Hello');
    expect(document.lines.single.translation, '你好');
  });

  test('TTML 中原文之后的多个显式翻译保留为主译文和变体', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml" xml:lang="en"><body><div>
  <p begin="1s" end="3s">Hello</p>
  <p begin="1s" end="3s" xml:lang="zh" role="translation">你好</p>
  <p begin="1s" end="3s" xml:lang="ja" role="translation">こんにちは</p>
</div></body></tt>
''');

    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, 'Hello');
    expect(document.lines.single.translation, '你好');
    expect(document.lines.single.variants, hasLength(1));
    expect(document.lines.single.variants.single.text, 'こんにちは');
    expect(document.lines.single.variants.single.role, LyricRole.translation);
  });

  test('TTML 逐层累计父容器偏移，并解析帧和刻度时间', () {
    final nested = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml">
  <body begin="5s"><div begin="2s">
    <p begin="1s" dur="3s"><span begin="0s" dur="1s">词</span></p>
  </div></body>
</tt>
''');
    expect(nested.lines.single.start, const Duration(seconds: 8));
    expect(nested.lines.single.end, const Duration(seconds: 11));
    expect(nested.lines.single.words.single.start, const Duration(seconds: 8));
    expect(nested.lines.single.words.single.end, const Duration(seconds: 9));

    final framesAndTicks = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml"
    xmlns:ttp="http://www.w3.org/ns/ttml#parameter"
    ttp:frameRate="25" ttp:tickRate="50">
  <body><div><p begin="25f" dur="50t">一秒</p></div></body>
</tt>
''');
    expect(framesAndTicks.lines.single.start, const Duration(seconds: 1));
    expect(framesAndTicks.lines.single.end, const Duration(seconds: 2));
  });

  test('TTML seq 容器中未显式定位的行接续前一行', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml"><body>
  <div timeContainer="seq">
    <p dur="1s">第一句</p>
    <p dur="1s">第二句</p>
  </div>
</body></tt>
''');

    expect(document.lines.map((line) => line.start), [
      Duration.zero,
      const Duration(seconds: 1),
    ]);
    expect(document.lines.map((line) => line.end), [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
    ]);
  });

  test('TTML seq 容器按前一行逐字结束时间继续排布', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml"><body>
  <div timeContainer="seq">
    <p><span begin="0s" dur="1s">第一句</span></p>
    <p dur="1s">第二句</p>
  </div>
</body></tt>
''');

    expect(document.lines.map((line) => line.start), [
      Duration.zero,
      const Duration(seconds: 1),
    ]);
    expect(document.lines.map((line) => line.end), [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
    ]);
  });

  test('TTML xml:space preserve 保留歌词中的原始空格', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml" xml:space="preserve"><body><div><p begin="0s">你  好</p></div></body></tt>
''');

    expect(document.lines.single.text, '你  好');
  });

  test('TTML 的 dur 和逐字结束时间可以保留间奏边界', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml"><body><div>
  <p begin="0s" dur="1s">前一句</p>
  <p begin="10s" dur="1s">后一句</p>
</div></body></tt>
''');

    expect(document.lines, hasLength(2));
    expect(document.lines.first.end, const Duration(seconds: 1));
    expect(document.lines.last.end, const Duration(seconds: 11));
  });

  test('TTML 逐字结束时间可以保留后续间奏', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml"><body><div>
  <p begin="0s"><span begin="0s" end="1s">前一句</span></p>
  <p begin="10s" end="11s">后一句</p>
</div></body></tt>
''');

    expect(document.lines, hasLength(2));
    expect(document.lines.first.end, const Duration(seconds: 1));
    expect(document.lines.first.words.single.end, const Duration(seconds: 1));
  });

  test('TTML 对唱背景行独立计时并合并到主唱歌词组', () {
    final document = parseLyricsFile('''
<tt xmlns="http://www.w3.org/ns/ttml">
  <body><div>
    <p begin="1s" end="1.2s" role="background" agent="v2">
      <span begin="0s" end="0.2s">啊</span>
    </p>
    <p begin="1.2s" end="3s" agent="v1">主唱歌词</p>
  </div></body>
</tt>
''');

    expect(document.timing, LyricsTiming.word);
    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, '主唱歌词');
    expect(document.lines.single.variants, hasLength(1));
    final background = document.lines.single.variants.single;
    expect(background.role, LyricRole.alternate);
    expect(background.text, '啊');
    expect(background.start, const Duration(seconds: 1));
    expect(background.end, const Duration(milliseconds: 1200));
    expect(background.words.single.start, const Duration(seconds: 1));
    expect(background.words.single.end, const Duration(milliseconds: 1200));
    expect(document.hasWordTimestamps, isTrue);
  });

  test('无时间戳歌词归一化为纯歌词结构', () {
    final document = parseLyricsFile('第一行\n第二行', extension: '.txt');

    expect(document.syntax, LyricsSyntax.plainText);
    expect(document.timing, LyricsTiming.none);
    expect(document.plainLines, ['第一行', '第二行']);
    expect(document.normalizedData, isA<UntimedLyricsData>());
  });

  test('歌词来源选择优先使用外挂同步歌词', () {
    final selected = selectLyricsSource([
      const LyricsSource(
        content: '纯文本歌词',
        kind: LyricsSourceKind.embedded,
        tagName: 'UNSYNCEDLYRICS',
      ),
      const LyricsSource(
        content: '[00:01.00]外挂歌词',
        kind: LyricsSourceKind.sidecar,
        extension: '.lrc',
      ),
      const LyricsSource(
        content: '[00:01.00]内嵌同步歌词',
        kind: LyricsSourceKind.embedded,
        tagName: 'SYNCEDLYRICS',
      ),
    ]);

    expect(selected?.kind, LyricsSourceKind.sidecar);
    expect(selected?.extension, '.lrc');
  });

  test('独立翻译来源按相同时间戳合并', () {
    final document = parseLyricsSources([
      const LyricsSource(
        content: '[00:01.00]原文',
        kind: LyricsSourceKind.embedded,
      ),
      const LyricsSource(
        content: '[00:01.00]Translation',
        kind: LyricsSourceKind.embedded,
        tagName: 'LYRICS_TRANSLATION_EN',
        language: 'en',
        role: LyricRole.translation,
      ),
    ]);

    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, '原文');
    expect(document.lines.single.translation, 'Translation');
  });

  test('高优先级翻译来源不会挤掉可用的原文来源', () {
    final document = parseLyricsSources([
      const LyricsSource(
        content: '[00:01.00]原文',
        kind: LyricsSourceKind.embedded,
        tagName: 'LRC',
      ),
      const LyricsSource(
        content: '[00:01.00]译文',
        kind: LyricsSourceKind.sidecar,
        extension: '.lrc',
        role: LyricRole.translation,
        tagName: 'SYNCEDLYRICS',
      ),
    ]);

    expect(document.lines.single.text, '原文');
    expect(document.lines.single.translation, '译文');
  });

  test('外挂无时间翻译按行号合并到带时间原文且不会重复使用', () {
    final document = parseLyricsSources([
      const LyricsSource(
        content: '''
1
00:00:01,000 --> 00:00:03,000
第一句

2
00:00:02,000 --> 00:00:04,000
第二句
''',
        kind: LyricsSourceKind.embedded,
        extension: '.srt',
      ),
      const LyricsSource(
        content: '第一句译文\n第二句译文',
        kind: LyricsSourceKind.sidecar,
        extension: '.txt',
        role: LyricRole.translation,
      ),
    ]);

    expect(document.lines.map((line) => line.translation), ['第一句译文', '第二句译文']);
  });

  test('外挂同步翻译的一条记录最多关联一行', () {
    final document = parseLyricsSources([
      const LyricsSource(
        content: '''
1
00:00:01,000 --> 00:00:03,000
原文一

2
00:00:02,000 --> 00:00:04,000
原文二
''',
        kind: LyricsSourceKind.embedded,
        extension: '.srt',
      ),
      const LyricsSource(
        content: '1\n00:00:01,000 --> 00:00:04,000\n单条译文',
        kind: LyricsSourceKind.sidecar,
        extension: '.srt',
        role: LyricRole.translation,
      ),
    ]);

    expect(document.lines.first.translation, '单条译文');
    expect(document.lines.last.translation, isNull);
  });

  test('Track 对旧数据也能提供统一歌词文档', () {
    const track = Track(
      id: 'track',
      title: '歌曲',
      artist: '艺术家',
      album: '专辑',
      duration: Duration(minutes: 3),
      lyrics: '[00:01.00]第一行',
      lyricsFormat: '.lrc',
    );

    expect(track.lyricsDocument.lines.single.text, '第一行');
    expect(track.lyricsDocument.timing, LyricsTiming.line);
  });
}
