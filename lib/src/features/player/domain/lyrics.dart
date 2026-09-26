import 'package:xml/xml.dart';

/// 歌词来源的语法格式。
enum LyricsSyntax {
  lrc,
  qrc,
  yrc,
  krc,
  ttml,
  srt,
  vtt,
  ass,
  plainText,
  unknown,
}

/// 歌词时间戳的粒度。
enum LyricsTiming { none, line, word }

/// 歌词片段的语义角色，用于翻译和对唱等扩展场景。
enum LyricRole { original, translation, alternate }

extension LyricsSyntaxLabel on LyricsSyntax {
  String get label => switch (this) {
    LyricsSyntax.lrc => 'LRC / Enhanced LRC',
    LyricsSyntax.qrc => 'QRC',
    LyricsSyntax.yrc => 'YRC',
    LyricsSyntax.krc => 'KRC',
    LyricsSyntax.ttml => 'TTML',
    LyricsSyntax.srt => 'SRT',
    LyricsSyntax.vtt => 'WebVTT',
    LyricsSyntax.ass => 'ASS / SSA',
    LyricsSyntax.plainText => '纯文本',
    LyricsSyntax.unknown => '未知格式',
  };
}

extension LyricsTimingLabel on LyricsTiming {
  String get label => switch (this) {
    LyricsTiming.none => '无时间戳',
    LyricsTiming.line => '逐行时间戳',
    LyricsTiming.word => '逐字时间戳',
  };
}

/// 歌词中的一个逐字时间片段。
class LyricWord {
  const LyricWord({
    required this.start,
    required this.text,
    this.end,
    this.speaker,
  });

  final Duration start;
  final Duration? end;
  final String text;
  final String? speaker;
}

/// 同一时间点下的一段附加歌词，例如翻译或另一位演唱者的歌词。
class LyricVariant {
  const LyricVariant({
    required this.text,
    this.start,
    this.end,
    this.words = const [],
    this.role = LyricRole.alternate,
    this.language,
    this.speaker,
  });

  final String text;
  final Duration? start;
  final Duration? end;
  final List<LyricWord> words;
  final LyricRole role;
  final String? language;
  final String? speaker;

  bool get isTranslation => role == LyricRole.translation;
}

/// 一行歌词，可同时包含整行时间、逐字时间、翻译和说话者信息。
class LyricLine {
  const LyricLine({
    required this.start,
    required this.text,
    this.words = const [],
    this.translation,
    this.translationWords = const [],
    this.end,
    this.speaker,
    this.language,
    this.role = LyricRole.original,
    this.variants = const [],
  });

  final Duration start;
  final Duration? end;
  final String text;
  final List<LyricWord> words;
  final String? translation;
  final List<LyricWord> translationWords;
  final String? speaker;
  final String? language;
  final LyricRole role;
  final List<LyricVariant> variants;

  bool get isWordSynchronized => words.isNotEmpty;

  LyricLine copyWith({
    Duration? start,
    Duration? end,
    String? translation,
    List<LyricWord>? translationWords,
    String? speaker,
    String? language,
    LyricRole? role,
    List<LyricVariant>? variants,
  }) {
    return LyricLine(
      start: start ?? this.start,
      end: end ?? this.end,
      text: text,
      words: words,
      translation: translation ?? this.translation,
      translationWords: translationWords ?? this.translationWords,
      speaker: speaker ?? this.speaker,
      language: language ?? this.language,
      role: role ?? this.role,
      variants: variants ?? this.variants,
    );
  }
}

/// 无时间戳歌词的归一化数据结构。
class UntimedLyricsData {
  const UntimedLyricsData(this.lines);

  final List<String> lines;

  String get text => lines.join('\n');
}

/// 逐行时间戳歌词的归一化数据结构。
class LineTimedLyricsData {
  const LineTimedLyricsData(this.lines);

  final List<LyricLine> lines;
}

/// 逐字时间戳歌词的归一化数据结构。
class WordTimedLyricsData extends LineTimedLyricsData {
  const WordTimedLyricsData(super.lines);
}

/// 歌词解析后的统一文档。
class LyricsDocument {
  const LyricsDocument({
    this.lines = const [],
    this.plainLines = const [],
    this.offset = Duration.zero,
    this.syntax = LyricsSyntax.unknown,
    this.timing = LyricsTiming.none,
    this.metadata = const {},
  });

  /// 有时间戳时使用的逐行数据。
  final List<LyricLine> lines;

  /// 无时间戳时使用的纯歌词行。
  final List<String> plainLines;

  final Duration offset;
  final LyricsSyntax syntax;
  final LyricsTiming timing;
  final Map<String, String> metadata;

  bool get hasTimestamps => timing != LyricsTiming.none;

  /// 含独立逐字时间的对唱/背景声部也属于逐字歌词。
  bool get hasWordTimestamps => lines.any(
    (line) =>
        line.words.isNotEmpty ||
        line.translationWords.isNotEmpty ||
        line.variants.any((variant) => variant.words.isNotEmpty),
  );

  String get plainLyrics {
    if (plainLines.isNotEmpty) return plainLines.join('\n');
    return lines
        .map(
          (line) => [
            line.text,
            if (line.translation != null) line.translation!,
            for (final variant in line.variants) variant.text,
          ].join('\n'),
        )
        .join('\n');
  }

  /// 暴露三种归一化数据结构，让渲染层无需关心原始语法。
  Object get normalizedData => switch (timing) {
    LyricsTiming.none => UntimedLyricsData(plainLines),
    LyricsTiming.line => LineTimedLyricsData(lines),
    LyricsTiming.word => WordTimedLyricsData(lines),
  };

