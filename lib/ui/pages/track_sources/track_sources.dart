import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/ui/widgets/drawer_menu_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:linglun/states/tracks_provider.dart';
import 'package:linglun/ui/utils/show_snack_bar.dart';
import 'package:linglun/ui/pages/track_sources/utils/show_scanning_dialog.dart';
import 'package:path/path.dart' as p;

/// 歌曲来源页：勾选扫描哪些目录（系统音乐目录 + 自定义目录），
/// 点右下角按钮开始扫描，结果整体替换全局曲库。
class TrackSources extends ConsumerStatefulWidget {
  final bool? hideDrawerButton;
  const new({super.key, this.hideDrawerButton});

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
    var path = result.path;

    if (context.mounted && path != null) {
      setState(
        () => platformPath = (name: result.name, path: path, ticked: true),
      );
    }
  }

  // 自定义来源：路径/URI → 是否勾选。
  // TODO: 来源列表和勾选状态只在内存里，后续需要接入 Drift。
  Map<String, bool> userUris = {};

  @override
  void initState() {
    super.initState();
    utils = createPlatformFileUtils();
    getPlatformPath();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading:
            (context.layout == WindowLayout.phone &&
                widget.hideDrawerButton != true)
            ? const DrawerMenuButton()
            : null,
        title: const Text('歌曲来源'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
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
                      // 外层 if 已保证 path != null，这里的判空和 enabled 条件恒成立，是死代码。
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
                  var uri = await utils.pickDirectory();
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
                    title: Text(p.basename(uri)),
                    subtitle: Text(utils.getSourceKeyFromUri(uri)),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 弹窗取消时返回 null，tracksProvider.update 会忽略它。
          final tracks = await showScanningDialog(context, {
            if (platformPath.ticked && platformPath.path != null)
              platformPath.path!,
            ...userUris.keys.where((element) => userUris[element] ?? false),
          }, ref.read(tracksProvider));
          if (tracks != null && mounted) {
            ref.read(tracksProvider.notifier).replaceAll(tracks);
          }
        },
        isExtended: true,
        icon: const Icon(Icons.refresh),
        label: const Text('刷新曲库'),
      ),
    );
  }
}
