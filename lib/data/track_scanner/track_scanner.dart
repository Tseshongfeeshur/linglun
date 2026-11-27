import 'dart:async';

import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/models/discover_event.dart';
import 'package:linglun/data/track_scanner/models/parse_event.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:path/path.dart' as p;

import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/utils/collation_of.dart';

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
      final track = TrackInfo(
        sourceKey: item.sourceKey,
        title: title,
        titleCollation: collationOf(title),
        artists: tag.artists,
        artistsCollation: collationOfNullable(tag.artists.firstOrNull),
        album: tag.album,
        albumCollation: collationOfNullable(tag.album),
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
