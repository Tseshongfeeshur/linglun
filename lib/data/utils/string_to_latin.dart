import 'package:romanize/romanize.dart';
import 'package:diacritic/diacritic.dart';

Future<void>? _romanizeInit;

final _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

final _invalid = RegExp(r'[^a-z0-9\s]', unicode: true);
final _spaces = RegExp(r'\s+');

// final _multiSharp = RegExp(r'#(\s*#)+');

Future<void> initRomanize() =>
    _romanizeInit ??= TextRomanizer.ensureInitialized();

extension StringUtils on String {
  /// 转换前需要执行 `await initRomanize();`
  String toLatin() {
    var result = trim();
    if (result.isEmpty) return '#';

    // 符号两侧手动分词
    // m[0] 是匹配到的符号
    result = result.replaceAllMapped(_symbol, (m) => ' ${m[0]} ');

    try {
      result = TextRomanizer.romanize(result);
    } catch (_) {}

    result = removeDiacritics(result)
        .toLowerCase()
        .replaceAll(_invalid, '#')
        // .replaceAll(_multiSharp, '#')
        .replaceAll(_spaces, ' ')
        .trim();

    return result.isEmpty ? '#' : result;
  }
}
