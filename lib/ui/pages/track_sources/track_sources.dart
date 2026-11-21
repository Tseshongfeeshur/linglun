import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/android_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/linux_file_utils.dart';
import 'package:linglun/data/models/window_layout.dart';
import 'package:linglun/data/models/drawer_state.dart';
import 'package:linglun/states/tracks_provider.dart';
import 'package:linglun/states/drawer_provider.dart';
import 'package:linglun/ui/utils/show_snack_bar.dart';
import 'package:linglun/ui/widgets/reveal_icon.dart';
import 'package:linglun/ui/pages/track_sources/utils/show_scanning_dialog.dart';

/// 歌曲来源页：勾选扫描哪些目录（系统音乐目录 + 自定义目录），
/// 点右下角按钮开始扫描，结果整体替换全局曲库。
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
    var path = result.path;

    if (context.mounted && path != null) {
      setState(
        () => platformPath = (name: result.name, path: path, ticked: true),
      );
    }
  }

  // 自定义来源：路径/URI → 是否勾选。
  // TODO: 来源列表和勾选状态只在内存里，重启就没了。在接 Drift 之前，
  // 也可先存一份本地配置（JSON/shared_preferences），否则每次启动都要重新选目录。
  Map<String, bool> userUris = {};

  @override
  void initState() {
    super.initState();

    if (Platform.isLinux) {
      utils = LinuxFileUtils();
    } else if (Platform.isAndroid) {
      utils = AndroidFileUtils();
    } else {
      // FIXME: 其他平台（Windows/macOS/iOS 等）在这里直接 throw。Frame 用 IndexedStack，
      // 启动时就会构建所有页面，应用在这些平台上会在启动时直接崩溃。
      // 应降级成"暂不支持"的提示，或实现对应平台。另外平台判断与
      // scan_provider.dart 里重复了一份，建议抽成 createPlatformFileUtils() 工厂。
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
        // 这里是 target: true（总是展开），与 TrackLib 里的"切换"不一致，
        // 抽成共用组件的 TODO 见 track_lib.dart。
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
      // TODO: 宽屏下列表限宽 960 但靠左排布，TrackLib 是用 Align(topCenter) 居中的，
      // 两页不一致。
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
                var uri = await utils.getUri();
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
                  // TODO: Android 上 uri 是 content://...tree/primary%3AMusic 这样的字符串，
                  // 直接显示很难读；应解码后显示成 "primary:Music" 或更友好的名字。
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
          // TODO: 1) 没有勾选任何来源时，现有曲库里的曲目会全部被标成 removed
          //          （parse 末尾把"库里有、这次没发现"的都标 removed），应拦截并提示；
          //       2) await 之后又用了 ref/context，若页面此时已销毁会抛异常，
          //          应先判断 mounted。
          // 弹窗取消时返回 null，tracksProvider.update 会忽略它。
          final tracks = await showScanningDialog(context, {
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
