import 'package:linglun/data/track_scanner/models/parse_event.dart';
import 'package:linglun/states/track_scanner/scan_provider.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/track_scanner/models/scan_state.dart';

/// 弹出阻塞式扫描对话框，扫描完成并确认后返回新的完整曲库；取消返回 null。
/// 返回值 = 跳过的旧记录 + 新增/已变化/被标 removed 的记录；
Future<
  ({
    List<TrackParsed> parsed,
    List<TrackSkipped> skipped,
    List<TrackMissed> missed,
  })?
>
showScanningDialog(
  BuildContext context,
  Set<String> uris,
  List<TrackInfo> existing,
) async {
  return await showDialog<
    ({
      List<TrackParsed> parsed,
      List<TrackSkipped> skipped,
      List<TrackMissed> missed,
    })
  >(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                scanState.discoverFinished ? '解析中' : '寻找中',
                style: const TextStyle(fontSize: 24),
              ),
              Text(
                '${scanState.parsedCount}/${scanState.discoverResult.length}',
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
                    ? (scanState.parsedCount) / scanState.discoverResult.length
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

              // 第一项：已更新
              ListTile(
                leading: const Icon(Icons.update),
                trailing: scanState.parseUpdates.isEmpty
                    ? null
                    : const Icon(Icons.keyboard_arrow_right),
                title: Text(
                  // 已更新 = 新增或已变化（不含被标记 removed 的）。
                  '已更新 ${scanState.parseUpdates.length} 项',
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

                  final updated = scanState.parseUpdates.toList();
                  _showDetailDialog(
                    context,
                    '更新明细',
                    updated.map((i) => i.fileName).toList(),
                  );
                },
              ),

              // 第二项：已跳过
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
                    : _showDetailDialog(
                        context,
                        '跳过明细',
                        scanState.parseSkips.map((i) => i.fileName).toList(),
                      ),
              ),

              // 第三项：历史移除
              ListTile(
                leading: const Icon(Icons.remove_circle),
                trailing: scanState.parseMissings.isEmpty
                    ? null
                    : const Icon(Icons.keyboard_arrow_right),
                title: Text(
                  '曾被移除 ${scanState.parseMissings.length} 项',
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
                subtitle: const Text(
                  '曲库中存在条目，但源文件无法加载',
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 2,
                ),
                onTap: () => scanState.parseMissings.isEmpty
                    ? null
                    : _showDetailDialog(
                        context,
                        '移除明细',
                        scanState.parseMissings.map((i) => i.fileName).toList(),
                      ),
              ),

              // 第四项：已失败
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
                    : _showDetailDialog(context, '失败明细', [
                        for (
                          var i = 0;
                          i < scanState.discoverErrors.length;
                          i++
                        )
                          '${scanState.discoverErrors[i].uri}: ${scanState.discoverErrors[i].detail}',
                        for (var i = 0; i < scanState.parseErrors.length; i++)
                          '${scanState.parseErrors[i].file.uri}: ${scanState.parseErrors[i].detail}',
                      ]),
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
                  Navigator.pop(context, (
                    parsed: scanState.parseUpdates,
                    skipped: scanState.parseSkips,
                    missed: scanState.parseMissings,
                  ));
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

void _showDetailDialog(BuildContext context, String title, List<String> lines) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: const TextStyle(fontSize: 24)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lines.length,
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  title: Text(
                    lines[index],
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
                  child: const Text('关闭'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