  String get syntaxLabel => syntax.label;
  String get timingLabel => timing.label;

  LyricsDocument copyWith({LyricsSyntax? syntax}) {
    return LyricsDocument(
      lines: lines,
      plainLines: plainLines,
      offset: offset,
      syntax: syntax ?? this.syntax,
      timing: timing,
      metadata: metadata,
    );
  }
}

/// 自动识别并解析普通 LRC、逐字歌词和无时间戳纯文本。
LyricsDocument parseLyrics(String source) => parseLyricsFile(source);

/// 自动识别歌词语法；内容特征优先于文件扩展名。
LyricsDocument parseLyricsFile(String source, {String? extension}) {
  final syntax = _detectSyntax(source, extension);
  return switch (syntax) {
    LyricsSyntax.ttml => _parseTtml(source),
    LyricsSyntax.srt => _parseSubtitleBlocks(
      source,
      _srtTimestamp,
      LyricsSyntax.srt,
    ),
    LyricsSyntax.vtt => _parseSubtitleBlocks(
      source,
      _vttTimestamp,
      LyricsSyntax.vtt,
    ),
    LyricsSyntax.ass => _parseAss(source),
    LyricsSyntax.lrc => _parseLrc(source),
    LyricsSyntax.qrc => _parseQrc(source),
    LyricsSyntax.yrc => _parseYrc(source),
    LyricsSyntax.krc => _parseKrc(source),
    LyricsSyntax.plainText => _parsePlainText(source),
    LyricsSyntax.unknown => _parsePlainText(source),
  };
}

LyricsSyntax _detectSyntax(String source, String? extension) {
  final trimmed = source.trimLeft();
  final normalizedExtension = extension?.toLowerCase().trim();

  bool hasExtension(String value) =>
      normalizedExtension == value || normalizedExtension == '.$value';

  if ((trimmed.startsWith('<') || trimmed.startsWith('<?xml')) &&
      RegExp(
        r'<(?:\w+:)?(?:tt|body|div|p)\b',
        caseSensitive: false,
      ).hasMatch(trimmed)) {
    return LyricsSyntax.ttml;
  }
  if (hasExtension('ttml') || hasExtension('xml')) {
    return LyricsSyntax.ttml;
  }
  if (trimmed.startsWith('WEBVTT')) {
    return LyricsSyntax.vtt;
  }
  if (RegExp(r'\d{2}:\d{2}:\d{2},\d{3}\s+-->').hasMatch(source) ||
      hasExtension('srt')) {
    return LyricsSyntax.srt;
  }
  if (hasExtension('vtt') ||
      RegExp(r'\d{2}:\d{2}(?::\d{2})?\.\d{3}\s+-->').hasMatch(source)) {
    return LyricsSyntax.vtt;
  }
  if (hasExtension('ass') ||
      hasExtension('ssa') ||
      source.contains('Dialogue:')) {
    return LyricsSyntax.ass;
  }
  final hasYrcContent = RegExp(
    r'^\s*\[\d+\s*[,，]\s*\d+\s*\]\s*\(\d+\s*[,，]\s*\d+\s*[,，]\s*\d+\s*\)',
    multiLine: true,
  ).hasMatch(source);
  final hasQrcContent = RegExp(
    r'^\s*\[\d+\s*[,，]\s*\d+\s*\].*?\(\d+\s*[,，]\s*\d+\s*\)',
    multiLine: true,
  ).hasMatch(source);
  final hasKrcContent = RegExp(
    r'^\s*\[\d+\s*[,，]\s*\d+\s*\].*?<\d+\s*[,，]\s*\d+\s*[,，]\s*\d+\s*>',
    multiLine: true,
  ).hasMatch(source);
  if (hasExtension('yrc') || hasYrcContent) return LyricsSyntax.yrc;
  if (hasExtension('qrc') || hasQrcContent) return LyricsSyntax.qrc;
  if (hasExtension('krc') || hasKrcContent) return LyricsSyntax.krc;
  // Enhanced LRC 既可能使用行首方括号，也可能只使用逐字尖括号。
  // 内嵌歌词通常没有文件扩展名，因此不能只依赖扩展名判断格式。
  final hasLrcLineTimestamp = RegExp(
    r'^\s*\[\s*(?:\d+(?::\d{1,3}){1,2}(?:[.,]\d{1,3})?|\d+\s*[,，]\s*\d+(?:\s*[,，]\s*\d+)?)\s*\]',
    multiLine: true,
  ).hasMatch(source);
  final hasEnhancedWordTimestamp = RegExp(
    r'(?:<\s*\d+(?::\d{1,3}){1,2}(?:[.,]\d{1,3})?\s*>|'
    r'<\s*\d+\s*[,，]\s*\d+(?:\s*[,，]\s*\d+)?\s*>|'
    r'\(\s*\d+\s*[,，]\s*\d+(?:\s*[,，]\s*\d+)?\s*\))',
  ).hasMatch(source);
  if (hasExtension('lrc') ||
      hasExtension('elrc') ||
      hasLrcLineTimestamp ||
      hasEnhancedWordTimestamp ||
      RegExp(
        r'^\s*\[offset\s*:',
        caseSensitive: false,
        multiLine: true,
      ).hasMatch(source)) {
    return LyricsSyntax.lrc;
  }
  return LyricsSyntax.plainText;
}

LyricsDocument _parsePlainText(String source) {
  final lines = source
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.trim().isNotEmpty)
      .toList();
  return LyricsDocument(
    plainLines: lines,
    syntax: LyricsSyntax.plainText,
    timing: LyricsTiming.none,
  );
}

