/// 歌词中的一个逐字时间片段。
class LyricWord {
  const LyricWord({required this.start, required this.text});

  final Duration start;
  final String text;
}

/// 一行歌词，可同时包含整行时间和逐字时间。
class LyricLine {
  const LyricLine({
    required this.start,
    required this.text,
    this.words = const [],
    this.translation,
  });

  final Duration start;
  final String text;
  final List<LyricWord> words;
  final String? translation;

  bool get isWordSynchronized => words.isNotEmpty;
}

class LyricsDocument {
  const LyricsDocument({required this.lines, this.offset = Duration.zero});

  final List<LyricLine> lines;
  final Duration offset;
}

/// 解析普通 LRC 和 Enhanced LRC 的行级、逐字时间标签。
LyricsDocument parseLyrics(String source) {
  final lines = <LyricLine>[];
  var offset = Duration.zero;

  for (final rawLine in source.replaceAll('\r\n', '\n').split('\n')) {
    final line = rawLine.trimRight();
    if (line.isEmpty) continue;

    final offsetMatch = RegExp(
      r'^\[offset:([+-]?\d+)\]',
      caseSensitive: false,
    ).firstMatch(line);
    if (offsetMatch != null) {
      offset = Duration(milliseconds: int.parse(offsetMatch.group(1)!));
      continue;
    }

    final lineTimes = <Duration>[];
    for (final match in RegExp(
      r'\[(\d+):(\d{1,2})(?:[.:](\d{1,3}))?\]',
    ).allMatches(line)) {
      lineTimes.add(
        _parseTimestamp(match.group(1)!, match.group(2)!, match.group(3)),
      );
    }
    if (lineTimes.isEmpty) continue;

    final textStart = line.lastIndexOf(']') + 1;
    final text = line.substring(textStart).trim();
    final words = _parseWords(text);
    for (final time in lineTimes) {
      lines.add(LyricLine(start: time, text: _plainText(text), words: words));
    }
  }

  lines.sort((a, b) => a.start.compareTo(b.start));
  return LyricsDocument(lines: _mergeTranslations(lines), offset: offset);
}

/// 根据文件扩展名解析常见歌词格式；未知格式仍尝试按 LRC 处理。
LyricsDocument parseLyricsFile(String source, {String? extension}) {
  switch (extension?.toLowerCase()) {
    case '.srt':
      return _parseSubtitleBlocks(source, _srtTimestamp);
    case '.vtt':
      return _parseSubtitleBlocks(source, _vttTimestamp);
    case '.ass':
    case '.ssa':
      return _parseAss(source);
    default:
      return parseLyrics(source);
  }
}

LyricsDocument _parseSubtitleBlocks(
  String source,
  Duration? Function(String) timestampParser,
) {
  final lines = <LyricLine>[];
  final blocks = source.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));
  for (final block in blocks) {
    final rows = block.split('\n').map((line) => line.trim()).toList();
    final timingIndex = rows.indexWhere((row) => row.contains('-->'));
    if (timingIndex == -1 || timingIndex + 1 >= rows.length) continue;
    final timing = rows[timingIndex].split('-->');
    final start = timestampParser(timing.first.trim());
    if (start == null) continue;
    final text = rows.sublist(timingIndex + 1).join('\n').trim();
    if (text.isNotEmpty) lines.add(LyricLine(start: start, text: text));
  }
  return LyricsDocument(lines: _mergeTranslations(lines));
}

Duration? _srtTimestamp(String value) {
  final match = RegExp(r'^(\d+):(\d{2}):(\d{2}),(\d{3})').firstMatch(value);
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
  for (final row in source.split('\n')) {
    if (!row.startsWith('Dialogue:')) continue;
    final fields = row.substring('Dialogue:'.length).split(',');
    if (fields.length < 10) continue;
    final start = _assTimestamp(fields[1].trim());
    if (start == null) continue;
    final text = fields
        .sublist(9)
        .join(',')
        .replaceAll(RegExp(r'\{[^}]*\}'), '');
    lines.add(LyricLine(start: start, text: text.replaceAll(r'\N', '\n')));
  }
  return LyricsDocument(lines: _mergeTranslations(lines));
}

/// 常见双语歌词会使用相同时间戳连续存放原文和译文，这里将其合并为一行。
List<LyricLine> _mergeTranslations(List<LyricLine> lines) {
  final merged = <LyricLine>[];
  for (final line in lines) {
    if (merged.isNotEmpty &&
        merged.last.start == line.start &&
        merged.last.translation == null &&
        line.text != merged.last.text) {
      final previous = merged.removeLast();
      merged.add(
        LyricLine(
          start: previous.start,
          text: previous.text,
          words: previous.words,
          translation: line.text,
        ),
      );
    } else {
      merged.add(line);
    }
  }
  return merged;
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

Duration _parseTimestamp(String minutes, String seconds, String? fraction) {
  final secondValue = int.parse(seconds);
  final fractionText = fraction ?? '';
  final milliseconds = switch (fractionText.length) {
    0 => 0,
    1 => int.parse(fractionText) * 100,
    2 => int.parse(fractionText) * 10,
    _ => int.parse(fractionText.substring(0, 3)),
  };
  return Duration(
    minutes: int.parse(minutes),
    seconds: secondValue,
    milliseconds: milliseconds,
  );
}

List<LyricWord> _parseWords(String text) {
  final matches = RegExp(r'<(\d+):(\d{1,2})(?:[.:](\d{1,3}))?>')
      .allMatches(text);
  if (matches.isEmpty) return const [];

  final words = <LyricWord>[];
  for (var index = 0; index < matches.length; index++) {
    final match = matches.elementAt(index);
    final end = index + 1 < matches.length
        ? matches.elementAt(index + 1).start
        : text.length;
    final wordText = text.substring(match.end, end);
    words.add(
      LyricWord(
        start: _parseTimestamp(
          match.group(1)!,
          match.group(2)!,
          match.group(3),
        ),
        text: wordText,
      ),
    );
  }
  return words;
}

String _plainText(String text) =>
    text.replaceAll(RegExp(r'<\d+:\d{1,2}(?:[.:]\d{1,3})?>'), '');
