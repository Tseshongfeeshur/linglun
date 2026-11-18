import 'package:path/path.dart' as p;
import 'package:linglun/data/track_scanner/track_scanner.dart';

class ScanState {
  final List<FileDiscovered> discoverResult;
  final List<FileDiscoveredError> discoverErrors;
  final bool discoverFinished;

  final List<TrackParsed> parseUpdates;
  final List<TrackSkipped> parseSkips;
  final List<TrackParsedError> parseErrors;
  final bool parseFinished;

  final String? current;

  new({
    this.discoverResult = const [],
    this.discoverErrors = const [],
    this.discoverFinished = false,

    this.parseUpdates = const [],
    this.parseSkips = const [],
    this.parseErrors = const [],
    this.parseFinished = false,

    this.current,
  });

  ScanState copyWith({
    List<FileDiscovered>? discoverResult,
    List<FileDiscoveredError>? discoverErrors,
    bool? discoverFinished,

    List<TrackParsed>? parseUpdates,
    List<TrackSkipped>? parseSkips,
    List<TrackParsedError>? parseErrors,
    bool? parseFinished,

    String? current,
  }) {
    return ScanState(
      discoverResult: discoverResult ?? this.discoverResult,
      discoverErrors: discoverErrors ?? this.discoverErrors,
      discoverFinished: discoverFinished ?? this.discoverFinished,

      parseUpdates: parseUpdates ?? this.parseUpdates,
      parseSkips: parseSkips ?? this.parseSkips,
      parseErrors: parseErrors ?? this.parseErrors,
      parseFinished: parseFinished ?? this.parseFinished,

      current: current ?? this.current,
    );
  }

  ScanState applyDiscover(DiscoverEvent event) {
    switch (event) {
      case FileDiscovered():
        return copyWith(
          discoverResult: [...discoverResult, event],
          current: event.name,
        );
      case FileDiscoveredError():
        return copyWith(
          discoverErrors: [...discoverErrors, event],
          current: p.basename(event.uri),
        );
      case FileDiscoveredFinish():
        return copyWith(discoverFinished: true);
    }
  }

  ScanState applyParse(ParseEvent event) {
    switch (event) {
      case TrackParsed():
        return copyWith(
          parseUpdates: [...parseUpdates, event],
          current: event.track.fileName,
        );
      case TrackSkipped():
        return copyWith(
          parseSkips: [...parseSkips, event],
          current: event.track.fileName,
        );
      case TrackParsedError():
        return copyWith(
          parseErrors: [...parseErrors, event],
          current: event.file.name,
        );
      case TrackParsedFinish():
        return copyWith(parseFinished: true);
    }
  }
}
