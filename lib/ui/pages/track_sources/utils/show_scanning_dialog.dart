import 'dart:math';

import 'package:linglun/data/track_scanner/providers/scan_provider.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/scan_state.dart';

Future<List<TrackInfo>?> showScanningDialog(
  BuildContext context,
  Set<String> paths,
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
  final Set<String> pathsToDiscover;
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
        .read(scanProvider.notifier)
        .startScan(widget.pathsToDiscover, widget.existing);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch<ScanState>(scanProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: scanState.parseFinished
          ? _ContentAtFinnish(scanState: scanState)
          : _ContentAtScanning(scanState: scanState),
    );
  }
}

class _ContentAtScanning extends StatelessWidget {
  const new({required this.scanState});

  final ScanState scanState;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                scanState.discoverFinished ? '解析中' : '寻找中',
                style: const TextStyle(fontSize: 24),
              ),
              Text(
                '${scanState.parseUpdates.length + scanState.parseSkips.length + scanState.parseErrors.length}/${scanState.discoverResult.length}',
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
                value:
                    scanState.discoverFinished &&
                        scanState.discoverResult.isNotEmpty
                    ? (scanState.parseUpdates.length +
                              scanState.parseSkips.length +
                              scanState.parseErrors.length) /
                          scanState.discoverResult.length
                    : null,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 18,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    scanState.current ?? '正在发现文件…',
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
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentAtFinnish extends StatelessWidget {
  const new({required this.scanState});

  final ScanState scanState;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: max(MediaQuery.sizeOf(context).height - 20, 0),
      ),
      child: Column(
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

              ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.update),
                title: Text(
                  '已更新 ${scanState.parseUpdates.length} 项',
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
                subtitle: const Text(
                  '新增或修改过的曲目',
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 2,
                ),
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: max(
                        MediaQuery.sizeOf(context).height - 500,
                        0,
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: scanState.parseUpdates.length,
                      itemBuilder: (context, index) => ListTile(
                        dense: true,
                        title: Text(
                          scanState.parseUpdates[index].track.fileName,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.skip_next),
                title: Text(
                  '已跳过 ${scanState.parseSkips.length} 项',
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
                subtitle: const Text(
                  '和已有曲目路径、大小和修改时间均相同的曲目',
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 2,
                ),
                children: scanState.parseSkips
                    .map(
                      (item) => ListTile(
                        dense: true,
                        title: Text(item.track.fileName),
                      ),
                    )
                    .toList(),
              ),

              ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.error),
                title: Text(
                  '已失败 ${scanState.discoverErrors.length + scanState.parseErrors.length} 项',
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
                subtitle: const Text(
                  '扫描失败的目录和文件',
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 2,
                ),
                children: [
                  ...scanState.discoverErrors.map(
                    (item) => ListTile(
                      dense: true,
                      title: Text('${item.path}: ${item.detail}'),
                    ),
                  ),
                  ...scanState.parseErrors.map(
                    (item) => ListTile(
                      dense: true,
                      title: Text('${item.file.uri}: ${item.detail}'),
                    ),
                  ),
                ],
              ),
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
                  Navigator.pop(context, <TrackInfo>[
                    ...scanState.parseSkips.map((item) => item.track),
                    ...scanState.parseUpdates.map((item) => item.track),
                  ]);
                },
                child: const Text('更新曲库'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
