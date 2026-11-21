import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/track_info.dart';

// TODO: 这两个样式函数是公开的顶层函数，名字很通用；加下划线私有化
// （_headStyle / _descStyle），headStyle 的 context 参数也没用到。
TextStyle headStyle(BuildContext context) =>
    const TextStyle(fontWeight: FontWeight(500));
TextStyle descStyle(BuildContext context) => TextStyle(
  color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
  fontSize: 12,
);

/// 曲目信息面板。目前是调试性质：括号里灰色的是各排序键（sort），
/// 便于核对拉丁化/分组规则。
void showTrackInfoBottomSheet(
  BuildContext context,
  TrackInfo track,
) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  builder: (context) => SingleChildScrollView(
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 18),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
            ),
            children: [
              TextSpan(text: '标题：', style: headStyle(context)),
              TextSpan(text: track.title),
              TextSpan(
                text: '（${track.titleKey.sort}）',
                style: descStyle(context),
              ),
              // 注意：artistsKeys 为空列表时下面的 .first 会抛异常
              // （见 TrackScanner.parse 里的 FIXME）；这里也只显示第一个艺术家的排序键。
              TextSpan(text: '\n艺术家：', style: headStyle(context)),
              TextSpan(text: track.artists?.join(' / ')),
              TextSpan(
                text: '（${track.artistsKeys.first.sort}）',
                style: descStyle(context),
              ),
              TextSpan(text: '\n专辑：', style: headStyle(context)),
              TextSpan(text: track.album),
              TextSpan(
                text: '（${track.albumKey.sort}）',
                style: descStyle(context),
              ),
              TextSpan(text: '\n路径：', style: headStyle(context)),
              TextSpan(text: track.uri),
              // TODO: sizeBytes 可能是 -1（平台未知），会显示成 "-0.00 MiB"。
              TextSpan(text: '\n文件体积：', style: headStyle(context)),
              TextSpan(
                text:
                    '${(track.sizeBytes / 1024 / 1024).toStringAsFixed(2)} MiB',
              ),
              TextSpan(
                text: '（${track.sizeBytes.toString()} B）',
                style: descStyle(context),
              ),
              TextSpan(text: '\n时长：', style: headStyle(context)),
              TextSpan(
                // TODO: 时长格式化抽成公共函数 formatDuration(int ms)，列表项和播放页也会用到。
                text: (() {
                  var tmps = (track.durationMs ~/ 1000);
                  var h = tmps ~/ 60 ~/ 60;
                  var m = tmps ~/ 60 % 60;
                  var s = tmps % 60;
                  return '${h != 0 ? '${h.toString().padLeft(2, '0')}:' : ''}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                })(),
              ),
              TextSpan(text: '\n播放次数：', style: headStyle(context)),
              TextSpan(text: '${track.playCount.toString()} 次'),
              TextSpan(text: '\n扫描时间：', style: headStyle(context)),
              TextSpan(text: track.addTime.toString()),
              TextSpan(text: '\n编辑时间：', style: headStyle(context)),
              TextSpan(text: track.editTime.toString()),
            ],
          ),
        ),
      ),
    ),
  ),
);
