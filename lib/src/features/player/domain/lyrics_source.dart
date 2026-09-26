import 'lyrics.dart';

/// 歌词来源类型。
enum LyricsSourceKind { sidecar, embedded }

/// 一份未解析的歌词来源，保留其原始标签和文件信息，供选择器及详情页使用。
class LyricsSource {
  const LyricsSource({
    required this.content,
    required this.kind,
    this.extension,
    this.tagName,
    this.language,
    this.role = LyricRole.original,
  });

  final String content;
  final LyricsSourceKind kind;
  final String? extension;
  final String? tagName;
  final String? language;
  final LyricRole role;

  String get label {
    final suffix = [
      if (language != null && language!.isNotEmpty) language!,
      if (role == LyricRole.translation) '翻译',
      if (role == LyricRole.alternate) '变体',
    ].join('，');
    if (kind == LyricsSourceKind.sidecar) {
      return '外挂 ${extension ?? '歌词'}${suffix.isEmpty ? '' : '（$suffix）'}';
    }
    return '内嵌 ${tagName ?? '歌词'}${suffix.isEmpty ? '' : '（$suffix）'}';
  }

  Map<String, Object?> toJson() => {
    'content': content,
    'kind': kind.name,
    'extension': extension,
    'tagName': tagName,
    'language': language,
    'role': role.name,
  };

  factory LyricsSource.fromJson(Map<String, Object?> json) {
    final kind = LyricsSourceKind.values.firstWhere(
      (item) => item.name == json['kind'],
      orElse: () => LyricsSourceKind.embedded,
    );
    final role = LyricRole.values.firstWhere(
      (item) => item.name == json['role'],
      orElse: () => LyricRole.original,
    );
    return LyricsSource(
      content: json['content']?.toString() ?? '',
      kind: kind,
      extension: json['extension']?.toString(),
      tagName: json['tagName']?.toString(),
      language: json['language']?.toString(),
      role: role,
    );
  }
}

/// 按“可同步优先、外挂优先、结构化标签优先”的规则选择活动歌词。
LyricsSource? selectLyricsSource(Iterable<LyricsSource> sources) {
  final candidates = sources
      .where((source) => source.content.trim().isNotEmpty)
      .toList(growable: false);
  if (candidates.isEmpty) return null;
  final hasOriginal = candidates.any(
    (source) => source.role == LyricRole.original,
  );
  final hasAlternate = candidates.any(
    (source) => source.role == LyricRole.alternate,
  );
  final primaryCandidates = hasOriginal
      ? candidates.where((source) => source.role == LyricRole.original)
      : hasAlternate
      ? candidates.where((source) => source.role == LyricRole.alternate)
      : candidates;
  return primaryCandidates.reduce((first, second) {
    final firstScore = _lyricsSourceScore(first);
    final secondScore = _lyricsSourceScore(second);
    return secondScore > firstScore ? second : first;
  });
}

int _lyricsSourceScore(LyricsSource source) {
  var score = source.kind == LyricsSourceKind.sidecar ? 100 : 0;
  final tag = source.tagName?.toUpperCase() ?? '';
  if (tag.contains('SYNC') || tag.contains('SYLT')) score += 60;
  if (tag.contains('LRC') || tag.contains('TTML') || tag.contains('YRC')) {
    score += 40;
  }
  if (tag.contains('UNSYNC') || tag.contains('USLT')) score -= 20;
  if (source.role == LyricRole.translation) score -= 80;
  if (source.role == LyricRole.alternate) score -= 20;
  return score;
}

/// 将选中的主歌词和独立保存的翻译歌词合成为一个渲染文档。
///
/// 同一份歌词中的翻译由 [parseLyricsFile] 按时间戳规则处理；这里主要
/// 处理播放器元数据中把原文和译文拆成两个字段的情况。
LyricsDocument parseLyricsSources(Iterable<LyricsSource> sources) {
  final available = sources
      .where((source) => source.content.trim().isNotEmpty)
      .toList(growable: false);
  final primary = selectLyricsSource(available);
  if (primary == null) return const LyricsDocument();

  var document = parseLyricsFile(primary.content, extension: primary.extension);
  for (final source in available) {
    if (identical(source, primary) || source.role != LyricRole.translation) {
      continue;
    }
    document = _mergeExternalTranslation(
      document,
      parseLyricsFile(source.content, extension: source.extension),
    );
  }
  return document;
}

