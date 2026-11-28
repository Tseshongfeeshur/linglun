import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/utils/track_sort.dart';
import 'package:linglun/states/repo_provider.dart';

/// 全局曲库（含被标记 removed 的曲目）监听
final tracksProvider = StreamProvider<List<TrackInfo>>(
  (ref) => ref.watch(repoProvider).watchTracks(),
);

final groupedTracksProvider = Provider.autoDispose
    .family<AsyncValue<List<TrackListItemType>>, SortConfig>((ref, sortConfig) {
      return ref
          .watch(tracksProvider)
          .whenData(
            (data) =>
                groupTrackList(sortTrackList(data, sortConfig), sortConfig),
          );
    });
