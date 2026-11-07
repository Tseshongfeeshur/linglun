import 'package:linglun/data/models/music_info_model.dart';
import 'package:linglun/ui/pages/music_lib/music_sort.dart';
import 'package:linglun/ui/pages/widgets/list_page_actions.dart';

List<MusicInfo> sortMusicList(List<MusicInfo> list, SortConfig sortConfig) {
  final result = [...list];
  switch (sortConfig.method) {
    case MusicSort.titleInLatin:
      result.sort((a, b) => a.titleInLatin.compareTo(b.titleInLatin));
    case MusicSort.artistsInLatin:
      result.sort((a, b) => a.artistsInLatin.compareTo(b.artistsInLatin));
    case MusicSort.albumInLatin:
      result.sort((a, b) => a.albumInLatin.compareTo(b.albumInLatin));

    case MusicSort.path:
      result.sort((a, b) => a.path.compareTo(b.path));

    case MusicSort.sizeBytes:
      result.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    case MusicSort.durationMs:
      result.sort((a, b) => a.durationMs.compareTo(b.durationMs));
    case MusicSort.playCount:
      result.sort((a, b) => a.playCount.compareTo(b.playCount));
    case MusicSort.addTime:
      result.sort((a, b) => a.addTime.compareTo(b.addTime));
    case MusicSort.editTime:
      result.sort((a, b) => a.editTime.compareTo(b.editTime));
  }

  return sortConfig.descending ? result.reversed.toList() : result;
}
