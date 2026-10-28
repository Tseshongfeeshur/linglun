import 'package:flutter/material.dart';

abstract interface class PageModel {
  String get title;
  IconData get icon;
  IconData get selectedIcon;
  List<Widget>? get appBarActions => null;
}
