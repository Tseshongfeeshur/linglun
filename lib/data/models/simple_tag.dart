/// 从音频文件标签里读出的原始信息（解析阶段的中间产物），
/// 之后由 TrackScanner 补全分组键等字段，变成 TrackInfo。
/// title / artists / album 缺失时为 null（不是空串）。
class SimpleTag {
  final String? title;
  final List<String> artists;
  final String? album;
  // 标签里的时长（毫秒）。无标签 mp3 / 部分 VBR mp3 可能为 0 或不准，
  // 按项目决定：播放时用播放器返回的时长覆盖它。
  final int durationMs;

  new({
    this.title,
    required this.artists,
    this.album,
    required this.durationMs,
  });
}
