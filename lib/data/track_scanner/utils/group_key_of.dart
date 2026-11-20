import 'package:diacritic/diacritic.dart';
import 'package:lpinyin/lpinyin.dart';

import 'package:linglun/data/models/track_info.dart';

// 分组与排序键的计算规则：
// - 拉丁（去音标）与汉字（拼音）共用 A-Z，组内按拉丁化字符串排序
// - 假名按五十音行分组，组内按平假名码点排序（码点顺序基本就是五十音顺序）
// - 韩文按初声分组（双辅音并入单辅音），组内按音节码点排序（本身就是 가나다 顺序）
// - 西里尔按首字母分组（Ё 并入 Е，Й 并入 И）
// - 数字、符号、其他文字归 '#'
// - 开头的空白和符号会被跳过，用第一个字母或数字判断

// ====== 文字识别 ======

enum Script { latin, han, kana, hangul, cyrillic, other }

Script scriptOf(int c) {
  if ((c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      (c >= 0xC0 && c <= 0x24F && c != 0xD7 && c != 0xF7) ||
      (c >= 0x1E00 && c <= 0x1EFF)) {
    return Script.latin;
  }
  if ((c >= 0x4E00 && c <= 0x9FFF) ||
      (c >= 0x3400 && c <= 0x4DBF) ||
      (c >= 0xF900 && c <= 0xFAFF) ||
      (c >= 0x20000 && c <= 0x2FA1F)) {
    return Script.han;
  }
  if ((c >= 0x3041 && c <= 0x30FF) || (c >= 0x31F0 && c <= 0x31FF)) {
    return Script.kana;
  }
  if ((c >= 0xAC00 && c <= 0xD7A3) ||
      (c >= 0x1100 && c <= 0x11FF) ||
      (c >= 0x3130 && c <= 0x318F)) {
    return Script.hangul;
  }
  if (c >= 0x400 && c <= 0x4FF) return Script.cyrillic;
  return Script.other;
}

// ====== 预处理 ======

final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);
final _asciiLetter = RegExp(r'[a-z]');
final _spaces = RegExp(r'\s+');

// 半角片假名（U+FF66 起，共 58 个）对应的全角字符
const _halfKana = 'ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜';

/// 全角 ASCII → 半角，半角片假名 → 全角，片假名 → 平假名
String _fold(String s) {
  final b = StringBuffer();
  for (var c in s.runes) {
    if (c == 0x3000) {
      c = 0x20;
    } else if (c >= 0xFF66 && c <= 0xFF9F) {
      c = _halfKana.codeUnitAt(c - 0xFF66);
    } else if (c >= 0xFF01 && c <= 0xFF5E) {
      c -= 0xFEE0;
    }
    if (c >= 0x30A1 && c <= 0x30F6) c -= 0x60;
    b.writeCharCode(c);
  }
  return b.toString();
}

/// 去掉开头的空白和符号，直到第一个字母或数字
String _stripLeading(String s) {
  final runes = s.runes.toList();
  var i = 0;
  while (i < runes.length &&
      !_letterOrDigit.hasMatch(String.fromCharCode(runes[i]))) {
    i++;
  }
  return String.fromCharCodes(runes.sublist(i));
}

/// 把连续的汉字整段转成拼音（整段转换才能识别词组里的多音字），其余字符原样保留
String _toLatin(String s) {
  final out = StringBuffer();
  final run = StringBuffer();

  void flush() {
    if (run.isEmpty) return;
    out
      ..write(' ')
      ..write(
        PinyinHelper.getPinyinE(
          run.toString(),
          separator: ' ',
          defPinyin: '#',
          format: PinyinFormat.WITHOUT_TONE,
        ),
      )
      ..write(' ');
    run.clear();
  }

  for (final c in s.runes) {
    if (scriptOf(c) == Script.han) {
      run.writeCharCode(c);
    } else {
      flush();
      out.writeCharCode(c);
    }
  }
  flush();
  return out.toString();
}

// ====== 假名与韩文的分组表 ======

const _kanaRows = {
  'あ': 'ぁあぃいぅうぇえぉおゔ',
  'か': 'かがきぎくぐけげこごゕゖ',
  'さ': 'さざしじすずせぜそぞ',
  'た': 'ただちぢっつづてでとど',
  'な': 'なにぬねの',
  'は': 'はばぱひびぴふぶぷへべぺほぼぽ',
  'ま': 'まみむめも',
  'や': 'ゃやゅゆょよ',
  'ら': 'らりるれろ',
  'わ': 'ゎわゐゑをん',
};

final Map<int, String> _kanaRowOf = {
  for (final e in _kanaRows.entries)
    for (final c in e.value.runes) c: e.key,
};

// 19 个初声依次对应的分组，双辅音（ㄲㄸㅃㅆㅉ）并入单辅音
const _hangulInitials = 'ㄱㄱㄴㄷㄷㄹㅁㅂㅂㅅㅅㅇㅈㅈㅊㅋㅌㅍㅎ';

// ====== 对外接口 ======

/// 计算一个名字的分组键与组内排序键，扫描时调用
TextKey keyOf(String text) {
  final s = _stripLeading(_fold(text.trim()));
  if (s.isEmpty) return const TextKey(group: '#', sort: '');

  final first = s.runes.first;
  final tidy = s.replaceAll(_spaces, ' ');

  switch (scriptOf(first)) {
    case Script.latin:
    case Script.han:
      final sort = removeDiacritics(_toLatin(s))
          .toLowerCase()
          .replaceAll(_spaces, ' ')
          .trim();
      final head = sort.isEmpty ? '' : sort[0];
      return TextKey(
        group: _asciiLetter.hasMatch(head) ? head.toUpperCase() : '#',
        sort: sort,
      );

    case Script.kana:
      return TextKey(group: _kanaRowOf[first] ?? '#', sort: tidy);

    case Script.hangul:
      final code = first - 0xAC00;
      final head = (code >= 0 && first <= 0xD7A3)
          ? _hangulInitials[code ~/ 588]
          : '#';
      return TextKey(group: head, sort: tidy);

    case Script.cyrillic:
      var head = String.fromCharCode(first).toUpperCase();
      if (head == 'Ё') head = 'Е';
      if (head == 'Й') head = 'И';
      return TextKey(
        group: head,
        sort: tidy.toLowerCase().replaceAll('ё', 'е'),
      );

    case Script.other:
      return TextKey(group: '#', sort: tidy.toLowerCase());
  }
}

/// 名字缺失（如未知歌手、未知专辑）时使用：归 '#'，并排在 '#' 组末尾
TextKey keyOfNullable(String? text) {
  if (text == null || text.isEmpty) {
    return const TextKey(group: '#', sort: '\uffff');
  }
  return keyOf(text);
}

/// 分组的先后顺序：A-Z、假名、韩文、西里尔、'#'；同类内按码点
/// （假名行首、韩文初声、西里尔大写字母的码点顺序恰好就是各自的惯例顺序）
int groupRank(String group) {
  final c = group.runes.first;
  final bucket = switch (scriptOf(c)) {
    Script.latin => 0,
    Script.kana => 1,
    Script.hangul => 2,
    Script.cyrillic => 3,
    Script.han => 4,
    Script.other => 9,
  };
  return bucket * 0x200000 + c;
}

/// 先比分组，再比组内排序键
int compareKeys(TextKey a, TextKey b) {
  final r = groupRank(a.group).compareTo(groupRank(b.group));
  return r != 0 ? r : a.sort.compareTo(b.sort);
}
