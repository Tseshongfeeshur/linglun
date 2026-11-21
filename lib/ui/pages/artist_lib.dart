import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/states/drawer_provider.dart';
import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/data/models/drawer_state.dart';
import 'package:linglun/ui/widgets/reveal_icon.dart';

class ArtistLib extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerState = ref.watch<DrawerState>(drawerProvider);
    final layout = context.layout;

    return Scaffold(
      appBar: AppBar(
        leading: layout == WindowLayout.phone
            ? IconButton(
                onPressed: () => ref
                    .read(drawerProvider.notifier)
                    .switchExtendingAt(layout, target: true),
                icon: RevealIcon(
                  isFilled: drawerState.extendedAt(layout),
                  outlineIcon: Icons.menu,
                  filledIcon: Icons.menu_open,
                  outlineIconColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  filledIconColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              )
            : null,
        title: const Text('艺术家'),
      ),
      // TODO: 页面内容尚未实现。按项目约定，艺术家页是"艺术家实体"的列表（不是歌曲列表）。
      body: const Center(child: Text('ArtistLib')),
    );
  }
}
