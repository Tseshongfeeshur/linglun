import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/track_scanner.dart';
import 'package:material_ui/material_ui.dart';

Future<List<TrackInfo>?> showScanningDialog(
  BuildContext context,
  List<String> paths,
  List<TrackInfo> existing,
) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) => PopScope(
      canPop: false,
      child: Dialog(
        child: ScanningDialogContent(
          pathsToDiscover: paths,
          existing: existing,
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

class ScanState {
  final List<String> discoverErrors;
  final List<String> scanErrors;
  final bool isCanceled;
  final int scannedCounter;
  final int updatedCounter;
  final int skippedCounter;
  final int discoveredCounter;
  final String? currentScanning;
  final List<TrackInfo>? scanResult;

  const new({
    this.discoverErrors = const [],
    this.scanErrors = const [],
    this.isCanceled = false,
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

  ScanState update(ScanState old, ScanEvent event) {
    switch (event) {
      case TrackScanned():
        return old.copyWith(
          scannedCounter: old.scannedCounter + 1,
          updatedCounter: updatedCounter + 1,
          currentScanning: event.track.path,
        );
      case TrackSkipped():
        return old.copyWith(
          scannedCounter: old.scannedCounter + 1,
          skippedCounter: skippedCounter + 1,
          currentScanning: event.path,
        );
      case TrackScannedError():
        return old.copyWith(
          scannedCounter: old.scannedCounter + 1,
          currentScanning: event.path,
          scanErrors: [...old.scanErrors, '${event.path}: ${event.detail}'],
        );
      case TrackScannedFinish():
        return old.copyWith(scanResult: event.tracks);
    }
  }
}

class ScanningDialogContent extends StatefulWidget {
  final List<String> pathsToDiscover;
  final List<TrackInfo> existing;
  const new({super.key, required this.pathsToDiscover, required this.existing});

  @override
  State<ScanningDialogContent> createState() => _ScanningDialogContentState();
}

class _ScanningDialogContentState extends State<ScanningDialogContent> {
  final TrackScanner trackScanner = TrackScanner();
  ScanState scanState = ScanState();
  bool isCanceled = false;

  Future<void> scan() async {
    final discoverResult = await trackScanner.discover(widget.pathsToDiscover);
    final tracksToScan = discoverResult.paths;
    scanState = scanState.copyWith(discoverErrors: discoverResult.errorPaths);

    if (!mounted) return;
    setState(
      () => scanState = scanState.copyWith(
        discoveredCounter: tracksToScan.length,
      ),
    );

    final scanStream = trackScanner.scan(tracksToScan, widget.existing);
    await for (final ScanEvent event in scanStream) {
      if (scanState.isCanceled) break;
      if (mounted) {
        setState(() {
          scanState = scanState.update(scanState, event);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    scan();
  }

  @override
  void dispose() {
    isCanceled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  scanState.scanResult == null ? '扫描' : '扫描完成',
                  style: TextStyle(fontSize: 24),
                ),
                if (scanState.scanResult == null)
                  Text(
                    '${scanState.scannedCounter}/${scanState.discoveredCounter}',
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
            scanState.scanResult == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: scanState.discoveredCounter > 0
                            ? scanState.scannedCounter /
                                  scanState.discoveredCounter
                            : null,
                      ),
                      SizedBox(height: 4),
                      SizedBox(
                        height: 18,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            scanState.currentScanning ?? '正在发现文件…',
                            style: const TextStyle(fontSize: 14, height: 1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12),

                      ResultInfoLine(
                        icon: Icons.find_in_page,
                        text: '已处理',
                        count: scanState.scannedCounter,
                        help: '扫描器发现并处理的所有曲目，包括跳过的条目和失败的条目',
                      ),
                      ResultInfoLine(
                        icon: Icons.update,
                        text: '已更新',
                        count: scanState.updatedCounter,
                        help: '所有曲目中那些新增或修改过的曲目',
                      ),
                      ResultInfoLine(
                        icon: Icons.skip_next,
                        text: '已跳过',
                        count: scanState.skippedCounter,
                        help: '若在已有曲库中发现路径、大小和修改时间均相同的曲目，我们认为其没有发生变化，因此跳过了扫描。',
                      ),
                      ResultInfoLine(
                        icon: Icons.error,
                        text: '已失败',
                        count:
                            scanState.discoverErrors.length +
                            scanState.scanErrors.length,
                        help: '由于目录不可读等多种原因，扫描失败的目录和文件',
                      ),

                      if (scanState.discoverErrors.isNotEmpty ||
                          scanState.scanErrors.isNotEmpty)
                        SizedBox(height: 4),
                      if (scanState.discoverErrors.isNotEmpty)
                        for (final String path in scanState.discoverErrors)
                          Text(path),
                      if (scanState.scanErrors.isNotEmpty)
                        for (final String detail in scanState.scanErrors)
                          Text(detail),
                    ],
                  ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, scanState.scanResult);
                },
                child: Text(scanState.scanResult == null ? '取消' : '更新曲库'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final int count;
  final String help;

  const new({
    super.key,
    required this.icon,
    required this.text,
    required this.count,
    required this.help,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon),
        SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 16)),
        Spacer(),
        Text('$count 项'),
        SizedBox(width: 6),
        IconButton(
          onPressed: () {},
          tooltip: help,
          icon: Icon(Icons.question_mark),
          iconSize: 16,
        ),
      ],
    );
  }
}
