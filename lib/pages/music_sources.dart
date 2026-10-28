import 'package:material_ui/material_ui.dart';

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
  List<Widget>? get appBarActions => null;

  @override
  FloatingActionButton get fab => FloatingActionButton.extended(
    onPressed: () {},
    isExtended: true,
    icon: Icon(Icons.refresh),
    label: Text('刷新曲库'),
  );

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('MusicSources'));
  }
}
