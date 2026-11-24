import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/ui/utils/cover_thumbnail_cache.dart';

final coverCacheProvider = Provider<CoverThumbnailCache>(
  (ref) => CoverThumbnailCache(),
);