LyricsDocument _parseLrc(String source) {
  final timedLines = <LyricLine>[];
  final plainLines = <String>[];
  final metadata = <String, String>{};
  var offset = Duration.zero;

  for (final line in _normalizedLyricLines(source)) {
    final tags = <_BracketTag>[];
    var cursor = 0;
    while (cursor < line.length && line[cursor] == '[') {
      final close = line.indexOf(']', cursor);
      if (close == -1) break;
      final value = line.substring(cursor + 1, close);
      if (_parseLrcTimestamp(value) == null && !value.contains(':')) break;
      tags.add(_BracketTag(value, cursor, close + 1));
      cursor = close + 1;
    }

    final timestamps = <Duration>[];
    var hasMetadataTag = false;
    for (final tag in tags) {
      final timestamp = _parseLrcTimestamp(tag.value);
      if (timestamp != null) {
        timestamps.add(timestamp);
        continue;
      }

      final separator = tag.value.indexOf(':');
      if (separator == -1) continue;
      hasMetadataTag = true;
      final key = tag.value.substring(0, separator).trim().toLowerCase();
      final value = tag.value.substring(separator + 1).trim();
      if (key == 'offset') {
        offset = Duration(milliseconds: int.tryParse(value) ?? 0);
      } else {
        metadata[key] = value;
      }
    }

    final text = line.substring(cursor).trim();
    final speakerInfo = _extractSpeaker(text);
    final wordResult = _parseLrcWords(
      speakerInfo.text,
      speaker: speakerInfo.speaker,
      initialStart: timestamps.firstOrNull,
    );
    final cleanText = wordResult.text;

    // 某些扩展 LRC 只写逐字时间标签，不再重复写整行时间标签。
    if (timestamps.isEmpty) {
      if (wordResult.firstStart != null) {
        timedLines.add(
          LyricLine(
            start: wordResult.firstStart!,
            end: wordResult.words.lastOrNull?.end,
            text: cleanText,
            words: wordResult.words,
            speaker: speakerInfo.speaker,
          ),
        );
      } else if (cleanText.isNotEmpty && !metadata.containsValue(cleanText)) {
        if (!hasMetadataTag) plainLines.add(cleanText);
      }
      continue;
    }
    if (cleanText.isEmpty) continue;

    for (final timestamp in timestamps) {
      timedLines.add(
        LyricLine(
          start: timestamp,
          end: wordResult.words.lastOrNull?.end,
          text: cleanText,
          words: wordResult.words,
          speaker: speakerInfo.speaker,
        ),
      );
    }
  }

  if (timedLines.isEmpty) {
    return LyricsDocument(
      plainLines: plainLines,
      offset: offset,
      syntax: LyricsSyntax.lrc,
      timing: LyricsTiming.none,
      metadata: metadata,
    );
  }
  return _timedDocument(
    timedLines,
    offset: offset,
    syntax: LyricsSyntax.lrc,
    metadata: metadata,
  );
}

/// 解析 QQ 音乐 QRC：行时间在行首，逐词时间位于词尾。
///
/// 典型结构为 `[行开始毫秒,行时长]文字(词开始毫秒,词时长)文字...`。
LyricsDocument _parseQrc(String source) {
  final lines = <LyricLine>[];
  for (final rawLine in _normalizedLyricLines(source)) {
    final match = RegExp(r'^\s*\[\s*(\d+)\s*[,，]\s*(\d+)\s*\](.*)$')
        .firstMatch(rawLine);
    if (match == null) continue;

    final lineStart = Duration(milliseconds: int.parse(match.group(1)!));
    final lineEnd =
        lineStart + Duration(milliseconds: int.parse(match.group(2)!));
    final parsed = _parseQrcWords(match.group(3)!);
    final text = parsed.text.trim();
    if (text.isEmpty) continue;
    lines.add(
      LyricLine(
        start: lineStart,
        end: lineEnd,
        text: text,
        words: parsed.words,
      ),
    );
  }
  return _timedDocument(lines, syntax: LyricsSyntax.qrc);
}

/// 解析网易云 YRC：行时间在行首，逐词时间位于词首。
///
/// 典型结构为 `[行开始毫秒,行时长](词开始毫秒,词时长,属性)文字...`。
LyricsDocument _parseYrc(String source) {
  final lines = <LyricLine>[];
  for (final rawLine in _normalizedLyricLines(source)) {
    final match = RegExp(r'^\s*\[\s*(\d+)\s*[,，]\s*(\d+)\s*\](.*)$')
        .firstMatch(rawLine);
    if (match == null) continue;

    final lineStart = Duration(milliseconds: int.parse(match.group(1)!));
    final lineEnd =
        lineStart + Duration(milliseconds: int.parse(match.group(2)!));
    final parsed = _parseYrcWords(match.group(3)!);
    final text = parsed.text.trim();
    if (text.isEmpty) continue;
    lines.add(
      LyricLine(
        start: lineStart,
        end: lineEnd,
        text: text,
        words: parsed.words,
      ),
    );
  }
  return _timedDocument(lines, syntax: LyricsSyntax.yrc);
}

