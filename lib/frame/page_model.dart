import 'package:material_ui/material_ui.dart';

abstract interface class PageModel {
  String get title;
  IconData get icon;
  IconData get selectedIcon;
  List<Widget>? get appBarActions => null;
  FloatingActionButton? get fab => null;
}
