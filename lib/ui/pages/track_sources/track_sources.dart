import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/data/providers/drawer_provider.dart';
import 'package:linglun/ui/utils/show_snack_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import 'package:linglun/data/providers/tracks_provider.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/utils/get_platform_music_path.dart';
import 'package:linglun/ui/widgets/reveal_icon.dart';
import 'package:linglun/ui/pages/track_sources/utils/show_scanning_dialog.dart';

class TrackSources extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TrackSources> createState() => _TrackSourcesState();
}

class _TrackSourcesState extends ConsumerState<TrackSources> {
  ({String? path, bool ticked}) platformPath = (path: null, ticked: false);

  Future<void> getPlatformPath() async {
    String? path = await getPlatformMusicPath();
    if (context.mounted && path != null) {
      setState(() => platformPath = (path: path, ticked: true));
    }
  }

  Map<String, bool> userPaths = {};

  @override
  void initState() {
    super.initState();
    getPlatformPath();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('歌曲来源'),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          children: [
            ListTile(
              minTileHeight: 0,
              minVerticalPadding: 0,
              title: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '系统媒体库',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withAlpha(180),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            CheckboxListTile(
              secondary: const Icon(Icons.folder_special),
              title: const Text('XDG 音乐目录'),
              subtitle: platformPath.path == null
                  ? null
                  : Text(platformPath.path!),
              value: platformPath.ticked,
              onChanged: (value) => setState(
                () => platformPath = (
                  path: platformPath.path,
                  ticked: value ?? false,
                ),
              ),
              enabled: platformPath.path != null,
            ),
            ListTile(
              minTileHeight: 0,
              minVerticalPadding: 0,
              title: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Text(
                  '自定义文件夹',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withAlpha(180),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('添加文件夹'),
              onTap: () async {
                String? path = await FilePicker.getDirectoryPath();
                if (path == null) {
                  if (context.mounted) {
                    showSnackBar(context, Icons.warning, '未选择任何文件夹');
                  }
                  return;
                }
                setState(() => userPaths.addAll({path: true}));
              },
            ),
            ...userPaths.keys.map(
              (path) => Dismissible(
                key: Key(path),
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.delete_forever,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => setState(() => userPaths.remove(path)),
                child: CheckboxListTile(
                  secondary: const Icon(Icons.folder),
                  title: Text(path),
                  value: userPaths[path],
                  onChanged: (value) {
                    setState(() {
                      userPaths[path] = value ?? false;
                      // userPaths.addAll({path: value ?? false});
                    });
                  },
                  enabled: userPaths[path] != null,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final List<TrackInfo>? tracks = await showScanningDialog(context, {
            if (platformPath.ticked && platformPath.path != null)
              platformPath.path!,
            ...userPaths.keys.where((element) => userPaths[element] ?? false),
          }, []);
          ref.read(tracksProvider.notifier).update(tracks);
        },
        isExtended: true,
        icon: const Icon(Icons.refresh),
        label: const Text('刷新曲库'),
      ),
    );
  }
}
