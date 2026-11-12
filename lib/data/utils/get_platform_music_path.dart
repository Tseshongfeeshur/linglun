import 'dart:io';

// import 'package:path/path.dart' as p;

Future<String?> getPlatformMusicPath() async {
  if (Platform.isLinux) {
    final result = await Process.run('sh', [
      '-c',
      '. "\$HOME/.config/user-dirs.dirs"; printf "%s" "\$XDG_MUSIC_DIR"',
    ]);

    if (result.exitCode != 0) return null;

    final path = (result.stdout as String).trim();
    return path.isNotEmpty ? path : null;
  } else {
    // TODO: 待实现的跨平台
    return null;
  }
}
