import 'package:flutter/material.dart';

import 'package:linglun/frame/page_model.dart';

class MusicSources extends StatelessWidget implements PageModel {
  const MusicSources({super.key});

  @override
  String get title => '歌曲来源';

  @override
  IconData get icon => Icons.folder_special_outlined;

  @override
  IconData get selectedIcon => Icons.folder_special;

  @override
  List<Widget> get appBarActions => [];

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('MusicSources'));
  }
}
