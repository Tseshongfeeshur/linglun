import 'dart:typed_data';

import 'package:flutter_taglib/flutter_taglib.dart';

({Uint8List? coverBytes, String? mimeType})? loadCover(String uri) {
  final file = TagLibFile.open(uri);
  if (file == null) {
    return null;
  }

  // TODO: 首次读取后缓存。
  if (file.hasCover) {
    final coverBytes = file.coverData;
    final mimeType = file.coverMimeType;
    return (mimeType: mimeType, coverBytes: coverBytes);
  } else {
    return null;
  }
}
