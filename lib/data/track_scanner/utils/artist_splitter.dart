/// 名字带分隔符的艺术家
/// 匹配时忽略大小写和名字内部的空白
const List<String> _protectedArtistNames = [
  // 含 & 的
  'Simon & Garfunkel',
  'Hall & Oates',
  'Sonny & Cher',
  'Brooks & Dunn',
  'Mumford & Sons',
  'Belle & Sebastian',
  'Iron & Wine',
  'Years & Years',
  'Chase & Status',
  'Eric B. & Rakim',
  'Ike & Tina Turner',
  'Kool & The Gang',
  'KC & The Sunshine Band',
  'Echo & The Bunnymen',
  'Hootie & The Blowfish',
  'Siouxsie & The Banshees',
  'Katrina & The Waves',
  'Huey Lewis & The News',
  'Bob Marley & The Wailers',
  'Sly & The Family Stone',
  'Nick Cave & The Bad Seeds',
  'Earth, Wind & Fire',
  'Crosby, Stills, Nash & Young',
  'Crosby, Stills & Nash',
  'Emerson, Lake & Palmer',
  'Blood, Sweat & Tears',
  // 含 / 的
  'AC/DC',
  'Leo/need',
  // 含 、 的
  'ハロー、ハッピーワールド！',
  // 含 ， 的
  'Tyler, The Creator',
  'Peter, Paul and Mary',
];

class ArtistSplitter {
  new({
    required List<String> protectedNames,
    List<String> separators = const ['、', ';', '/', '&', '；'],
  }) : _separatorPattern = RegExp(separators.map(RegExp.escape).join('|')),
       _protectedPattern = _buildProtectedPattern(protectedNames),
       _canonicalByKey = {
         for (final name in protectedNames) _toKey(name): name.trim(),
       };

  final RegExp _separatorPattern;
  final RegExp? _protectedPattern; // 保护表为空时为 null
  final Map<String, String> _canonicalByKey; // 归一化后的 key -> 规范名称

  static final RegExp _whitespacePattern = RegExp(r'\s+');

  /// 去掉所有空白并转小写（'ac / dc'）
  static String _toKey(String text) =>
      text.replaceAll(_whitespacePattern, '').toLowerCase();

  static RegExp? _buildProtectedPattern(List<String> names) {
    // 必须提前返回，否则空的交替会在每个位置匹配空串
    if (names.isEmpty) return null;
    // 最长匹配优先
    final sorted = [...names]..sort((a, b) => b.length.compareTo(a.length));
    final alternatives = sorted.map(
      // 名字内部空白放宽（'Simon&Garfunkel'）
      (name) =>
          RegExp.escape(name.trim()).replaceAll(_whitespacePattern, r'\s*'),
    );
    return RegExp(
      // 前后不能紧挨内容（'Marshall & Oates', 'Hall & Oates'）
      r'(?<![\p{L}\p{N}])(?:' + alternatives.join('|') + r')(?![\p{L}\p{N}])',
      caseSensitive: false,
      unicode: true,
    );
  }

  List<String> split(String raw) {
    // 没有分隔符就不跑正则
    if (!_separatorPattern.hasMatch(raw)) {
      final single = raw.trim();
      return single.isEmpty ? <String>[] : [single];
    }

    final result = <String>[];
    var cursor = 0;
    final protectedPattern = _protectedPattern;
    if (protectedPattern != null) {
      for (final match in protectedPattern.allMatches(raw)) {
        _addSplitParts(raw.substring(cursor, match.start), result);
        final matched = match.group(0)!;
        result.add(_canonicalByKey[_toKey(matched)] ?? matched.trim());
        cursor = match.end;
      }
    }
    _addSplitParts(raw.substring(cursor), result);
    return result;
  }

  void _addSplitParts(String segment, List<String> out) {
    for (final part in segment.split(_separatorPattern)) {
      final name = part.trim();
      if (name.isNotEmpty) out.add(name); // 过滤多余分隔符产生的空串
    }
  }
}

/// 全局单例
final ArtistSplitter artistSplitter = ArtistSplitter(
  protectedNames: _protectedArtistNames,
);

List<String> splitArtists(String raw) => artistSplitter.split(raw);
