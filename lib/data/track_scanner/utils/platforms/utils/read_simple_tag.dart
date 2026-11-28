import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/utils/artist_splitter.dart';

String? _readAlbumArtist(dynamic file) {
  for (final entry in file.properties.entries) {
    if (entry.key.toUpperCase() == 'ALBUMARTIST' && entry.value.isNotEmpty) {
      final first = entry.value.first?.trim();
      if (first != null && first.isNotEmpty) {
        return first;
      }
    }
  }
  return null;
}

Future<SimpleTag> readSimpleTag(String uri) async {
  final file = await TagLibFile.openAsync(uri);
  if (file == null) {
    throw 'failed to open file';
  }

  final artists = splitArtists(file.artist);
  SimpleTag? tag;
  try {
    tag = SimpleTag(
      title: file.title.isEmpty ? null : file.title,
      artists: artists,
      album: file.album.isEmpty ? null : file.album,
      // 如果专辑字段空，直接丢弃专辑艺术家；
      // 否则使用文件内专辑艺术家标签，若无则使用首位艺术家。
      albumArtist: file.album.isEmpty
          ? null
          : _readAlbumArtist(file) ??
                (file.album.isEmpty
                    ? null
                    : (artists.isEmpty ? null : artists.first)),
      durationMs: file.duration.inMilliseconds,
    );
  } finally {
    file.close();
  }

  return tag;
}
