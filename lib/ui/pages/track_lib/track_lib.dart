import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/ui/widgets/drawer_menu_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/states/tracks_provider.dart';

import 'package:linglun/data/utils/track_sort.dart';

import 'package:linglun/ui/widgets/list_page_actions.dart';
import 'package:linglun/ui/pages/track_lib/widgets/track_list_view.dart';

/// 曲库页：自己持有 Scaffold/AppBar，页面状态（排序方式）放在 State 里，
/// 用 setState；曲目数据来自全局的 tracksProvider。
class TrackLib extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TrackLib> createState() => _TrackLibState();
}

class _TrackLibState extends ConsumerState<TrackLib> {
  // 默认按标题升序。
  SortConfig sortConfig = const SortConfig(TrackSort.title, false);

  @override
  Widget build(BuildContext context) {
    final groupedTracks = ref.watch(groupedTracksProvider(sortConfig));

    return Scaffold(
      appBar: AppBar(
        leading: context.layout == WindowLayout.phone
            ? const DrawerMenuButton()
            : null,
        title: const Text('曲库', style: TextStyle(overflow: TextOverflow.fade)),
        actions: [
          ListPageActions(
            sortConfig: sortConfig,
            onSortChanged: (value) => setState(() => sortConfig = value),
          ),
        ],
      ),
      // 列表限宽 960 并顶部居中（TrackSources 页里没有居中，两页不一致）。
      // TODO: 曲库为空时没有空状态提示，应引导用户去"歌曲来源"页扫描。
      body: Align(
        alignment: AlignmentGeometry.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: TrackListView(
            groupedTracks: groupedTracks,
            // TODO: 靠"有没有 'default' 这个键"反推是否分组，见 track_sort.dart
            // 里 groupTrackList 的 TODO。
            hasGroups: !groupedTracks.keys.contains('default'),
          ),
        ),
      ),
    );
  }
}