/// 解析酷狗 KRC：行时间在行首，逐词时间位于词首。
///
/// KRC 的常见明文结构为 `[行开始毫秒,行时长]<词开始毫秒,词时长,属性>文字...`。
/// 加密的 KRC 需要先在音频元数据层解密，解析器只处理已经解码的文本。
LyricsDocument _parseKrc(String source) {
  final lines = <LyricLine>[];
  for (final rawLine in _normalizedLyricLines(source)) {
    final match = RegExp(r'^\s*\[\s*(\d+)\s*[,，]\s*(\d+)\s*\](.*)$')
        .firstMatch(rawLine);
    if (match == null) continue;

    final lineStart = Duration(milliseconds: int.parse(match.group(1)!));
    final lineEnd =
        lineStart + Duration(milliseconds: int.parse(match.group(2)!));
    final parsed = _parseKrcWords(match.group(3)!, lineStart);
    if (parsed.text.isEmpty) continue;
    lines.add(
      LyricLine(
        start: lineStart,
        end: lineEnd,
        text: parsed.text,
        words: parsed.words,
      ),
    );
  }
  return _timedDocument(lines, syntax: LyricsSyntax.krc);
}

Iterable<String> _normalizedLyricLines(String source) => source
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n')
    .split('\n')
    .map((line) => line.trimRight())
    .where((line) => line.trim().isNotEmpty);

({String text, List<LyricWord> words}) _parseQrcWords(String source) {
  final markers = RegExp(r'\(\s*\d+\s*[,，]\s*\d+(?:\s*[,，]\s*\d+)?\s*\)')
      .allMatches(source)
      .toList();
  if (markers.isEmpty) {
    return (text: _cleanLyricText(source), words: const []);
  }

  final words = <LyricWord>[];
  final textBuffer = StringBuffer();
  var cursor = 0;
  for (final marker in markers) {
    final wordText = source.substring(cursor, marker.start);
    final timing = _parseRelativeTiming(marker.group(0)!);
    if (timing == null) continue;
    textBuffer.write(wordText);
    if (wordText.isNotEmpty) {
      words.add(
        LyricWord(
          // QRC 词时间从音频起点计算，不能再次叠加行起始时间。
          start: timing.start,
          end: timing.end,
          text: wordText,
        ),
      );
    }
    cursor = marker.end;
  }
  textBuffer.write(source.substring(cursor));
  return (
    text: _cleanLyricText(textBuffer.toString()),
    words: _completeWordEnds(words),
  );
}

({String text, List<LyricWord> words}) _parseYrcWords(String source) {
  final markers = RegExp(r'\(\s*\d+\s*[,，]\s*\d+(?:\s*[,，]\s*\d+)?\s*\)')
      .allMatches(source)
      .toList();
  if (markers.isEmpty) {
    return (text: _cleanLyricText(source), words: const []);
  }

  final words = <LyricWord>[];
  final textBuffer = StringBuffer();
  var cursor = 0;
  for (var index = 0; index < markers.length; index++) {
    final marker = markers[index];
    final timing = _parseRelativeTiming(marker.group(0)!);
    if (timing == null) continue;
    if (marker.start > cursor) {
      textBuffer.write(source.substring(cursor, marker.start));
    }
    final wordEnd = index + 1 < markers.length
        ? markers[index + 1].start
        : source.length;
    final wordText = source.substring(marker.end, wordEnd);
    if (wordText.isNotEmpty) {
      words.add(
        LyricWord(
          // YRC 词时间从音频起点计算，第三个数字是扩展属性。
          start: timing.start,
          end: timing.end,
          text: wordText,
        ),
      );
      textBuffer.write(wordText);
    }
    cursor = wordEnd;
  }
  if (cursor < source.length) textBuffer.write(source.substring(cursor));
  return (
    text: _cleanLyricText(textBuffer.toString()),
    words: _completeWordEnds(words),
  );
}

({String text, List<LyricWord> words}) _parseKrcWords(
  String source,
  Duration lineStart,
) {
  final markers = RegExp(r'<\s*\d+\s*[,，]\s*\d+\s*[,，]\s*\d+\s*>')
      .allMatches(source)
      .toList();
  if (markers.isEmpty) {
    return (text: _cleanLyricText(source), words: const []);
  }

  final words = <LyricWord>[];
  final textBuffer = StringBuffer();
  for (var index = 0; index < markers.length; index++) {
    final marker = markers[index];
    final timing = _parseRelativeTiming(marker.group(0)!);
    if (timing == null) continue;
    final segmentEnd = index + 1 < markers.length
        ? markers[index + 1].start
        : source.length;
    final wordText = _stripLyricMarkup(
      source.substring(marker.end, segmentEnd),
    );
    if (wordText.isEmpty) continue;
    final start = lineStart + timing.start;
    final end = timing.end == null ? null : lineStart + timing.end!;
    words.add(LyricWord(start: start, end: end, text: wordText));
    textBuffer.write(wordText);
  }
  return (
    text: _cleanLyricText(textBuffer.toString()),
    words: _completeWordEnds(words),
  );
}

LyricsDocument _parseSubtitleBlocks(
  String source,
  Duration? Function(String) timestampParser,
  LyricsSyntax syntax,
) {
  final lines = <LyricLine>[];
  final plainLines = <String>[];
  final blocks = source.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));
  for (final block in blocks) {
    final rows = block.split('\n').map((line) => line.trim()).toList();
    final timingIndex = rows.indexWhere((row) => row.contains('-->'));
    if (timingIndex == -1 || timingIndex + 1 >= rows.length) {
      plainLines.addAll(rows.where((row) => row.isNotEmpty));
      continue;
    }
    final timing = rows[timingIndex].split('-->');
    final start = timestampParser(timing.first.trim().split(' ').first);
    if (start == null) continue;
    final end = timing.length > 1
        ? timestampParser(timing[1].trim().split(' ').first)
        : null;
    final text = rows.sublist(timingIndex + 1).join('\n').trim();
    if (text.isNotEmpty) {
      lines.add(LyricLine(start: start, end: end, text: text));
    }
  }
  if (lines.isEmpty) {
    return LyricsDocument(
      plainLines: plainLines,
      syntax: syntax,
      timing: LyricsTiming.none,
    );
  }
  return _timedDocument(lines, syntax: syntax);
}

