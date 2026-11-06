import 'package:linglun/ui/utils/window_info.dart';
import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_model.dart';
import 'package:linglun/ui/pages/widgets/list_page_actions.dart';

import 'package:linglun/data/models/music_info_model.dart';

import 'package:linglun/test/music_list_generator.dart';

class MusicLib extends StatefulWidget implements PageModel {
  const MusicLib({super.key});

  @override
  String get title => '曲库';

  @override
  IconData get icon => Icons.library_music_outlined;

  @override
  IconData get selectedIcon => Icons.library_music;

  @override
  State<MusicLib> createState() => _MusicLibState();
}

class _MusicLibState extends State<MusicLib> {
  List<MusicInfo> musicList = generateTestMusicList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(overflow: TextOverflow.fade),
        ),
        actions: [ListPageActions()],
      ),
      body: Center(
        child: SizedBox(
          width: context.isDesktop ? 960 : null,
          child: ListView(
            children: List.generate(
              musicList.length,
              ((index) => ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                title: Text(
                  musicList[index].title,
                  maxLines: 1,
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                ),
                subtitle: Text(
                  musicList[index].titleInLatin,
                  maxLines: 1,
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                ),
                onTap: () {
                  TextStyle headStyle(BuildContext context) =>
                      TextStyle(fontWeight: FontWeight(500));
                  TextStyle descStyle(BuildContext context) => TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withAlpha(180),
                    fontSize: 12,
                  );

                  showDialog(
                    context: context,
                    builder: ((context) => AlertDialog(
                      title: Text('歌曲信息'),
                      content: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                          ),
                          children: [
                            TextSpan(text: '标题：', style: headStyle(context)),
                            TextSpan(text: musicList[index].title),
                            TextSpan(
                              text: '（${musicList[index].titleInLatin}）',
                              style: descStyle(context),
                            ),
                            TextSpan(text: '\n艺术家：', style: headStyle(context)),
                            TextSpan(
                              text: musicList[index].artists.join(' / '),
                            ),
                            TextSpan(
                              text: '（${musicList[index].artistsInLatin}）',
                              style: descStyle(context),
                            ),
                            TextSpan(text: '\n专辑：', style: headStyle(context)),
                            TextSpan(text: musicList[index].album),
                            TextSpan(
                              text: '（${musicList[index].albumInLatin}）',
                              style: descStyle(context),
                            ),
                            TextSpan(text: '\n路径：', style: headStyle(context)),
                            TextSpan(text: musicList[index].path),
                            TextSpan(
                              text: '\n文件体积：',
                              style: headStyle(context),
                            ),
                            TextSpan(
                              text:
                                  '${(musicList[index].sizeBytes / 1024 / 1024).toStringAsFixed(2)} MiB',
                            ),
                            TextSpan(
                              text:
                                  '（${musicList[index].sizeBytes.toString()} B）',
                              style: descStyle(context),
                            ),
                            TextSpan(text: '\n时长：', style: headStyle(context)),
                            TextSpan(
                              text: (() {
                                int tmps =
                                    (musicList[index].durationMs ~/ 1000);
                                int h = tmps ~/ 60 ~/ 60;
                                int m = tmps ~/ 60 % 60;
                                int s = tmps % 60;
                                return '${h != 0 ? '${h.toString().padLeft(2, '0')}:' : ''}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                              })(),
                            ),
                            TextSpan(
                              text: '\n播放次数：',
                              style: headStyle(context),
                            ),
                            TextSpan(
                              text:
                                  '${musicList[index].playCount.toString()} 次',
                            ),
                            TextSpan(
                              text: '\n扫描时间：',
                              style: headStyle(context),
                            ),
                            TextSpan(text: musicList[index].addTime.toString()),
                            TextSpan(
                              text: '\n编辑时间：',
                              style: headStyle(context),
                            ),
                            TextSpan(
                              text: musicList[index].editTime.toString(),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('好'),
                        ),
                      ],
                    )),
                  );
                },
              )),
            ),
          ),
        ),
      ),
    );
  }
}
