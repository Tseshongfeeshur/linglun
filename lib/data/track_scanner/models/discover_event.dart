// ===== 发现阶段（遍历目录，只列文件，不读标签，很快）的事件 =====
sealed class DiscoverEvent {}

/// 发现了一个文件（还没有解析标签）。
class FileDiscovered extends DiscoverEvent {
  final String uri;
  // 身份键，用于去重与增量比对，含义见 TrackInfo.sourceKey。
  final String sourceKey;
  final String name;
  // 平台取不到时 sizeBytes 可能是 -1、editTime 可能是 epoch 0；
  // TrackScanner.parse 会据此放弃"未变化→跳过"的判断。
  final int sizeBytes;
  final DateTime editTime;

  new({
    required this.uri,
    required this.sourceKey,
    required this.name,
    required this.sizeBytes,
    required this.editTime,
  });
}

class FileDiscoveredError extends DiscoverEvent {
  final String uri;
  final String detail;

  new({required this.uri, required this.detail});
}

class FileDiscoveredFinish extends DiscoverEvent {}
