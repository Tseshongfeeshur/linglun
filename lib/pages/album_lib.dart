import 'package:material_ui/material_ui.dart';

import 'package:linglun/frame/page_model.dart';

class AlbumLib extends StatelessWidget implements PageModel {
  const AlbumLib({super.key});

  @override
  String get title => '专辑';

  @override
  IconData get icon => Icons.album_outlined;

  @override
  IconData get selectedIcon => Icons.album;

  @override
  List<Widget>? get appBarActions => null;

  @override
  FloatingActionButton? get fab => null;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('AlbumLib'));
  }
}
