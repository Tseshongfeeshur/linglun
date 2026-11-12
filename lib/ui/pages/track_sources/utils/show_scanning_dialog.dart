import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/track_scanner.dart';
import 'package:material_ui/material_ui.dart';

void showScanningDialog(BuildContext context, List<String> paths) {
  showDialog(
    context: context,
    builder: (BuildContext context) =>
        Dialog(child: ScanningDialogContent(paths: paths)),
  );
}

class ScanningDialogContent extends StatefulWidget {
  final List<String> paths;
  const ScanningDialogContent({super.key, required this.paths});

  @override
  State<ScanningDialogContent> createState() => _ScanningDialogContentState();
}

class _ScanningDialogContentState extends State<ScanningDialogContent> {
  List<String>? errorPaths;
  String? currentPath;
  int scannedCounter = 0, skippedCounter = 0, discovered = 0;
  List<TrackInfo>? scanResult;

  Future<void> scan() async {
    final TrackScanner trackScanner = TrackScanner();
    final result = await trackScanner.discover(widget.paths);
    final tracksToScan = result.paths;

    setState(() {
      discovered = tracksToScan.length;
    });

    errorPaths = result.errorPaths;

    final scanStream = trackScanner.scan(tracksToScan, []);

    await for (final ScanEvent event in scanStream) {
      setState(() {
        switch (event) {
          case TrackScanned():
            scannedCounter++;
            currentPath = event.track.path;
          case TrackSkipped():
            scannedCounter++;
            skippedCounter++;
            currentPath = event.path;
          case TrackScannedError():
            scannedCounter++;
          case TrackScannedFinish():
            scanResult = event.tracks;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    scan();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('扫描', style: TextStyle(fontSize: 24)),
                Text(
                  '$scannedCounter/$discovered',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 24),
            LinearProgressIndicator(
              value: discovered != 0 ? scannedCounter / discovered : null,
            ),
            SizedBox(height: 8),
            Text(
              currentPath ?? '正在发现文件…',
              style: TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis),
              maxLines: 1,
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () {}, child: Text('确定')),
            ),
          ],
        ),
      ),
    );
  }
}
