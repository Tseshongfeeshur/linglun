import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/utils/track_sort.dart';

/// 全局曲库（含被标记 removed 的曲目）。扫描完成后整体替换。
class _TracksNotifier extends Notifier<List<TrackInfo>> {
  @override
  List<TrackInfo> build() {
    // TODO: 从数据库获取
    return [];
  }

  void replaceAll(List<TrackInfo> tracks) {
    state = tracks;
  }
}

final tracksProvider = NotifierProvider<_TracksNotifier, List<TrackInfo>>(
  _TracksNotifier.new,
);

final groupedTracksProvider = Provider.autoDispose
    .family<List<TrackListItemType>, SortConfig>((ref, sortConfig) {
      final tracks = ref.watch(tracksProvider);
      return groupTrackList(sortTrackList(tracks, sortConfig), sortConfig);
    });
