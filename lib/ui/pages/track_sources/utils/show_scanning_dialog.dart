import 'package:linglun/states/track_scanner/scan_provider.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/scan_state.dart';

/// 弹出阻塞式扫描对话框，扫描完成并确认后返回新的完整曲库；取消返回 null。
/// 返回值 = 跳过的旧记录 + 新增/已变化/被标 removed 的记录；
/// 解析失败的曲目不在其中（见 TrackScanner.parse 里的 FIXME）。
Future<List<TrackInfo>?> showScanningDialog(
  BuildContext context,
  Set<String> uris,
  List<TrackInfo> existing,
) async {
  // TODO: 补上泛型 showDialog<List<TrackInfo>>，现在返回值是 dynamic，
  // 靠隐式转换才通过类型检查。
  return await showDialog(
    context: context,
    builder: (BuildContext context) => PopScope(
      // 禁止返回键/点击外部关闭，只能通过对话框里的按钮退出
      // （代码里调用的 Navigator.pop 不受 canPop 限制）。
      canPop: false,
      child: Dialog(
        child: _ScanningDialogFrame(urisToDiscover: uris, existing: existing),
      ),
    ),
    barrierDismissible: false,
  );
}

class _ScanningDialogFrame extends ConsumerStatefulWidget {
  final Set<String> urisToDiscover;
  final List<TrackInfo> existing;
  const new({required this.urisToDiscover, required this.existing});

  @override
  ConsumerState<_ScanningDialogFrame> createState() =>
      _ScanningDialogFrameState();
}

class _ScanningDialogFrameState extends ConsumerState<_ScanningDialogFrame> {
  @override
  void initState() {
    super.initState();
    // 对话框一出现就开始扫描；对话框关闭 → scanProvider（autoDispose）销毁
    // → 扫描在下一个事件处停止，这就是"取消"。
    ref
        .read(scanProvider.notifier)
        .startScan(widget.urisToDiscover, widget.existing);
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
            // 左：阶段名；右：已处理数/已发现数。
            // 注意：parse 结尾会把"库里有、磁盘上没有"的曲目也作为 TrackParsed 发出，
            // 所以最后一瞬间已处理数可能超过已发现数（随即进入完成页，影响很小）。
            // TODO: "已处理数"（updates+skips+errors 三项相加）这里写了两遍，
            // 在 ScanState 里加一个 parsedCount getter。
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

/// 扫描完成页：三个汇总项（已更新/已跳过/已失败），点开看明细，
/// 底部"更新曲库"把结果返回给调用方。
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

              // TODO: 下面三个明细对话框结构几乎一样（各约 60 行），抽成一个
              // _showDetailDialog(context, title, List<String> lines) 即可。
              // 明细里的按钮文案"取消"也应是"关闭"。
              // 第一项：已更新
              ListTile(
                leading: const Icon(Icons.update),
                trailing: scanState.parseUpdates.isEmpty
                    ? null
                    : const Icon(Icons.keyboard_arrow_right),
                title: Text(
                  // 已更新 = 新增或已变化（不含被标记 removed 的）。
                  // TODO: 被标记 removed 的曲目也会随"更新曲库"一起写回，但界面上没有单独
                  // 展示它们的数量，用户不知道有多少首被标成了"已移除"。
                  '已更新 ${scanState.parseUpdates.where((item) => item.track.removed == false).length} 项',
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
                subtitle: const Text(
                  '修改过或新增的曲目',
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 2,
                ),
                onTap: () {
                  if (scanState.parseUpdates.isEmpty) {
                    return;
                  }

                  final updated = scanState.parseUpdates
                      .where((item) => item.track.removed == false)
                      .toList();
                  showDialog(
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
                                itemCount: scanState.parseUpdates
                                    .where(
                                      (item) => item.track.removed == false,
                                    )
                                    .length,
                                itemBuilder: (context, index) => ListTile(
                                  dense: true,
                                  title: Text(
                                    updated[index].track.fileName,
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
                  );
                },
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
                                            '${item.uri}: ${item.detail}',
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
                  // 新的完整曲库 = 跳过的旧记录 + 新增/已变化/removed 的记录。
                  // 解析失败的曲目不在其中，见 TrackScanner.parse 里的 FIXME。
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