LyricsDocument _mergeExternalTranslation(
  LyricsDocument original,
  LyricsDocument translation,
) {
  if (original.lines.isNotEmpty && translation.lines.isNotEmpty) {
    final translatedLines = translation.lines;
    final usedTranslationIndices = <int>{};
    final lines = <LyricLine>[];
    for (final line in original.lines) {
      if (line.translation != null) {
        final matchIndex = _translationIndexFor(
          translatedLines,
          usedIndices: usedTranslationIndices,
          start: line.start,
          end: line.end,
        );
        if (matchIndex == null) {
          lines.add(line);
          continue;
        }
        usedTranslationIndices.add(matchIndex);
        final translationLine = translatedLines[matchIndex];
        lines.add(
          line.copyWith(
            variants: [
              ...line.variants,
              LyricVariant(
                text: translationLine.text,
                start: translationLine.start,
                end: translationLine.end,
                words: translationLine.words,
                language: translationLine.language,
                speaker: translationLine.speaker,
                role: LyricRole.translation,
              ),
            ],
          ),
        );
        continue;
      }
      final matchIndex = _translationIndexFor(
        translatedLines,
        usedIndices: usedTranslationIndices,
        start: line.start,
        end: line.end,
      );
      if (matchIndex == null) {
        lines.add(line);
        continue;
      }
      usedTranslationIndices.add(matchIndex);
      final match = translatedLines[matchIndex];
      lines.add(
        line.copyWith(translation: match.text, translationWords: match.words),
      );
    }
    return LyricsDocument(
      lines: lines,
      offset: original.offset,
      syntax: original.syntax,
      timing:
          lines.any(
            (line) =>
                line.isWordSynchronized ||
                line.translationWords.isNotEmpty ||
                line.variants.any((variant) => variant.words.isNotEmpty),
          )
          ? LyricsTiming.word
          : LyricsTiming.line,
      metadata: original.metadata,
    );
  }

  if (original.lines.isNotEmpty && translation.plainLines.isNotEmpty) {
    final lines = [
      for (var index = 0; index < original.lines.length; index++)
        index < translation.plainLines.length &&
                original.lines[index].translation == null
            ? original.lines[index].copyWith(
                translation: translation.plainLines[index],
              )
            : original.lines[index],
    ];
    return LyricsDocument(
      lines: lines,
      offset: original.offset,
      syntax: original.syntax,
      timing: original.timing,
      metadata: original.metadata,
    );
  }

  if (original.plainLines.isNotEmpty) {
    final translatedLines = translation.lines.isNotEmpty
        ? translation.lines.map((line) => line.text).toList(growable: false)
        : translation.plainLines;
    final merged = <String>[];
    for (var index = 0; index < original.plainLines.length; index++) {
      merged.add(original.plainLines[index]);
      if (index < translatedLines.length) {
        merged.add(translatedLines[index]);
      }
    }
    return LyricsDocument(
      plainLines: merged,
      offset: original.offset,
      syntax: original.syntax,
      timing: LyricsTiming.none,
      metadata: original.metadata,
    );
  }
  return original;
}

int? _translationIndexFor(
  List<LyricLine> lines, {
  required Set<int> usedIndices,
  required Duration start,
  required Duration? end,
}) {
  if (end != null) {
    for (var index = 0; index < lines.length; index++) {
      if (!usedIndices.contains(index) &&
          lines[index].start == start &&
          lines[index].end == end) {
        return index;
      }
    }
  }
  for (var index = 0; index < lines.length; index++) {
    if (!usedIndices.contains(index) && lines[index].start == start) {
      return index;
    }
  }
  if (end != null) {
    for (var index = 0; index < lines.length; index++) {
      if (!usedIndices.contains(index) && lines[index].end == end) {
        return index;
      }
    }
  }
  return null;
}
