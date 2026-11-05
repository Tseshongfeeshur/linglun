import 'package:linglun/data/models/music_info_model.dart';
import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_model.dart';

import 'package:linglun/ui/pages/widgets/list_page_actions.dart';

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
  final List<MusicInfo> testlist = [
    MusicInfo(
      title: '爱若琉璃',
      artists: ['周深'],
      album: '爱若琉璃',
      path: '/home/ryan/Music/favorate/爱若琉璃 - 周深.opus',
      sizeBytes: 6309258,
      durationMs: 207360,
      playCount: 18,
      addTime: DateTime(2026, 7, 8, 23, 25),
      editTime: DateTime(2026, 7, 8, 22, 10),
    ),
    MusicInfo(
      title: 'august',
      artists: ['Taylor Swift'],
      album: 'folklore (deluxe version)',
      path: '/home/ryan/Music/favorate/august - Taylor Swift.opus',
      sizeBytes: 8612326,
      durationMs: 261922,
      playCount: 12,
      addTime: DateTime(2026, 7, 8, 23, 27),
      editTime: DateTime(2026, 7, 3, 22, 10),
    ),
    MusicInfo(
      title: 'すずめ feat.十明',
      artists: ['RADWIMPS', '十明'],
      album: 'すずめ feat.十明',
      path: '/home/ryan/Music/favorate/すずめ feat.十明 - RADWIMPS; 十明.opus',
      sizeBytes: 7490068,
      durationMs: 236390,
      playCount: 7,
      addTime: DateTime(2026, 7, 8, 23, 26),
      editTime: DateTime(2026, 7, 5, 22, 10),
    ),
    MusicInfo(
      title: '안녕 hello',
      artists: [''],
      album: '',
      path: '',
      sizeBytes: 7490068,
      durationMs: 236390,
      playCount: 7,
      addTime: DateTime(2026, 7, 8, 23, 26),
      editTime: DateTime(2026, 7, 5, 22, 10),
    ),
  ];

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
      body: ListView(
        children: List.generate(
          testlist.length,
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
            title: Text(testlist[index].title),
            subtitle: Text(testlist[index].titleInLatin),
            onTap: () {},
          )),
        ),
      ),
    );
  }
}