Duration? _srtTimestamp(String value) {
  final match = RegExp(r'^(\d+):(\d{2}):(\d{2})[,.](\d{3})').firstMatch(value);
  if (match == null) return null;
  return Duration(
    hours: int.parse(match.group(1)!),
    minutes: int.parse(match.group(2)!),
    seconds: int.parse(match.group(3)!),
    milliseconds: int.parse(match.group(4)!),
  );
}

Duration? _vttTimestamp(String value) {
  final match = RegExp(r'(?:(\d+):)?(\d{2}):(\d{2})\.(\d{3})')
      .firstMatch(value);
  if (match == null) return null;
  return Duration(
    hours: int.tryParse(match.group(1) ?? '0') ?? 0,
    minutes: int.parse(match.group(2)!),
    seconds: int.parse(match.group(3)!),
    milliseconds: int.parse(match.group(4)!),
  );
}

LyricsDocument _parseAss(String source) {
  final lines = <LyricLine>[];
  final plainLines = <String>[];
  for (final row in source.split('\n')) {
    if (!row.startsWith('Dialogue:')) continue;
    final fields = row.substring('Dialogue:'.length).split(',');
    if (fields.length < 10) continue;
    final start = _assTimestamp(fields[1].trim());
    final end = _assTimestamp(fields[2].trim());
    if (start == null) continue;
    final rawText = fields.sublist(9).join(',');
    final text = rawText.replaceAll(RegExp(r'\{[^}]*\}'), '');
    final words = _parseAssWords(rawText, start);
    final clean = text.replaceAll(RegExp(r'\\[Nn]'), '\n').trim();
    if (clean.isNotEmpty) {
      lines.add(LyricLine(start: start, end: end, text: clean, words: words));
    }
  }
  if (lines.isEmpty) {
    return LyricsDocument(
      plainLines: plainLines,
      syntax: LyricsSyntax.ass,
      timing: LyricsTiming.none,
    );
  }
  return _timedDocument(lines, syntax: LyricsSyntax.ass);
}

Duration? _assTimestamp(String value) {
  final match = RegExp(r'^(\d+):(\d{2}):(\d{2})\.(\d{2})').firstMatch(value);
  if (match == null) return null;
  return Duration(
    hours: int.parse(match.group(1)!),
    minutes: int.parse(match.group(2)!),
    seconds: int.parse(match.group(3)!),
    milliseconds: int.parse(match.group(4)!) * 10,
  );
}

List<LyricWord> _parseAssWords(String raw, Duration lineStart) {
  final matches = RegExp(r'\{\\(?:k|K|kf|ko)(\d+)\}').allMatches(raw).toList();
  if (matches.isEmpty) return const [];
  final words = <LyricWord>[];
  var cursor = Duration.zero;
  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    final end = index + 1 < matches.length
        ? matches[index + 1].start
        : raw.length;
    final text = raw
        .substring(match.end, end)
        .replaceAll(RegExp(r'\{[^}]*\}'), '')
        .replaceAll(RegExp(r'\\[Nn]'), '\n');
    final start = lineStart + cursor;
    cursor += Duration(milliseconds: int.parse(match.group(1)!) * 10);
    if (text.trim().isNotEmpty) {
      words.add(LyricWord(start: start, end: lineStart + cursor, text: text));
    }
  }
  return words;
}

LyricsDocument _parseTtml(String source) {
  try {
    final document = XmlDocument.parse(source);
    final paragraphs = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local.toLowerCase() == 'p')
        .toList();
    final root = document.rootElement;
    final rootLanguage = _xmlAttribute(root, 'lang');
    final lines = <LyricLine>[];
    final plainLines = <String>[];

    for (final paragraph in paragraphs) {
      final paragraphBegin = _parseTtmlTime(_xmlAttribute(paragraph, 'begin'));
      final paragraphStart = paragraphBegin?.value;
      final paragraphEndValue = _parseTtmlTime(_xmlAttribute(paragraph, 'end'));
      final paragraphDuration = _parseTtmlTime(_xmlAttribute(paragraph, 'dur'));
      // p 的 begin/end 都相对父时间容器；不能把 end 再叠加到 begin 上。
      final paragraphEnd =
          paragraphEndValue?.value ??
          (paragraphStart != null && paragraphDuration != null
              ? paragraphStart + paragraphDuration.value
              : null);
      final paragraphLanguage = _xmlAttribute(paragraph, 'lang');
      final role = _xmlAttribute(paragraph, 'role');
      final speaker = _firstNonEmpty([
        _xmlAttribute(paragraph, 'agent'),
        _xmlAttribute(paragraph, 'speaker'),
        _xmlAttribute(paragraph, 'voice'),
      ]);
      final isTranslation = _isTranslation(
        role: role,
        language: paragraphLanguage,
        rootLanguage: rootLanguage,
      );
      final isBackground = _isBackgroundRole(role);
      final wordElements = paragraph.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local.toLowerCase() == 'span')
          .where((element) => _xmlAttribute(element, 'begin') != null)
          .toList();
      final words = <LyricWord>[];
      for (final wordElement in wordElements) {
        final rawBegin = _parseTtmlTime(_xmlAttribute(wordElement, 'begin'));
        if (rawBegin == null) continue;
        final wordStart = _resolveTtmlTime(rawBegin, paragraphStart);
        final rawEnd = _parseTtmlTime(_xmlAttribute(wordElement, 'end'));
        final rawDuration = _parseTtmlTime(_xmlAttribute(wordElement, 'dur'));
        final wordEnd = rawEnd != null
            ? _resolveTtmlTime(rawEnd, paragraphStart)
            : rawDuration != null
            ? wordStart + rawDuration.value
            : null;
        final text = _cleanTtmlText(wordElement.innerText);
        if (text.isEmpty) continue;
        words.add(
          LyricWord(
            start: wordStart,
            end: wordEnd,
            text: text,
            speaker: _firstNonEmpty([
              _xmlAttribute(wordElement, 'agent'),
              _xmlAttribute(wordElement, 'speaker'),
            ]),
          ),
        );
      }
      final text = _cleanTtmlText(paragraph.innerText);
      if (text.isEmpty) continue;

      final start = paragraphStart ?? words.firstOrNull?.start;
      if (start == null) {
        plainLines.add(text);
        continue;
      }
      lines.add(
        LyricLine(
          start: start,
          end: paragraphEnd,
          text: text,
          words: words,
          speaker: speaker,
          language: paragraphLanguage,
          role: isBackground
              ? LyricRole.alternate
              : isTranslation
              ? LyricRole.translation
              : LyricRole.original,
        ),
      );
    }

    if (lines.isEmpty) {
      if (plainLines.isEmpty) {
        plainLines.addAll(
          document.rootElement.innerText
              .split('\n')
              .map(_cleanTtmlText)
              .where((line) => line.isNotEmpty),
        );
      }
      return LyricsDocument(
        plainLines: plainLines,
        syntax: LyricsSyntax.ttml,
        timing: LyricsTiming.none,
      );
    }

    return _timedDocument(lines, syntax: LyricsSyntax.ttml);
  } on Object {
    // XML 不完整时仍保留原文，避免一份坏歌词让歌曲无法播放。
    return _parsePlainText(source).copyWith(syntax: LyricsSyntax.ttml);
  }
}

