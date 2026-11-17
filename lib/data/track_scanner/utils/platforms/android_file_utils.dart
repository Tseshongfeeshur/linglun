import 'package:haudiotagger/haudiotagger.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';

class AndroidFileUtils extends PlatformFileUtils {
  @override
  Stream<DiscoverEvent> discover(Set<String> rootPaths) async* {}

  @override
  Future<Tag?> parse(FileDiscovered item) async {
    return null;
  }
}
