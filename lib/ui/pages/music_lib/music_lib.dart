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
  List<MusicInfo> testlist = generateTestMusicList();

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
