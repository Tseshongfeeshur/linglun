import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/ui/widgets/drawer_menu_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtistLib extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: context.layout == WindowLayout.phone
            ? const DrawerMenuButton()
            : null,
        title: const Text('艺术家'),
      ),
      // TODO: 页面内容尚未实现。按项目约定，艺术家页是"艺术家实体"的列表（不是歌曲列表）。
      body: const Center(child: Text('ArtistLib')),
    );
  }
}