LyricsDocument _timedDocument(
  List<LyricLine> input, {
  required LyricsSyntax syntax,
  Duration offset = Duration.zero,
  Map<String, String> metadata = const {},
  bool mergeSameTimestamp = true,
}) {
  // List.sort 不保证相同键的相对顺序，歌词翻译依赖“下行”语义，
  // 因此显式保留解析时的原始顺序。
  final indexed =
      [
        for (var index = 0; index < input.length; index++)
          _IndexedLyricLine(index: index, line: input[index]),
      ]..sort((a, b) {
        final byStart = a.line.start.compareTo(b.line.start);
        return byStart != 0 ? byStart : a.index.compareTo(b.index);
      });
  final sorted = [for (final entry in indexed) entry.line];
  // 先补齐可推导的结束时间，再合并翻译，确保“同结束时间”规则可用。
  final withInferredEnds = _inferLineEnds(sorted);
  final merged = mergeSameTimestamp
      ? _mergeTranslations(withInferredEnds)
      : withInferredEnds;
  final withEnds = _inferLineEnds(merged);
  final timing =
      withEnds.any(
        (line) =>
            line.isWordSynchronized ||
            line.translationWords.isNotEmpty ||
            line.variants.any((variant) => variant.words.isNotEmpty),
      )
      ? LyricsTiming.word
      : LyricsTiming.line;
  return LyricsDocument(
    lines: withEnds,
    offset: offset,
    syntax: syntax,
    timing: timing,
    metadata: metadata,
  );
}

List<LyricLine> _inferLineEnds(List<LyricLine> lines) {
  return [
    for (var index = 0; index < lines.length; index++)
      lines[index].end == null
          ? lines[index].copyWith(end: _inferredLyricEnd(lines, index))
          : lines[index],
  ];
}

Duration? _inferredLyricEnd(List<LyricLine> lines, int index) {
  final line = lines[index];
  final knownEnd = _latestKnownLyricEnd(line);
  if (knownEnd != null && knownEnd > line.start) return knownEnd;
  if (index + 1 < lines.length && lines[index + 1].start > line.start) {
    // 同起始时间的下行仍需保留到翻译合并阶段，不能提前把它们拆成不同区间。
    if (index > 0 && lines[index - 1].start == line.start) return null;
    return lines[index + 1].start;
  }
  return null;
}

Duration? _latestKnownLyricEnd(LyricLine line) {
  Duration? latest;

  void add(Duration? value) {
    if (value != null && (latest == null || value > latest!)) latest = value;
  }

  add(line.words.lastOrNull?.end);
  add(line.translationWords.lastOrNull?.end);
  for (final variant in line.variants) {
    add(variant.end);
    add(variant.words.lastOrNull?.end);
  }
  return latest;
}

