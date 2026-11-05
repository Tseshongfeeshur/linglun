import 'package:material_ui/material_ui.dart';

enum MusicSort {
  titleInLatin('标题', Icons.title),
  artistsInLatin('艺术家', Icons.person),
  albumInLatin('专辑', Icons.album),

  path('文件路径', Icons.folder_copy),

  sizeBytes('文件体积', Icons.storage),
  durationMs('时长', Icons.timer),
  playCount('播放次数', Icons.play_circle),
  addTime('扫描时间', Icons.add),
  editTime('编辑时间', Icons.edit);

  const MusicSort(this.label, this.icon);

  final String label;
  final IconData icon;
}
