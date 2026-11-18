import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/scan_state.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/utils/platforms/platform_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/android_file_utils.dart';
import 'package:linglun/data/track_scanner/utils/platforms/linux_file_utils.dart';

class _ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() {
    return ScanState();
  }

  Future<void> startScan(
    Set<String> urisToDiscover,
    List<TrackInfo> existing,
  ) async {
    final TrackScanner trackScanner = TrackScanner();

    PlatformFileUtils utils;
    if (Platform.isLinux) {
      utils = LinuxFileUtils();
    } else if (Platform.isAndroid) {
      utils = AndroidFileUtils();
    } else {
      throw 'platform not supported';
    }

    final discoverStream = trackScanner.discover(utils, urisToDiscover);
    await for (final event in discoverStream) {
      if (!ref.mounted) break;
      state = state.applyDiscover(event);
    }

    List<FileDiscovered> tracksToParse = [];
    if (ref.mounted) {
      tracksToParse = state.discoverResult;
    }

    final parseStream = trackScanner.parse(utils, tracksToParse, existing);
    await for (final ParseEvent event in parseStream) {
      if (!ref.mounted) break;
      state = state.applyParse(event);
    }
  }
}

final scanProvider = NotifierProvider.autoDispose<_ScanNotifier, ScanState>(
  _ScanNotifier.new,
);
