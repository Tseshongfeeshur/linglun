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
          ? _ContentAtFinish(scanState: scanState)
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

class _ContentAtFinish extends StatelessWidget {
  const new({required this.scanState});

  final ScanState scanState;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('扫描完成', style: TextStyle(fontSize: 24)),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // 第一项：已更新
              ListTile(
                leading: const Icon(Icons.update),
                trailing: scanState.parseUpdates.isEmpty
                    ? null
                    : const Icon(Icons.keyboard_arrow_right),
                title: Text(
                  '已更新 ${scanState.parseUpdates.length} 项',
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
                subtitle: const Text(
                  '修改或增删过的曲目',
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 2,
                ),
                onTap: () => scanState.parseUpdates.isEmpty
                    ? null
                    : showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    '更新明细',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                                Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: scanState.parseUpdates.length,
                                    itemBuilder: (context, index) => ListTile(
                                      dense: true,
                                      title: Text(
                                        scanState
                                            .parseUpdates[index]
                                            .track
                                            .fileName,
                                        style: const TextStyle(height: 1.1),
                                      ),
                                      subtitle:
                                          scanState
                                              .parseUpdates[index]
                                              .track
                                              .removed
                                          ? const Text('源文件曾被移除')
                                          : null,
                                      trailing: IconButton(
                                        onPressed: () {
                                          // TODO
                                        },
                                        icon: const Icon(Icons.delete_forever),
                                        tooltip: '移除曲目数据',
                                      ),
                                      minTileHeight: 0,
                                      minVerticalPadding: 4,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('取消'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),

              // 第二项：已跳过（已统一结构）
              ListTile(
                leading: const Icon(Icons.skip_next),
                trailing: scanState.parseSkips.isEmpty
                    ? null
                    : const Icon(Icons.keyboard_arrow_right),
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
                onTap: () => scanState.parseSkips.isEmpty
                    ? null
                    : showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    '跳过明细',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                                Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: scanState.parseSkips.length,
                                    itemBuilder: (context, index) => ListTile(
                                      dense: true,
                                      title: Text(
                                        scanState
                                            .parseSkips[index]
                                            .track
                                            .fileName,
                                        style: const TextStyle(height: 1.1),
                                      ),
                                      minTileHeight: 0,
                                      minVerticalPadding: 4,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('取消'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),

              // 第三项：已失败（已统一结构）
              ListTile(
                leading: const Icon(Icons.error),
                trailing:
                    scanState.discoverErrors.isEmpty &&
                        scanState.parseErrors.isEmpty
                    ? null
                    : const Icon(Icons.keyboard_arrow_right),
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
                onTap: () =>
                    scanState.discoverErrors.isEmpty &&
                        scanState.parseErrors.isEmpty
                    ? null
                    : showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    '失败明细',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                                Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount:
                                        scanState.discoverErrors.length +
                                        scanState.parseErrors.length,
                                    itemBuilder: (context, index) {
                                      if (index <
                                          scanState.discoverErrors.length) {
                                        final item =
                                            scanState.discoverErrors[index];
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            '${item.path}: ${item.detail}',
                                            style: const TextStyle(height: 1.1),
                                          ),
                                        );
                                      } else {
                                        final item =
                                            scanState.parseErrors[index -
                                                scanState
                                                    .discoverErrors
                                                    .length];
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            '${item.file.uri}: ${item.detail}',
                                          ),
                                          minTileHeight: 0,
                                          minVerticalPadding: 4,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('取消'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
