import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';

class ScanState {
  final List<String> discoverErrors;
  final List<String> scanErrors;
  final int scannedCounter;
  final int updatedCounter;
  final int skippedCounter;
  final int discoveredCounter;
  final String? currentScanning;
  final List<TrackInfo>? scanResult;

  const new({
    this.discoverErrors = const [],
    this.scanErrors = const [],
    this.scannedCounter = 0,
    this.updatedCounter = 0,
    this.skippedCounter = 0,
    this.discoveredCounter = 0,
    this.currentScanning,
    this.scanResult,
  });

  ScanState copyWith({
    List<String>? discoverErrors,
    List<String>? scanErrors,
    int? scannedCounter,
    int? updatedCounter,
    int? skippedCounter,
    int? discoveredCounter,
    String? currentScanning,
    List<TrackInfo>? scanResult,
  }) {
    return ScanState(
      discoverErrors: discoverErrors ?? this.discoverErrors,
      scanErrors: scanErrors ?? this.scanErrors,
      scannedCounter: scannedCounter ?? this.scannedCounter,
      updatedCounter: updatedCounter ?? this.updatedCounter,
      skippedCounter: skippedCounter ?? this.skippedCounter,
      discoveredCounter: discoveredCounter ?? this.discoveredCounter,
      currentScanning: currentScanning ?? this.currentScanning,
      scanResult: scanResult ?? this.scanResult,
    );
  }

  ScanState apply(ScanEvent event) {
    switch (event) {
      case TrackScanned():
        return copyWith(
          scannedCounter: scannedCounter + 1,
          updatedCounter: updatedCounter + 1,
          currentScanning: event.track.path,
        );
      case TrackSkipped():
        return copyWith(
          scannedCounter: scannedCounter + 1,
          skippedCounter: skippedCounter + 1,
          currentScanning: event.path,
        );
      case TrackScannedError():
        return copyWith(
          scannedCounter: scannedCounter + 1,
          currentScanning: event.path,
          scanErrors: [...scanErrors, '${event.path}: ${event.detail}'],
        );
      case TrackScannedFinish():
        return copyWith(scanResult: event.tracks);
    }
  }
}
