import 'dart:io';

Future<({String name, String? path})> getPlatformMusicPath() async {
  if (Platform.isLinux) {
    final result = await Process.run('sh', [
      '-c',
      '. "\$HOME/.config/user-dirs.dirs"; printf "%s" "\$XDG_MUSIC_DIR"',
    ]);

    if (result.exitCode != 0) return (name: 'XDG 音乐目录', path: null);

    final path = (result.stdout as String).trim();
    return (name: '', path: path.isNotEmpty ? path : null);
  } else if (Platform.isAndroid) {
    return (name: '', path: null);
  } else {
    // TODO: 待实现的跨平台
    return (name: '', path: null);
  }
}
