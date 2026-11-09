import 'dart:io';

import 'package:path/path.dart' as p;

Future<String> getPlatformMusicPath() async {
  if (Platform.isLinux) {
    String defaultPath = p.join(
      Platform.environment['HOME'] ?? '/root',
      'Music',
    );
    final result = await Process.run('sh', [
      '-c',
      '. "\$HOME/.config/user-dirs.dirs"; printf "%s" "\$XDG_MUSIC_DIR"',
    ]);

    if (result.exitCode != 0) return defaultPath;

    final path = (result.stdout as String).trim();
    return path.isEmpty ? defaultPath : path;
  } else {
    // TODO: 待实现的跨平台
    return '';
  }
}

Future<int> main() async {
  String path = await getPlatformMusicPath();
  print(path);
  return 0;
}
