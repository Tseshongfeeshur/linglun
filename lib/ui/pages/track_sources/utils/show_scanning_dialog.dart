import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/data/track_scanner/track_scanner.dart';
import 'package:linglun/data/track_scanner/models/scan_state.dart';

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

final _scanProvider = NotifierProvider.autoDispose<_ScanNotifier, ScanState>(
  _ScanNotifier.new,
);

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
        child: _ScanningDialogFrame(pathsToDiscover: paths, existing: existing),
      ),
    ),
    barrierDismissible: false,
  );
}

class _ScanningDialogFrame extends ConsumerStatefulWidget {
  final List<String> pathsToDiscover;
  final List<TrackInfo> existing;
  const new({required this.pathsToDiscover, required this.existing});

  @override
  ConsumerState<_ScanningDialogFrame> createState() =>
      _ScanningDialogFrameState();
}

class _ScanningDialogFrameState extends ConsumerState<_ScanningDialogFrame> {
  @override
  void initState() {
    super.initState();
    ref
        .read(_scanProvider.notifier)
        .startScan(widget.pathsToDiscover, widget.existing);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch<ScanState>(_scanProvider);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: scanState.scanResult == null
            ? _ContentAtScanning(scanState: scanState)
            : _ContentAtFinnish(scanState: scanState),
      ),
    );
  }
}

class _ContentAtScanning extends StatelessWidget {
  const new({required this.scanState});

  final ScanState scanState;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('扫描', style: TextStyle(fontSize: 24)),
            Text(
              '${scanState.scannedCounter}/${scanState.discoveredCounter}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: scanState.discoveredCounter > 0
                  ? scanState.scannedCounter / scanState.discoveredCounter
                  : null,
            ),
            const SizedBox(height: 4),
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
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.pop(context, scanState.scanResult);
            },
            child: const Text('取消'),
          ),
        ),
      ],
    );
  }
}

class _ContentAtFinnish extends StatelessWidget {
  const new({required this.scanState});

  final ScanState scanState;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('扫描完成', style: TextStyle(fontSize: 24)),
        Column(
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            _ResultInfoLine(
              icon: Icons.find_in_page,
              text: '已处理',
              count: scanState.scannedCounter,
              help: '扫描器发现并处理的所有曲目，包括跳过的条目和失败的条目',
            ),
            _ResultInfoLine(
              icon: Icons.update,
              text: '已更新',
              count: scanState.updatedCounter,
              help: '所有曲目中那些新增或修改过的曲目',
            ),
            _ResultInfoLine(
              icon: Icons.skip_next,
              text: '已跳过',
              count: scanState.skippedCounter,
              help: '若在已有曲库中发现路径、大小和修改时间均相同的曲目，我们认为其没有发生变化，因此跳过了扫描。',
            ),
            _ResultInfoLine(
              icon: Icons.error,
              text: '已失败',
              count:
                  scanState.discoverErrors.length + scanState.scanErrors.length,
              help: '由于目录不可读等多种原因，扫描失败的目录和文件',
            ),

            if (scanState.discoverErrors.isNotEmpty ||
                scanState.scanErrors.isNotEmpty)
              const SizedBox(height: 4),
            if (scanState.discoverErrors.isNotEmpty)
              for (final String path in scanState.discoverErrors) Text(path),
            if (scanState.scanErrors.isNotEmpty)
              for (final String detail in scanState.scanErrors) Text(detail),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, scanState.scanResult);
              },
              child: const Text('更新曲库'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final int count;
  final String help;

  const new({
    required this.icon,
    required this.text,
    required this.count,
    required this.help,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      // spacing: ,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text('$count 项'),
        const SizedBox(width: 8),
        Tooltip(
          message: help,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: Icon(Icons.question_mark, size: 18),
          ),
        ),
      ],
    );
  }
}
