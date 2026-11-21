import 'package:material_ui/material_ui.dart';

/// 抽屉里的一个页面项：标题、两种状态的图标，以及页面本身。
class PageInfo {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  new({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}
