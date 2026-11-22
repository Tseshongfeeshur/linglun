import 'package:diacritic/diacritic.dart';
import 'package:pinyin/pinyin.dart';

import 'package:linglun/data/models/track_info.dart';

// 分组与排序键的计算规则：
// - 拉丁（去音标）与汉字（拼音）共用 A-Z，组内按拉丁化字符串排序
// - 假名按五十音行分组，组内按平假名码点排序（码点顺序基本就是五十音顺序）
// - 韩文按初声分组（双辅音并入单辅音），组内按音节码点排序（本身就是 가나다 顺序）
// - 西里尔按首字母分组（Ё 并入 Е，Й 并入 И）
// - 数字、符号、其他文字归 '#'
// - 开头的空白和符号会被跳过，用第一个字母或数字判断

// ====== 文字识别 ======

/// 用于分组的文字系统分类，不是完整的 Unicode Script 判定。
enum Script { latin, han, kana, hangul, cyrillic, other }

/// 按码点判断文字系统。拉丁包含带音标的扩展区（排除 × ÷）；
/// 汉字包含日语汉字；假名包含片假名扩展；韩文包含字母（Jamo）区。
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
// 末尾的 ゛ ゜ 只是兜底：半角浊点、半角半浊点正常情况下会在 _fold 里
// 与前一个假名合并，只有前面没有可合并的假名时才会保留成独立符号。
const _halfKana = 'ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜';

// 能加浊点的平假名（码点 +1 即为浊音），以及能加半浊点的（码点 +2 即为半浊音）
final Set<int> _voicedBase = 'かきくけこさしすせそたちつてとはひふへほ'.runes.toSet();
final Set<int> _semiVoicedBase = 'はひふへほ'.runes.toSet();

/// 把浊点/半浊点合并进前一个平假名；前一个字符不能合并时返回 null
int? _combineKana(int base, {required bool semi}) {
  if (semi) return _semiVoicedBase.contains(base) ? base + 2 : null;
  if (base == 0x3046) return 0x3094; // う → ゔ
  return _voicedBase.contains(base) ? base + 1 : null;
}

