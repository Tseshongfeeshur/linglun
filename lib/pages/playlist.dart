import 'package:material_ui/material_ui.dart';

import 'package:linglun/frame/page_model.dart';

class Playlist extends StatelessWidget implements PageModel {
  const Playlist({super.key});

  @override
  String get title => '播放列表';

  @override
  IconData get icon => Icons.queue_music_outlined;

  @override
  IconData get selectedIcon => Icons.queue_music;

  @override
  List<Widget>? get appBarActions => null;

  @override
  FloatingActionButton? get fab => null;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Playlist'));
  }
}
