import 'package:linglun/ui/utils/format_duration.dart';
import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/track_info.dart';

TextStyle _headStyle() => const TextStyle(fontWeight: FontWeight(500));
TextStyle _descStyle(BuildContext context) => TextStyle(
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
              TextSpan(text: '标题：', style: _headStyle()),
              TextSpan(text: track.title),
              TextSpan(
                text: '（${track.titleKey.sort}）',
                style: _descStyle(context),
              ),
              TextSpan(text: '\n艺术家：', style: _headStyle()),
              TextSpan(text: track.artists.join(' / ')),
              TextSpan(
                text: '（${track.artistsKey.sort}）',
                style: _descStyle(context),
              ),
              TextSpan(text: '\n专辑：', style: _headStyle()),
              TextSpan(text: track.album),
              TextSpan(
                text: '（${track.albumKey.sort}）',
                style: _descStyle(context),
              ),
              TextSpan(text: '\n路径：', style: _headStyle()),
              TextSpan(text: track.uri),
              // TODO: sizeBytes 可能是 -1（平台未知），会显示成 "-0.00 MiB"。
              TextSpan(text: '\n文件体积：', style: _headStyle()),
              TextSpan(
                text:
                    '${(track.sizeBytes / 1024 / 1024).toStringAsFixed(2)} MiB',
              ),
              TextSpan(
                text: '（${track.sizeBytes.toString()} B）',
                style: _descStyle(context),
              ),
              TextSpan(text: '\n时长：', style: _headStyle()),
              TextSpan(text: formatDuration(track.durationMs)),
              TextSpan(text: '\n播放次数：', style: _headStyle()),
              TextSpan(text: '${track.playCount.toString()} 次'),
              TextSpan(text: '\n扫描时间：', style: _headStyle()),
              TextSpan(text: track.addTime.toString()),
              TextSpan(text: '\n编辑时间：', style: _headStyle()),
              TextSpan(text: track.editTime.toString()),
            ],
          ),
        ),
      ),
    ),
  ),
);
