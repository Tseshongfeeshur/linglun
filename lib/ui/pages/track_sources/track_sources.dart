import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/android_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/linux_file_utils.dart';
import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/data/models/drawer_state.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/states/tracks_provider.dart';
import 'package:linglun/states/drawer_provider.dart';
import 'package:linglun/ui/utils/show_snack_bar.dart';
import 'package:linglun/ui/widgets/reveal_icon.dart';
import 'package:linglun/ui/pages/track_sources/utils/show_scanning_dialog.dart';

class TrackSources extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TrackSources> createState() => _TrackSourcesState();
}

class _TrackSourcesState extends ConsumerState<TrackSources> {
  late PlatformFileUtils utils;
  ({String name, String? path, bool ticked}) platformPath = (
    name: '',
    path: null,
    ticked: false,
  );

  Future<void> getPlatformPath() async {
    final result = await utils.getPlatformMusicPath();
    String? path = result.path;

    if (context.mounted && path != null) {
      setState(
        () => platformPath = (name: result.name, path: path, ticked: true),
      );
    }
  }

  Map<String, bool> userUris = {};

  @override
  void initState() {
    super.initState();

    if (Platform.isLinux) {
      utils = LinuxFileUtils();
    } else if (Platform.isAndroid) {
      utils = AndroidFileUtils();
    } else {
      throw 'platform not supported';
    }
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
            if (platformPath.path != null)
              Column(
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
                    title: Text(platformPath.name),
                    subtitle: platformPath.path == null
                        ? null
                        : Text(platformPath.path!),
                    value: platformPath.ticked,
                    onChanged: (value) => setState(
                      () => platformPath = (
                        name: platformPath.name,
                        path: platformPath.path,
                        ticked: value ?? false,
                      ),
                    ),
                    enabled: platformPath.path != null,
                  ),
                ],
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
                String? uri = await utils.getUri();
                if (uri == null) {
                  if (context.mounted) {
                    showSnackBar(context, Icons.warning, '未选择任何文件夹');
                  }
                  return;
                }
                setState(() => userUris.addAll({uri: true}));
              },
            ),
            ...userUris.keys.map(
              (uri) => Dismissible(
                key: Key(uri),
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
                onDismissed: (_) => setState(() => userUris.remove(uri)),
                child: CheckboxListTile(
                  secondary: const Icon(Icons.folder),
                  title: Text(uri),
                  value: userUris[uri],
                  onChanged: (value) {
                    setState(() {
                      userUris[uri] = value ?? false;
                    });
                  },
                  enabled: userUris[uri] != null,
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
            ...userUris.keys.where((element) => userUris[element] ?? false),
          }, ref.read(tracksProvider));
          ref.read(tracksProvider.notifier).update(tracks);
        },
        isExtended: true,
        icon: const Icon(Icons.refresh),
        label: const Text('刷新曲库'),
      ),
    );
  }
}
