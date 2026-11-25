import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/cover_thumbnail/cover_thumbnail_cache.dart';

final coverCacheProvider = Provider<CoverThumbnailCache>(
  (ref) => CoverThumbnailCache(),
);
