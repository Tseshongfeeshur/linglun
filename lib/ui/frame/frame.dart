import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/data/providers/drawer_provider.dart';
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
    const double mediumDrawerWidth = 56, largeDrawerWidth = 220;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Animate(target: drawerState.extended[layout] ?? false ? 1 : 0)
          .custom(
            duration: 200.ms,
            curve: Curves.easeInOutCubic,
            builder: (context, progress, child) => Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: layout == WindowLayout.phone
                        ? 0
                        : (layout == WindowLayout.tablet
                              ? 56
                              : mediumDrawerWidth +
                                    (largeDrawerWidth - mediumDrawerWidth) *
                                        progress),
                  ),
                  child: IndexedStack(
                    index: pageIndex,
                    children: pages.map((pageInfo) => pageInfo.page).toList(),
                  ),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).height,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(
                      (120 * (layout == WindowLayout.phone ? progress : 0))
                          .toInt()
                          .clamp(0, 120),
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
                      extended: drawerState.extended[layout] ?? false,
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
