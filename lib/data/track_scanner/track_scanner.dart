import 'dart:async';

import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:path/path.dart' as p;

import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/utils/group_key_of.dart';

// 只按扩展名过滤。
const _extensions = {
  // 高频有损 / 流媒体
  '.mp3',
  '.m4a',
  '.aac',
  '.ogg',
  '.opus',
  '.wma',
  // 无损 / 未压缩
  '.flac',
  '.wav',
  '.aif',
  '.aiff',
  '.ape',
};

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

// ===== 解析阶段（读标签，较慢）的事件 =====
sealed class ParseEvent {}

/// 新增或已变化的曲目（也用于"库里有、这次没发现"的曲目，此时 removed == true）。
class TrackParsed extends ParseEvent {
  final TrackInfo track;
  new({required this.track});
}

/// 与库里记录一致、无需重新解析的曲目（沿用旧记录）。
class TrackSkipped extends ParseEvent {
  final TrackInfo track;
  new({required this.track});
}

class TrackParsedError extends ParseEvent {
  final FileDiscovered file;
  final String detail;
  new({required this.file, required this.detail});
}

class TrackParsedFinish extends ParseEvent {}

/// 两阶段扫描：
///   1. discover：遍历来源目录，列出音频文件（去重、按扩展名过滤）；
///   2. parse：对每个文件读标签，并与已有曲库比对做增量更新。
/// 两个阶段由调用方（scan_provider）接力，这样能分别显示进度。
/// 平台相关的部分（遍历方式、读标签）都在 PlatformFileUtils 里。
class TrackScanner {
  Stream<DiscoverEvent> discover(
    PlatformFileUtils utils,
    Set<String> rootUris,
  ) async* {
    // 去重：来源目录重叠（如同时选了父目录和子目录）时，同一个文件会被
    // 发现多次。以 sourceKey 为准，先到先得（所以保留哪个 uri 取决于遍历顺序）。
    final keys = <String>{};
    final list = utils.discover(rootUris);
    await for (final item in list) {
      switch (item) {
        case FileDiscovered():
          final ext = p.extension(item.name).toLowerCase();
          // 这里的 continue 作用于外层的 await for（Dart 的 switch 分支不需要 break）。
          if (!_extensions.contains(ext)) continue;
          if (keys.contains(item.sourceKey)) continue;

          keys.add(item.sourceKey);
          yield item;
        case FileDiscoveredError():
          yield item;
        case FileDiscoveredFinish():
          yield item;
      }
    }
  }

  /// 解析 files 里的文件，与 existing（现有曲库）对比：
  ///   - 没变化 → TrackSkipped（沿用旧记录，只更新 uri）；
  ///   - 新增/已变化 → TrackParsed（playCount、addTime 沿用旧值）；
  ///   - 失败 → TrackParsedError；
  ///   - 库里有、files 里没有 → 标记 removed 后以 TrackParsed 发出。
  /// 最后以 TrackParsedFinish 结束。
  Stream<ParseEvent> parse(
    PlatformFileUtils utils,
    List<FileDiscovered> files,
    List<TrackInfo> existing,
  ) async* {
    // 以 sourceKey 建索引。处理过的会从 map 里移走，循环结束后剩下的
    // 就是"库里有、这次没发现"的曲目。
    var existingMap = <String, TrackInfo>{
      for (final TrackInfo element in existing) element.sourceKey: element,
    };

    for (final item in files) {
      SimpleTag tag;
      final existingTrack = existingMap[item.sourceKey];

      try {
        if (existingTrack != null) {
          // 若曲库数据版本过时，不管文件是否被修改都重新解析。
          if (existingTrack.version == TrackInfo.currentVersion) {
            existingMap.remove(item.sourceKey);
            // 路径身份(sourceKey)、修改时间、大小都相同 → 认为文件没变，跳过解析。
            // editTime 为 0 或 sizeBytes 为 -1 说明平台没给出可靠信息，不能据此判断
            // "没变"，必须重新解析。
            if ((existingTrack.editTime == item.editTime &&
                    existingTrack.sizeBytes == item.sizeBytes) &&
                (existingTrack.editTime.millisecondsSinceEpoch != 0 &&
                    existingTrack.sizeBytes != -1)) {
              yield TrackSkipped(
                track: existingTrack.copyWith(uri: item.uri, removed: false),
              );
              continue;
            }
          }
        }
        tag = await utils.parse(item);
      } catch (e) {
        // 如果 item 是库里已有的曲目、重新解析失败（文件被改坏/截断），保留旧记录。
        if (existingTrack != null) {
          yield TrackSkipped(track: existingTrack.copyWith(removed: true));
        }
        yield TrackParsedError(file: item, detail: e.toString());
        continue;
      }

      final title = tag.title ?? p.basenameWithoutExtension(item.name);
      final artists = (tag.artists?.isEmpty ?? false) ? null : tag.artists;
      final artistsKeys = tag.artists?.map((i) => keyOf(i)).toList();
      final track = TrackInfo(
        sourceKey: item.sourceKey,
        title: title,
        titleKey: keyOf(title),
        artists: artists,
        artistsKeys: (artistsKeys != null && artistsKeys.isNotEmpty)
            ? artistsKeys
            : [keyOfNullable(null)],
        album: tag.album,
        albumKey: keyOfNullable(tag.album),
        uri: item.uri,
        fileName: item.name,
        sizeBytes: item.sizeBytes,
        durationMs: tag.durationMs,
        // 文件变了，标签里的增益可能已失效
        // TODO: 应用自己回写增益也会改变文件修改时间，
        // 回写后必须同步更新库里的 editTime，否则下次扫描会被当成"文件变了"。
        trackGainUpdated: false,
        editTime: item.editTime,
        playCount: existingTrack?.playCount ?? 0,
        addTime: existingTrack?.addTime ?? DateTime.now(),
        removed: false,
      );
      yield TrackParsed(track: track);
    }
    for (var item in existingMap.values) {
      yield TrackParsed(track: item.copyWith(removed: true));
    }
    yield TrackParsedFinish();
  }
}
