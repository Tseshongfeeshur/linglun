import 'package:material_ui/material_ui.dart';

import 'package:linglun/frame/page_model.dart';

import 'package:linglun/pages/music_lib/search_field.dart';

class MusicLib extends StatelessWidget implements PageModel {
  MusicLib({super.key});

  final TextEditingController controller = TextEditingController();

  @override
  String get title => '曲库';

  @override
  IconData get icon => Icons.library_music_outlined;

  @override
  IconData get selectedIcon => Icons.library_music;

  @override
  List<Widget> get appBarActions => [
    SizedBox(width: 4),
    IconButton(onPressed: () {}, icon: const Icon(Icons.sort)),
    SizedBox(width: 6),
    IconButton(onPressed: () {}, icon: const Icon(Icons.check_box_outlined)),
    SizedBox(width: 2),
    SearchField(controller: controller),
    SizedBox(width: 4),
  ];

  @override
  FloatingActionButton? get fab => null;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('MusicLib'));
  }
}
