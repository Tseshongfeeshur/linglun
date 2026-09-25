/// 判断歌词词语是否满足 AMLL 的字符强调条件。
bool isAmlEmphasizedLyricWord(String text, Duration duration) {
  if (duration < const Duration(seconds: 1)) return false;
  if (isAmlCjkLyricWord(text)) return true;

  final trimmedLength = text.trim().length;
  return trimmedLength > 1 && trimmedLength <= 7;
}

bool isAmlCjkLyricWord(String text) => _amllCjkWordPattern.hasMatch(text);

final _amllCjkWordPattern = RegExp(
  r'^[\p{Unified_Ideograph}\u0800-\u9FFC]+$',
  unicode: true,
);
