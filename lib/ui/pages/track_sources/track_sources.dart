import 'package:linglun/ui/pages/track_sources/utils/show_scanning_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:file_picker/file_picker.dart';

import 'package:linglun/data/utils/get_platform_music_path.dart';

class TrackSources extends StatefulWidget {
  const TrackSources({super.key});

  @override
  State<TrackSources> createState() => _TrackSourcesState();
}

class _TrackSourcesState extends State<TrackSources> {
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
    return Scaffold(
      appBar: AppBar(title: Text('歌曲来源')),
      body: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 960),
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
              secondary: Icon(Icons.folder_special),
              title: Text('XDG 音乐目录'),
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
              leading: Icon(Icons.add),
              title: Text('添加文件夹'),
              onTap: () async {
                String? path = await FilePicker.getDirectoryPath();
                if (path != null) {
                  setState(() => userPaths.addAll({path: true}));
                }
              },
            ),
            ...userPaths.keys.map(
              (element) => CheckboxListTile(
                secondary: Icon(Icons.folder),
                title: Text(element),
                value: userPaths[element],
                onChanged: (value) {
                  setState(() {
                    userPaths[element] = value ?? false;
                    // userPaths.addAll({path: value ?? false});
                  });
                },
                enabled: userPaths[element] != null,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showScanningDialog(context, [
          if (platformPath.ticked && platformPath.path != null)
            platformPath.path!,
          ...userPaths.keys.where((element) => userPaths[element] ?? false),
        ]),
        isExtended: true,
        icon: Icon(Icons.refresh),
        label: Text('刷新曲库'),
      ),
    );
  }
}
