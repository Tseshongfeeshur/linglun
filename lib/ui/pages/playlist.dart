import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/ui/widgets/drawer_menu_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Playlist extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: context.layout == WindowLayout.phone
            ? const DrawerMenuButton()
            : null,
        title: const Text('歌单'),
      ),
      // TODO: 页面内容尚未实现（歌单需要先有数据库里的歌单表）。
      body: const Center(child: Text('Playlist')),
    );
  }
}
