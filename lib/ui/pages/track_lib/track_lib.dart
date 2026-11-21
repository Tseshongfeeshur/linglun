import 'package:material_ui/material_ui.dart';
import 'package:linglun/ui/widgets/reveal_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/data/models/drawer_state.dart';
import 'package:linglun/states/drawer_provider.dart';
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
    final drawerState = ref.watch<DrawerState>(drawerProvider);
    final layout = context.layout;

    // TODO: 排序+分组放在 build 里，每次重建都重算（O(n log n)）。会触发重建的有：
    //   1. 拖动窗口宽度（context.layout 依赖 MediaQuery，拖动时每一帧都重建）；
    //   2. drawerProvider 的任何变化（手机/平板上每次点击屏幕都会触发，
    //      见 drawer_provider.dart 里的 TODO）；
    //   3. 以后新增的搜索等状态。
    // 曲目上千后会明显掉帧。可以：只 select 自己需要的字段；把排序+分组结果缓存，
    // 仅当曲库或 sortConfig 变化时才重算（didUpdateWidget，或做成派生 Provider）。
    final originalTrackList = ref.watch(tracksProvider);
    var groupedTrackList = groupTrackList(
      sortTrackList(originalTrackList, sortConfig),
      sortConfig,
    );

    return Scaffold(
      appBar: AppBar(
        // TODO: 手机上的汉堡菜单按钮在 TrackLib/TrackSources/AlbumLib/ArtistLib/
        // Playlist/Settings 六个页面里各抄了一份，且行为不一致：这里是"切换"，
        // 其余页面是 target: true（总是展开）。抽成一个 DrawerMenuButton 组件，
        // 内部自己 watch drawerProvider。
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
      // 列表限宽 960 并顶部居中（TrackSources 页里没有居中，两页不一致）。
      // TODO: 曲库为空时没有空状态提示，应引导用户去"歌曲来源"页扫描。
      body: Align(
        alignment: AlignmentGeometry.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: TrackListView(
            groupedTrackList: groupedTrackList,
            // TODO: 靠"有没有 'default' 这个键"反推是否分组，见 track_sort.dart
            // 里 groupTrackList 的 TODO。
            hasGroups: !groupedTrackList.keys.contains('default'),
            descending: sortConfig.descending,
          ),
        ),
      ),
    );
  }
}
