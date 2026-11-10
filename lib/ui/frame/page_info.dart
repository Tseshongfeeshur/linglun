import 'package:material_ui/material_ui.dart';

class PageInfo {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  PageInfo({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}
