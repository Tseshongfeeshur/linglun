/// 曲库中最小的可播放单元。
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.coverColor = 0xFF263238,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final int coverColor;
}

const demoTracks = [
  Track(
    id: 'demo-1',
    title: '雾中回声',
    artist: '伶伦 Demo',
    album: '未命名的夜晚',
    duration: Duration(minutes: 4, seconds: 18),
    coverColor: 0xFF315A61,
  ),
  Track(
    id: 'demo-2',
    title: '远山来信',
    artist: '伶伦 Demo',
    album: '未命名的夜晚',
    duration: Duration(minutes: 3, seconds: 42),
    coverColor: 0xFF5F4B62,
  ),
  Track(
    id: 'demo-3',
    title: '月光下的留白',
    artist: '林间回响',
    album: '薄暮',
    duration: Duration(minutes: 5, seconds: 7),
    coverColor: 0xFF806044,
  ),
  Track(
    id: 'demo-4',
    title: '潮汐之后',
    artist: '林间回响',
    album: '薄暮',
    duration: Duration(minutes: 3, seconds: 56),
    coverColor: 0xFF3C536D,
  ),
];
