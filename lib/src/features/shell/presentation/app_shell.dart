import 'package:flutter/material.dart';

import '../../library/presentation/library_page.dart';
import '../../player/presentation/now_playing_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _NavigationRail(
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
          const VerticalDivider(width: 1),
          const Expanded(child: LibraryPage()),
        ],
      ),
      bottomNavigationBar: const NowPlayingBar(),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '伶伦',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 30),
          _NavItem(
            icon: Icons.library_music_outlined,
            label: '曲库',
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _NavItem(
            icon: Icons.album_outlined,
            label: '专辑',
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: '艺术家',
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _NavItem(
            icon: Icons.queue_music,
            label: '播放列表',
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.tune,
            label: '音频设置',
            selected: selectedIndex == 4,
            onTap: () => onSelected(4),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: '设置',
            selected: selectedIndex == 5,
            onTap: () => onSelected(5),
          ),
        ],
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: Theme.of(context).colorScheme.primary
              .withAlpha(25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          leading: Icon(icon, color: color, size: 21),
          title: Text(label, style: TextStyle(color: color)),
          onTap: onTap,
        ),
      ),
    );
  }
}
