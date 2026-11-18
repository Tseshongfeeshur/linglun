import 'package:linglun/data/models/simple_tag.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';

abstract class PlatformFileUtils {
  Stream<DiscoverEvent> discover(Set<String> rootUris);
  Future<SimpleTag> parse(FileDiscovered item);
  Future<String?> getUri();
  Future<({String name, String? path})> getPlatformMusicPath();
}