/// 统一字符形态：
/// - 全角空格 → 空格，全角 ASCII → 半角
/// - 半角片假名 → 全角，片假名 → 平假名
/// - 浊点/半浊点（半角 ﾞ ﾟ，或 macOS 文件名常见的组合记号 U+3099 U+309A）与前一个假名合并
/// - 分解形式的韩文（Jamo 序列，NFD）重新组合成预组合音节
String _fold(String s) {
  final out = <int>[];
  for (var c in s.runes) {
    // 1. 浊点、半浊点：合并进前一个字符（此时前一个字符已经是平假名）
    if (c == 0xFF9E || c == 0x3099 || c == 0xFF9F || c == 0x309A) {
      if (out.isNotEmpty) {
        final merged = _combineKana(out.last, semi: c == 0xFF9F || c == 0x309A);
        if (merged != null) {
          out.last = merged;
          continue;
        }
      }
    }

    // 2. 半角/全角统一，再把片假名转成平假名
    if (c == 0x3000) {
      c = 0x20;
    } else if (c >= 0xFF66 && c <= 0xFF9F) {
      c = _halfKana.codeUnitAt(c - 0xFF66);
    } else if (c >= 0xFF01 && c <= 0xFF5E) {
      c -= 0xFEE0;
    }
    if (c >= 0x30A1 && c <= 0x30F6) c -= 0x60;

    // 3. 韩文 Jamo 组合：初声(1100–1112)+中声(1161–1175) → 音节，
    //    再遇到终声(11A8–11C2) 且该音节还没有终声 → 补上终声
    if (out.isNotEmpty) {
      final last = out.last;
      if (c >= 0x1161 && c <= 0x1175 && last >= 0x1100 && last <= 0x1112) {
        out.last = 0xAC00 + ((last - 0x1100) * 21 + (c - 0x1161)) * 28;
        continue;
      }
      if (c >= 0x11A8 &&
          c <= 0x11C2 &&
          last >= 0xAC00 &&
          last <= 0xD7A3 &&
          (last - 0xAC00) % 28 == 0) {
        out.last = last + (c - 0x11A7);
        continue;
      }
    }

    out.add(c);
  }
  return String.fromCharCodes(out);
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
  // 汉字段转成拼音后前后各补一个空格，使汉字与相邻的拉丁/数字分词，
  // 拼音音节之间也用空格分隔：这样排序按"音节"而不是按字母
  // （西安 "xi an" 会排在 先 "xian" 之前，与字典顺序一致）。
  // defPinyin: '#' —— 没有拼音的生僻字会变成 '#'，若出现在开头则整条归 '#' 组。
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

// 小写假名并入各自的行（ぁ→あ行，っ→た行，ゃ→や行，ゎ→わ行），ゔ 归あ行，
// ん 归わ行。长音符 ー 和叠字符号 ゝ ゞ 不在表里，作首字符时归 '#'。
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
// 初声下标 = (音节码点 - 0xAC00) ~/ 588，其中 588 = 21 个中声 × 28 个终声（含无终声）。
const _hangulInitials = 'ㄱㄱㄴㄷㄷㄹㅁㅂㅂㅅㅅㅇㅈㅈㅊㅋㅌㅍㅎ';

// 兼容字母（U+3131–U+314E，共 30 个辅音，如单独输入的 "ㄱ"）对应的分组：
// 双辅音和辅音丛并入首个辅音（ㄳ→ㄱ，ㄵㄶ→ㄴ，ㄺ…ㅀ→ㄹ，ㅄ→ㅂ）。
const _hangulCompatGroups = 'ㄱㄱㄱㄴㄴㄴㄷㄷㄹㄹㄹㄹㄹㄹㄹㄹㅁㅂㅂㅂㅅㅅㅇㅈㅈㅊㅋㅌㅍㅎ';

/// 韩文首字符对应的分组：预组合音节取初声，单独的初声 Jamo、兼容字母直接映射，
/// 其余（如单独的元音）归 '#'。分解形式（NFD）的音节已在 _fold 里重新组合。
String _hangulGroup(int c) {
  if (c >= 0xAC00 && c <= 0xD7A3) return _hangulInitials[(c - 0xAC00) ~/ 588];
  if (c >= 0x1100 && c <= 0x1112) return _hangulInitials[c - 0x1100];
  if (c >= 0x3131 && c <= 0x314E) return _hangulCompatGroups[c - 0x3131];
  return '#';
}

// 西里尔字母的分组顺序：以俄语为主，并按各语言惯例把乌克兰语（Ґ Є І Ї）、
// 塞尔维亚语（Ђ Ј Љ Њ Ћ Џ）的字母插到相应位置；Ё 并入 Е、Й 并入 И，所以不在表里。
// 表外的西里尔字母排在表内字母之后，按码点排。
const _cyrillicOrder = 'АБВГҐДЂЕЄЖЗИІЇЈКЛЉМНЊОПРСТЋУФХЦЧЏШЩЪЫЬЭЮЯ';

// ====== 对外接口 ======

/// 计算一个名字的分组键与组内排序键，扫描时调用
TextKey keyOf(String text) {
  final s = _stripLeading(_fold(text.trim()));
  if (s.isEmpty) return const TextKey(group: '#', sort: '');

  final first = s.runes.first;
  final tidy = s.replaceAll(_spaces, ' ');

  // 只看第一个字符（跳过开头符号后）的文字系统来决定走哪套规则。
  switch (scriptOf(first)) {
    case Script.latin:
    case Script.han:
      // 汉字先转拼音，拉丁去掉音标；两者共用 A-Z。sort 已统一小写、压缩空白。
      // 去音标后首字符仍不是 a-z 的（个别未被映射的拉丁字母）归 '#'，
      // 此时 group 是 '#' 而 sort 以该字母开头，会排在 '#' 组内字母顺序里。
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
      return TextKey(group: _hangulGroup(first), sort: tidy);

    case Script.cyrillic:
      var head = String.fromCharCode(first).toUpperCase();
      if (head == 'Ё') head = 'Е';
      if (head == 'Й') head = 'И';
      // sort 里同样把 ё→е、й→и，使组内顺序与分组规则一致（й 开头的和 и 开头的混排）
      return TextKey(
        group: head,
        sort: tidy.toLowerCase().replaceAll('ё', 'е').replaceAll('й', 'и'),
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

/// 分组的先后顺序：A-Z、假名、韩文、西里尔、'#'；同类内：
/// 拉丁、假名行首、韩文初声的码点顺序恰好就是各自的惯例顺序，直接按码点；
/// 西里尔按 _cyrillicOrder 里的位置（表外的排在表内之后，按码点）。
int groupRank(String group) {
  // 分组键保证非空（keyOf 总会返回 '#' 兜底），否则这里会抛 StateError。
  final c = group.runes.first;
  final script = scriptOf(c);
  final bucket = switch (script) {
    Script.latin => 0,
    Script.kana => 1,
    Script.hangul => 2,
    Script.cyrillic => 3,
    Script.han => 4,
    Script.other => 9,
  };
  // 组内位置：西里尔查顺序表，其余直接用码点（最大 0x10FFFF）
  var inner = c;
  if (script == Script.cyrillic) {
    final i = _cyrillicOrder.indexOf(group[0]);
    inner = i >= 0 ? i : 0x10000 + c;
  }
  // 0x200000 > 最大码点 0x10FFFF，所以文字系统(bucket)优先，其次才比组内位置。
  // Script.han 在上面的 switch 里实际不会出现：汉字都已转成拼音首字母。
  return bucket * 0x200000 + inner;
}

/// 先比分组，再比组内排序键
int compareKeys(TextKey a, TextKey b) {
  final r = groupRank(a.group).compareTo(groupRank(b.group));
  // String.compareTo 按 UTF-16 码元逐个比较，与语言环境无关；
  // 大小写和音标已在 keyOf 里统一，所以这里不需要再处理。
  return r != 0 ? r : a.sort.compareTo(b.sort);
}
