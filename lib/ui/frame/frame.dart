import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/data/models/drawer_state.dart';
import 'package:linglun/states/drawer_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/ui/frame/widgets/app_drawer.dart';

import 'package:linglun/ui/frame/page_info.dart';

import 'package:linglun/ui/pages/album_lib.dart';
import 'package:linglun/ui/pages/artist_lib.dart';
import 'package:linglun/ui/pages/track_lib/track_lib.dart';
import 'package:linglun/ui/pages/track_sources/track_sources.dart';
import 'package:linglun/ui/pages/playlist.dart';
import 'package:linglun/ui/pages/settings.dart';

/// 应用外框：左侧抽屉 + 页面区。
/// 页面放在 IndexedStack 里同时保活（切页不丢状态，如排序方式、滚动位置）。
class Frame extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<Frame> createState() => _FrameState();
}

class _FrameState extends ConsumerState<Frame> {
  int pageIndex = 0;
  void onPageSwitched(int index) => setState(() => pageIndex = index);

  final List<PageInfo> pages = [
    PageInfo(
      title: '曲库',
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      page: const TrackLib(),
    ),
    PageInfo(
      title: '专辑',
      icon: Icons.album_outlined,
      selectedIcon: Icons.album,
      page: const AlbumLib(),
    ),
    PageInfo(
      title: '艺术家',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: const ArtistLib(),
    ),
    PageInfo(
      title: '歌单',
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music,
      page: const Playlist(),
    ),
    PageInfo(
      title: '歌曲来源',
      icon: Icons.folder_special_outlined,
      selectedIcon: Icons.folder_special,
      page: const TrackSources(),
    ),
    PageInfo(
      title: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      page: const Settings(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final drawerState = ref.watch<DrawerState>(drawerProvider);
    final layout = context.layout;
    // 抽屉两种宽度：收起态 56（只有图标）、展开态 220。
    const double mediumDrawerWidth = 56, largeDrawerWidth = 220;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // progress 是 0（收起）~ 1（展开）的动画进度。三种布局下抽屉的行为：
      //   phone  ：抽屉(220)从左侧滑入并浮在页面上，页面不让位，背后有半透明遮罩；
      //   tablet ：页面左侧固定留 56 给收起态抽屉；展开时抽屉在页面上方变宽（带阴影），
      //            不推动页面；
      //   desktop：抽屉常驻，页面左边距随动画在 56↔220 之间插值，推动页面。
      body: Animate(target: drawerState.extendedAt(layout) ? 1 : 0).custom(
        duration: 200.ms,
        curve: Curves.easeInOutCubic,
        builder: (context, progress, child) => Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: layout == WindowLayout.phone
                    ? 0
                    : (layout == WindowLayout.tablet
                          ? mediumDrawerWidth
                          : mediumDrawerWidth +
                                (largeDrawerWidth - mediumDrawerWidth) *
                                    progress),
              ),
              child: IndexedStack(
                index: pageIndex,
                children: pages.map((pageInfo) => pageInfo.page).toList(),
              ),
            ),
            // 遮罩：只在手机布局下有颜色。它始终在树里，靠 IgnorePointer 决定是否拦截点击：
            // 手机且抽屉展开时才拦截（吸收对页面的点击），点击后由下面抽屉上的
            // TapRegion.onTapOutside 负责把抽屉收起。
            Positioned.fill(
              child: IgnorePointer(
                ignoring:
                    !(layout == WindowLayout.phone &&
                        drawerState.extendedAt(layout)),
                child: Container(
                  color: Colors.black.withAlpha(
                    (120 * (layout == WindowLayout.phone ? progress : 0))
                        .toInt()
                        .clamp(0, 120),
                  ),
                ),
              ),
            ),
            Positioned(
              left: layout == WindowLayout.phone
                  ? (-largeDrawerWidth * (1 - progress))
                  : 0,
              top: 0,
              bottom: 0,
              width: layout == WindowLayout.phone
                  ? largeDrawerWidth
                  : mediumDrawerWidth +
                        (largeDrawerWidth - mediumDrawerWidth) * progress,
              // 点击抽屉外部就收起抽屉（桌面端抽屉常驻，所以关掉）。
              child: TapRegion(
                enabled: layout != WindowLayout.desktop,
                onTapOutside: (event) => ref
                    .read(drawerProvider.notifier)
                    .switchExtendingAt(layout, target: false),
                child: AppDrawer(
                  pageIndex: pageIndex,
                  pages: pages,
                  onSelected: onPageSwitched,
                  layout: layout,
                  mediumDrawerWidth: mediumDrawerWidth,
                  largeDrawerWidth: largeDrawerWidth,
                  extended: drawerState.extendedAt(layout),
                  animationProgress: progress,
                  onTapSwitch: ([bool? value]) => ref
                      .read(drawerProvider.notifier)
                      .switchExtendingAt(layout, target: value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
