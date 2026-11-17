import 'package:haudiotagger/haudiotagger.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';

abstract class PlatformFileUtils {
  Stream<DiscoverEvent> discover(Set<String> rootPaths);
  Future<Tag?> parse(FileDiscovered item);
  Future<String?> getUri();
}