/// 按歌词规范合并翻译：下行与上行的起始时间相同，或两行结束时间相同，
/// 就把下行视为上行翻译。第三行及之后仍保留为附加变体。
List<LyricLine> _mergeTranslations(List<LyricLine> lines) {
  final merged = <LyricLine>[];
  for (final line in lines) {
    if (merged.isEmpty) {
      merged.add(line);
      continue;
    }

    final preceding = merged.last;
    if (line.role == LyricRole.alternate &&
        _lyricIntervalsOverlap(preceding, line)) {
      merged.removeLast();
      merged.add(
        preceding.copyWith(
          start: preceding.start <= line.start ? preceding.start : line.start,
          end: _laterEnd(preceding.end, line.end),
          variants: [
            ...preceding.variants,
            LyricVariant(
              text: line.text,
              start: line.start,
              end: line.end,
              words: line.words,
              language: line.language,
              speaker: line.speaker,
              role: LyricRole.alternate,
            ),
          ],
        ),
      );
      continue;
    }

    if (line.role == LyricRole.original &&
        preceding.role == LyricRole.alternate &&
        _lyricIntervalsOverlap(preceding, line)) {
      merged.removeLast();
      merged.add(
        line.copyWith(
          start: line.start <= preceding.start ? line.start : preceding.start,
          end: _laterEnd(line.end, preceding.end),
          variants: [
            ...line.variants,
            LyricVariant(
              text: preceding.text,
              start: preceding.start,
              end: preceding.end,
              words: preceding.words,
              language: preceding.language,
              speaker: preceding.speaker,
              role: LyricRole.alternate,
            ),
          ],
        ),
      );
      continue;
    }

    if (merged.isEmpty || !_sameLyricTiming(merged.last, line)) {
      merged.add(line);
      continue;
    }

    final previous = merged.removeLast();
    if (line.role == LyricRole.alternate) {
      merged.add(
        previous.copyWith(
          start: previous.start <= line.start ? previous.start : line.start,
          end: _laterEnd(previous.end, line.end),
          variants: [
            ...previous.variants,
            LyricVariant(
              text: line.text,
              start: line.start,
              end: line.end,
              words: line.words,
              language: line.language,
              speaker: line.speaker,
              role: LyricRole.alternate,
            ),
          ],
        ),
      );
    } else if (line.role == LyricRole.translation ||
        previous.translation == null) {
      merged.add(
        previous.copyWith(
          end: _laterEnd(previous.end, line.end),
          translation: line.text,
          translationWords: line.words,
        ),
      );
    } else {
      merged.add(
        previous.copyWith(
          end: _laterEnd(previous.end, line.end),
          variants: [
            ...previous.variants,
            LyricVariant(
              text: line.text,
              start: line.start,
              end: line.end,
              words: line.words,
              language: line.language,
              speaker: line.speaker,
              role: LyricRole.alternate,
            ),
          ],
        ),
      );
    }
  }
  return merged;
}

bool _lyricIntervalsOverlap(LyricLine first, LyricLine second) {
  final firstEnd = first.end ?? first.start;
  final secondEnd = second.end ?? second.start;
  return first.start <= secondEnd && second.start <= firstEnd;
}

Duration? _laterEnd(Duration? first, Duration? second) {
  if (first == null) return second;
  if (second == null) return first;
  return first >= second ? first : second;
}

bool _sameLyricTiming(LyricLine first, LyricLine second) =>
    first.start == second.start ||
    (first.end != null && second.end != null && first.end == second.end);

Duration? _parseLrcTimestamp(String value) {
  final parts = value.trim().replaceAll(',', '.').split(':');
  if (parts.length == 2) {
    final minutes = int.tryParse(parts[0]);
    final seconds = double.tryParse(parts[1]);
    if (minutes != null && seconds != null && seconds < 60) {
      return Duration(
        minutes: minutes,
        microseconds: (seconds * Duration.microsecondsPerSecond).round(),
      );
    }
  }
  if (parts.length == 3) {
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    final seconds = double.tryParse(parts[2]);
    if (hours != null && minutes != null && seconds != null && seconds < 60) {
      return Duration(
        hours: hours,
        minutes: minutes,
        microseconds: (seconds * Duration.microsecondsPerSecond).round(),
      );
    }
  }
  return null;
}

/// 解析逐字标记中的相对毫秒时间。
_LrcTiming? _parseRelativeTiming(String value) {
  final numbers = RegExp(r'\d+').allMatches(value).toList();
  if (numbers.length < 2) return null;
  final start = int.tryParse(numbers[0].group(0)!);
  final duration = int.tryParse(numbers[1].group(0)!);
  if (start == null || duration == null) return null;
  return _LrcTiming(
    start: Duration(milliseconds: start),
    end: Duration(milliseconds: start + duration),
  );
}

({Duration value, bool relative})? _parseTtmlTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final text = value.trim().toLowerCase();
  final unitMatch = RegExp(r'^([+-]?\d+(?:\.\d+)?)(ms|s|m|h)$')
      .firstMatch(text);
  if (unitMatch != null) {
    final number = double.parse(unitMatch.group(1)!);
    const second = 1000000;
    final microseconds = switch (unitMatch.group(2)) {
      'ms' => (number * 1000).round(),
      's' => (number * second).round(),
      'm' => (number * 60 * second).round(),
      'h' => (number * 3600 * second).round(),
      _ => 0,
    };
    return (value: Duration(microseconds: microseconds), relative: true);
  }

  final parts = text.split(':');
  if (parts.length == 2) {
    final minutes = int.tryParse(parts[0]);
    final seconds = double.tryParse(parts[1]);
    if (minutes != null && seconds != null) {
      return (
        value: Duration(
          microseconds: ((minutes * 60 + seconds) * 1000000).round(),
        ),
        relative: false,
      );
    }
  }
  if (parts.length == 3) {
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    final seconds = double.tryParse(parts[2]);
    if (hours != null && minutes != null && seconds != null) {
      return (
        value: Duration(
          microseconds: ((hours * 3600 + minutes * 60 + seconds) * 1000000)
              .round(),
        ),
        relative: false,
      );
    }
  }
  return null;
}

Duration _resolveTtmlTime(
  ({Duration value, bool relative}) time,
  Duration? parentStart,
) {
  if (time.relative && parentStart != null) return parentStart + time.value;
  return time.value;
}

