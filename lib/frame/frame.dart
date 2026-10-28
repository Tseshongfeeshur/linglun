import 'package:flutter/material.dart';

import 'package:linglun/utils/window_info.dart';

import 'package:linglun/frame/page_model.dart';

import 'package:linglun/pages/album_lib.dart';
import 'package:linglun/pages/artist_lib.dart';
import 'package:linglun/pages/music_lib.dart';
import 'package:linglun/pages/music_sources.dart';
import 'package:linglun/pages/playlist.dart';
import 'package:linglun/pages/settings.dart';

class Frame extends StatefulWidget {
  const Frame({super.key});

  @override
  State<Frame> createState() => _FrameState();
}

class _FrameState extends State<Frame> {
  int pageIndex = 0;
  final List<PageModel> pages = [
    const MusicLib(),
    const AlbumLib(),
    const ArtistLib(),
    const Playlist(),
    const MusicSources(),
    const Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        context.isLandscape
            ? NavigationRail(
                selectedIndex: pageIndex,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                mainAxisAlignment: MainAxisAlignment.center,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (value) => setState(() {
                  pageIndex = value;
                }),
                destinations: List.generate(
                  pages.length,
                  (currentIndex) => NavigationRailDestination(
                    icon: pageIndex == currentIndex
                        ? Icon(pages[currentIndex].selectedIcon)
                        : Icon(pages[currentIndex].icon),
                    label: Text(pages[currentIndex].title),
                  ),
                ),
              )
            : SizedBox.shrink(),
        Expanded(
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text(pages[pageIndex].title),
              actions: pages[pageIndex].appBarActions,
            ),
            body: pages[pageIndex] as Widget,
            bottomNavigationBar: context.isLandscape
                ? null
                : NavigationBar(
                    selectedIndex: pageIndex,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    onDestinationSelected: (value) => setState(() {
                      pageIndex = value;
                    }),
                    destinations: List.generate(
                      pages.length,
                      (currentIndex) => NavigationDestination(
                        icon: Icon(pages[currentIndex].icon),
                        selectedIcon: Icon(pages[currentIndex].selectedIcon),
                        label: pages[currentIndex].title,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
