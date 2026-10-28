import 'package:flutter/material.dart';

import 'package:linglun/frame/page_model.dart';

class ArtistLib extends StatelessWidget implements PageModel {
  const ArtistLib({super.key});

  @override
  String get title => '艺术家';

  @override
  IconData get icon => Icons.person_outline;

  @override
  IconData get selectedIcon => Icons.person;

  @override
  List<Widget> get appBarActions => [];

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('ArtistLib'));
  }
}
