import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_model.dart';

class AlbumLib extends StatelessWidget implements PageModel {
  const AlbumLib({super.key});

  @override
  String get title => '专辑';

  @override
  IconData get icon => Icons.album_outlined;

  @override
  IconData get selectedIcon => Icons.album;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('AlbumLib')),
    );
  }
}
