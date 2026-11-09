import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/utils/window_info.dart';

import 'package:linglun/ui/frame/page_model.dart';

import 'package:linglun/ui/pages/album_lib.dart';
import 'package:linglun/ui/pages/artist_lib.dart';
import 'package:linglun/ui/pages/track_lib/track_lib.dart';
import 'package:linglun/ui/pages/track_sources.dart';
import 'package:linglun/ui/pages/playlist.dart';
import 'package:linglun/ui/pages/settings.dart';

class Frame extends StatefulWidget {
  const Frame({super.key});

  @override
  State<Frame> createState() => _FrameState();
}

class _FrameState extends State<Frame> {
  int pageIndex = 0;
  final List<PageModel> pages = [
    TrackLib(),
    AlbumLib(),
    ArtistLib(),
    Playlist(),
    TrackSources(),
    Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        context.isTablet
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
            body: pages[pageIndex] as Widget,
            bottomNavigationBar: context.isTablet
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
