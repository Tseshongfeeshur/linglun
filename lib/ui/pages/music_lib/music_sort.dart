import 'package:material_ui/material_ui.dart';

enum MusicSort {
  titleInLatin('标题', Icons.title, true),
  artistsInLatin('艺术家', Icons.person, true),
  albumInLatin('专辑', Icons.album, true),

  path('文件路径', Icons.folder_copy, false),

  sizeBytes('文件体积', Icons.storage, false),
  durationMs('时长', Icons.timer, false),
  playCount('播放次数', Icons.play_circle, false),
  addTime('扫描时间', Icons.add, false),
  editTime('编辑时间', Icons.edit, false);

  const MusicSort(this.label, this.icon, this.shouldBeGrouped);

  final String label;
  final IconData icon;
  final bool shouldBeGrouped;
}
