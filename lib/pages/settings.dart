import 'package:flutter/material.dart';

import 'package:linglun/frame/page_model.dart';

class Settings extends StatelessWidget implements PageModel {
  const Settings({super.key});

  @override
  String get title => '设置';

  @override
  IconData get icon => Icons.settings_outlined;

  @override
  IconData get selectedIcon => Icons.settings;

  @override
  List<Widget> get appBarActions => [];

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Settings'));
  }
}
