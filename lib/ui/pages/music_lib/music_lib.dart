import 'package:linglun/data/utils/sort_music_list.dart';
import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/utils/window_info.dart';
import 'package:linglun/ui/utils/show_music_info_dialog.dart';
import 'package:linglun/ui/frame/page_model.dart';
import 'package:linglun/ui/pages/music_lib/music_sort.dart';
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
  MusicSort sortMethod = MusicSort.titleInLatin;
  bool descending = false;
  List<MusicInfo> musicList = getMusicList();
  List<MusicInfo> get sortedMusicList =>
      sortMusicList(musicList, sortMethod, descending);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(overflow: TextOverflow.fade),
        ),
        actions: [
          ListPageActions(
            sortMethod: sortMethod,
            onSortChanged: (value) => setState(() {
              sortMethod = value;
              descending = false;
            }),
            descending: descending,
            onDescendingChanged: () => setState(() => descending = !descending),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: context.isDesktop ? 960 : null,
          child: MusicListView(sortedMusicList: sortedMusicList),
        ),
      ),
    );
  }
}

class MusicListView extends StatelessWidget {
  const MusicListView({super.key, required this.sortedMusicList});

  final List<MusicInfo> sortedMusicList;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: List.generate(
        sortedMusicList.length,
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
            sortedMusicList[index].title,
            maxLines: 1,
            style: TextStyle(overflow: TextOverflow.ellipsis),
          ),
          subtitle: Text(
            sortedMusicList[index].titleInLatin,
            maxLines: 1,
            style: TextStyle(overflow: TextOverflow.ellipsis),
          ),
          onTap: () {
            showMusicInfoDialog(context, sortedMusicList[index]);
          },
        )),
      ),
    );
  }
}
