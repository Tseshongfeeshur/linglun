import 'package:material_ui/material_ui.dart';

import 'package:linglun/data/utils/track_sort.dart';
import 'package:linglun/ui/widgets/list_page_actions.dart';
import 'package:linglun/ui/pages/track_lib/widgets/track_list_view.dart';

import 'package:linglun/data/models/track_info_model.dart';

import 'package:linglun/test/track_list_generator.dart';

class TrackLib extends StatefulWidget {
  const TrackLib({super.key});

  @override
  State<TrackLib> createState() => _TrackLibState();
}

class _TrackLibState extends State<TrackLib> {
  SortConfig sortConfig = SortConfig(TrackSort.titleInLatin, false);
  late List<TrackInfo> originalMusicList;

  @override
  void initState() {
    super.initState();
    originalMusicList = getTrackList();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<TrackInfo>> groupedMusicList = groupMusicList(
      sortMusicList(originalMusicList, sortConfig),
      sortConfig,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('曲库', style: TextStyle(overflow: TextOverflow.fade)),
        actions: [
          ListPageActions(
            sortConfig: sortConfig,
            onSortChanged: (value) => setState(() => sortConfig = value),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 960),
          child: MusicListView(
            groupedMusicList: groupedMusicList,
            hasGroups: !groupedMusicList.keys.contains('default'),
          ),
        ),
      ),
    );
  }
}
