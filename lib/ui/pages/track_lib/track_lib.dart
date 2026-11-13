import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/providers/tracks_provider.dart';
import 'package:material_ui/material_ui.dart';

import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/utils/track_sort.dart';

import 'package:linglun/ui/widgets/list_page_actions.dart';
import 'package:linglun/ui/pages/track_lib/widgets/track_list_view.dart';

class TrackLib extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TrackLib> createState() => _TrackLibState();
}

class _TrackLibState extends ConsumerState<TrackLib> {
  SortConfig sortConfig = const SortConfig(TrackSort.titleInLatin, false);
  late List<TrackInfo> originalMusicList;

  @override
  Widget build(BuildContext context) {
    List<TrackInfo> originalMusicList = ref.watch(tracksProvider);
    Map<String, List<TrackInfo>> groupedMusicList = groupMusicList(
      sortMusicList(originalMusicList, sortConfig),
      sortConfig,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('曲库', style: TextStyle(overflow: TextOverflow.fade)),
        actions: [
          ListPageActions(
            sortConfig: sortConfig,
            onSortChanged: (value) => setState(() => sortConfig = value),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: TrackListView(
            groupedMusicList: groupedMusicList,
            hasGroups: !groupedMusicList.keys.contains('default'),
          ),
        ),
      ),
    );
  }
}
