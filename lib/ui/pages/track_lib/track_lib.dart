import 'package:material_ui/material_ui.dart';
import 'package:linglun/ui/widgets/reveal_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/data/providers/drawer_provider.dart';
import 'package:linglun/data/providers/tracks_provider.dart';

import 'package:linglun/data/models/track_info.dart';
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
    final drawerState = ref.watch<DrawerState>(drawerProvider);
    final layout = context.layout;

    List<TrackInfo> originalMusicList = ref.watch(tracksProvider);
    Map<String, List<TrackInfo>> groupedMusicList = groupMusicList(
      sortMusicList(originalMusicList, sortConfig),
      sortConfig,
    );

    return Scaffold(
      appBar: AppBar(
        leading: layout == WindowLayout.phone
            ? IconButton(
                onPressed: () =>
                    ref.read(drawerProvider.notifier).switchExtendingAt(layout),
                icon: RevealIcon(
                  isFilled: drawerState.extendedAt(layout),
                  outlineIcon: Icons.menu,
                  filledIcon: Icons.menu_open,
                  outlineIconColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  filledIconColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              )
            : null,
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
