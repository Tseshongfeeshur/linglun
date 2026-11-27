import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/utils/track_sort.dart';
import 'package:linglun/states/repo_provider.dart';

/// 全局曲库（含被标记 removed 的曲目）。扫描完成后整体替换。
// TODO: 改为同步，数据库监听
class _TracksNotifier extends AsyncNotifier<List<TrackInfo>> {
  @override
  Future<List<TrackInfo>> build() async {
    final repo = ref.read(repoProvider);
    return repo.getTracks();
  }
}

final tracksProvider = AsyncNotifierProvider<_TracksNotifier, List<TrackInfo>>(
  _TracksNotifier.new,
);

final groupedTracksProvider = Provider.autoDispose
    .family<List<TrackListItemType>, SortConfig>((ref, sortConfig) {
      final tracks = ref.watch(tracksProvider);
      return groupTrackList(sortTrackList(tracks, sortConfig), sortConfig);
    });
