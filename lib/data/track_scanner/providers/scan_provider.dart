import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/track_scanner/models/scan_state.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';

class _ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() {
    return const ScanState();
  }

  Future<void> startScan(
    List<String> pathsToDiscover,
    List<TrackInfo> existing,
  ) async {
    final TrackScanner trackScanner = TrackScanner();

    final discoverResult = await trackScanner.discover(pathsToDiscover);
    if (!ref.mounted) return;

    final tracksToScan = discoverResult.paths;
    state = state.copyWith(
      discoverErrors: discoverResult.errorPaths,
      discoveredCounter: tracksToScan.length,
    );

    final scanStream = trackScanner.scan(tracksToScan, existing);
    await for (final ScanEvent event in scanStream) {
      if (!ref.mounted) break;
      state = state.apply(event);
    }
  }
}

final scanProvider = NotifierProvider.autoDispose<_ScanNotifier, ScanState>(
  _ScanNotifier.new,
);
