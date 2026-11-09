import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/utils/window_info.dart';
import 'package:linglun/ui/frame/page_model.dart';
import 'package:linglun/data/utils/track_sort.dart';
import 'package:linglun/ui/pages/widgets/list_page_actions.dart';
import 'package:linglun/ui/pages/track_lib/widgets/track_list_view.dart';

import 'package:linglun/data/models/track_info_model.dart';

import 'package:linglun/test/music_list_generator.dart';

class TrackLib extends StatefulWidget implements PageModel {
  const TrackLib({super.key});

  @override
  String get title => '曲库';

  @override
  IconData get icon => Icons.library_music_outlined;

  @override
  IconData get selectedIcon => Icons.library_music;

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
        title: Text(
          widget.title,
          style: TextStyle(overflow: TextOverflow.fade),
        ),
        actions: [
          ListPageActions(
            sortConfig: sortConfig,
            onSortChanged: (value) => setState(() => sortConfig = value),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: context.isDesktop ? 960 : null,
          child: MusicListView(
            groupedMusicList: groupedMusicList,
            hasGroups: !groupedMusicList.keys.contains('default'),
          ),
        ),
      ),
    );
  }
}
