import 'package:flutter/material.dart';

/// 使用较淡的斜杠分隔多个艺术家，避免把分隔符误认为艺术家名称的一部分。
class ArtistLabel extends StatelessWidget {
  const ArtistLabel({
    required this.artists,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textAlign = TextAlign.start,
    this.suffix,
    super.key,
  });

  final List<String> artists;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        children: [
          ...artistTextSpans(
            artists,
            style: textStyle,
            separatorColor: Colors.white54,
            separatorWeight: FontWeight(300),
          ),
          if (suffix != null) TextSpan(text: suffix, style: textStyle),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

List<InlineSpan> artistTextSpans(
  Iterable<String> artists, {
  required TextStyle style,
  required Color separatorColor,
  required FontWeight separatorWeight,
}) {
  final names = artists.map((artist) => artist.trim()).where((artist) {
    return artist.isNotEmpty;
  }).toList();
  if (names.isEmpty) names.add('未知艺术家');

  return [
    for (var index = 0; index < names.length; index++) ...[
      if (index > 0)
        TextSpan(
          text: ' / ',
          style: style.copyWith(
            color: separatorColor,
            fontWeight: separatorWeight,
          ),
        ),
      TextSpan(text: names[index], style: style),
    ],
  ];
}
