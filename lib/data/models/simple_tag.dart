class SimpleTag {
  final String? title;
  final List<String>? artists;
  final String? album;
  final int durationMs;

  new({this.title, this.artists, this.album, required this.durationMs});
}
