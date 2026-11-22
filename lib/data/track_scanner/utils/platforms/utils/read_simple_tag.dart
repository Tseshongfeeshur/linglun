import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/utils/artist_splitter.dart';

Future<SimpleTag> readSimpleTag(String uri) async {
  final file = await TagLibFile.openAsync(uri);
  if (file == null) {
    throw 'failed to open file';
  }

  SimpleTag? tag;
  try {
    tag = SimpleTag(
      title: file.title.isEmpty ? null : file.title,
      artists: splitArtists(file.artist),
      album: file.album.isEmpty ? null : file.album,
      durationMs: file.duration.inMilliseconds,
    );
  } finally {
    file.close();
  }

  return tag;
}
