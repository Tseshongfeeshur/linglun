import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/library_controller.dart';
import '../../library/presentation/library_page.dart';
import '../../library/presentation/collection_pages.dart';
import '../../library/presentation/sources_page.dart';
import '../../player/presentation/floating_player.dart';
import '../../library/presentation/scan_progress_dialog.dart';
import 'settings_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryControllerProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final portrait = constraints.maxHeight > constraints.maxWidth;
          final page = _buildPage();
          final content = portrait
              ? Stack(
                  children: [
                    Positioned.fill(child: page),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Center(
                        child: _NavigationRail(
                          selectedIndex: _selectedIndex,
                          vertical: false,
                          onSelected: (index) =>
                              setState(() => _selectedIndex = index),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const SizedBox(width: 16),
                    Center(
                      child: SafeArea(
                        child: _NavigationRail(
                          selectedIndex: _selectedIndex,
                          vertical: true,
                          onSelected: (index) =>
                              setState(() => _selectedIndex = index),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: page),
                  ],
                );
          return Stack(
            children: [
              Positioned.fill(child: content),
              const Positioned.fill(child: FloatingPlayer()),
              if (libraryState.isScanning) ...[
                const Positioned.fill(
                  child: ModalBarrier(
                    dismissible: false,
                    color: Colors.black54,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: ScanProgressDialog(
                      path: libraryState.scanPath,
                      stage: libraryState.scanStage,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPage() {
    return switch (_selectedIndex) {
      1 => const AlbumsPage(),
      2 => const ArtistsPage(),
      3 => const PlaylistsPage(),
      4 => const SourcesPage(),
      5 => const SettingsPage(),
      _ => const LibraryPage(),
    };
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.selectedIndex,
    required this.vertical,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool vertical;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.library_music_outlined, label: '曲库', index: 0),
      (icon: Icons.album_outlined, label: '专辑', index: 1),
      (icon: Icons.person_outline, label: '艺术家', index: 2),
      (icon: Icons.queue_music, label: '播放列表', index: 3),
      (icon: Icons.folder_special_outlined, label: '歌曲来源', index: 4),
      (icon: Icons.settings_outlined, label: '设置', index: 5),
    ];
    final children = <Widget>[];
    for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
      if (itemIndex == 4 || itemIndex == 5) {
        children.add(
          const Padding(
            padding: EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white38,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 4, height: 4),
            ),
          ),
        );
      }
      final item = items[itemIndex];
      children.add(
        _NavItem(
          icon: item.icon,
          label: item.label,
          selected: selectedIndex == item.index,
          onTap: () => onSelected(item.index),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: vertical
            ? Column(mainAxisSize: MainAxisSize.min, children: children)
            : Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.white60;

    final tileColor = selected
        ? Theme.of(context).colorScheme.primary.withAlpha(35)
        : Colors.transparent;
    return Tooltip(
      message: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}
