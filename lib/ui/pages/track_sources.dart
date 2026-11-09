import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_model.dart';

class TrackSources extends StatelessWidget implements PageModel {
  const TrackSources({super.key});

  @override
  String get title => '歌曲来源';

  @override
  IconData get icon => Icons.folder_special_outlined;

  @override
  IconData get selectedIcon => Icons.folder_special;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('MusicSources')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        isExtended: true,
        icon: Icon(Icons.refresh),
        label: Text('刷新曲库'),
      ),
    );
  }
}
