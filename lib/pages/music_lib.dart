import 'package:flutter/material.dart';

import 'package:linglun/frame/page_model.dart';

class MusicLib extends StatelessWidget implements PageModel {
  const MusicLib({super.key});

  @override
  String get title => '曲库';

  @override
  IconData get icon => Icons.library_music_outlined;

  @override
  IconData get selectedIcon => Icons.library_music;

  @override
  List<Widget> get appBarActions => [
    IconButton(onPressed: () {}, icon: const Icon(Icons.sort)),
    IconButton(onPressed: () {}, icon: const Icon(Icons.check_box_outlined)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)],
    );
  }
}