({String text, List<LyricWord> words, Duration? firstStart}) _parseLrcWords(
  String text, {
  String? speaker,
  Duration? initialStart,
}) {
  // Enhanced LRC 同时存在尖括号和方括号两种写法：
  // <00:01.00>word 以及 [00:01.00]word [00:01.30]next。后者的最后一个
  // 时间戳可能表示上一片段的结束时间，因此不能简单地把每个标签都当作起点。
  final matches = RegExp(
    r'(?:<|\[)\s*(\d{1,3}(?::\d{1,3}){1,2}(?:[.,]\d{1,3})?)\s*(?:>|\])',
  ).allMatches(text).toList();
  if (matches.isEmpty) {
    return (text: _plainText(text), words: const [], firstStart: initialStart);
  }

  final words = <LyricWord>[];
  final textBuffer = StringBuffer();
  var cursor = 0;
  Duration? activeStart;
  Duration? firstStart = initialStart;

  void appendSegment(String rawText, Duration? start, Duration? end) {
    // 逐字歌词常把单词间空格放在前一个片段末尾，不能逐片段 trim，
    // 否则会把英文歌词拼成无空格的连续字符串。
    final clean = _stripLyricMarkup(rawText).replaceAll(RegExp(r'[ \t]+'), ' ');
    if (clean.isEmpty) return;
    textBuffer.write(clean);
    // AMLL 会把纯空格作为独立的不可见词保留。这样类似
    // `<时间>你<时间> <时间>好` 的中文逐字歌词不会在相邻时间标签之间丢空格。
    if (start == null || clean.trim().isEmpty) return;
    firstStart ??= start;
    words.add(LyricWord(start: start, end: end, text: clean, speaker: speaker));
  }

  for (final match in matches) {
    final timing = _parseLrcTimestamp(match.group(1)!);
    if (timing == null) continue;
    final segmentText = text.substring(cursor, match.start);
    appendSegment(segmentText, activeStart ?? initialStart, timing);
    activeStart = timing;
    cursor = match.end;
  }
  appendSegment(text.substring(cursor), activeStart, null);

  // 当文本以时间标签结束时，该标签是上一片段的结束边界，而不是新词起点。
  if (words.isNotEmpty && cursor == text.length && activeStart != null) {
    final last = words.last;
    if (activeStart > last.start && last.end == null) {
      words[words.length - 1] = LyricWord(
        start: last.start,
        end: activeStart,
        text: last.text,
        speaker: last.speaker,
      );
    }
  }

  if (words.isEmpty) {
    return (text: _plainText(text), words: const [], firstStart: firstStart);
  }

  final withEnds = [
    for (var index = 0; index < words.length; index++)
      LyricWord(
        start: words[index].start,
        end:
            words[index].end ??
            (index + 1 < words.length ? words[index + 1].start : null),
        text: words[index].text,
        speaker: words[index].speaker,
      ),
  ];
  return (
    text: _plainText(textBuffer.toString()),
    words: withEnds,
    firstStart: firstStart,
  );
}

({String text, String? speaker}) _extractSpeaker(String text) {
  final bracket = RegExp(r'^\[([^\]]{1,24})\]\s*(.*)$').firstMatch(text);
  if (bracket != null && _parseLrcTimestamp(bracket.group(1)!) == null) {
    return (text: bracket.group(2)!, speaker: bracket.group(1));
  }
  // 说话者名称不能跨过歌词时间标签，否则 `[00:06.860]` 中的冒号会被
  // 误认为“说话者:歌词”的分隔符。
  final colon = RegExp(r'^([^\[\]<>:：]{1,16})[:：]\s*(.+)$').firstMatch(text);
  if (colon != null) {
    return (text: colon.group(2)!, speaker: colon.group(1)!.trim());
  }
  return (text: text, speaker: null);
}

String? _xmlAttribute(XmlElement element, String localName) {
  for (final attribute in element.attributes) {
    if (attribute.name.local.toLowerCase() == localName.toLowerCase()) {
      return attribute.value.trim();
    }
  }
  return null;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

bool _isTranslation({String? role, String? language, String? rootLanguage}) {
  final normalizedRole = role?.toLowerCase() ?? '';
  if (normalizedRole.contains('translation') ||
      normalizedRole.contains('translate')) {
    return true;
  }
  return language != null &&
      rootLanguage != null &&
      language.toLowerCase() != rootLanguage.toLowerCase();
}

bool _isBackgroundRole(String? role) {
  final normalized = role?.toLowerCase().trim() ?? '';
  return normalized.contains('background') ||
      normalized == 'bg' ||
      normalized.contains('backing') ||
      normalized.contains('alternate') ||
      normalized.contains('duet');
}

String _cleanTtmlText(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

String _stripLyricMarkup(String value) => value
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll(RegExp(r'\{[^}]*\}'), '');

String _cleanLyricText(String value) =>
    value.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

String _plainText(String text) => text
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll(RegExp(r'\{[^}]*\}'), '')
    .trim();

class _BracketTag {
  const _BracketTag(this.value, this.start, this.end);

  final String value;
  final int start;
  final int end;
}

class _IndexedLyricLine {
  const _IndexedLyricLine({required this.index, required this.line});

  final int index;
  final LyricLine line;
}

class _LrcTiming {
  const _LrcTiming({required this.start, this.end});

  final Duration start;
  final Duration? end;
}

List<LyricWord> _completeWordEnds(List<LyricWord> words) {
  return [
    for (var index = 0; index < words.length; index++)
      LyricWord(
        start: words[index].start,
        end:
            words[index].end ??
            (index + 1 < words.length ? words[index + 1].start : null),
        text: words[index].text,
        speaker: words[index].speaker,
      ),
  ];
}
