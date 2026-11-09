import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/track_info_model.dart';

TextStyle headStyle(BuildContext context) =>
    TextStyle(fontWeight: FontWeight(500));
TextStyle descStyle(BuildContext context) => TextStyle(
  color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
  fontSize: 12,
);

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
                text: '（${track.titleInLatin}）',
                style: descStyle(context),
              ),
              TextSpan(text: '\n艺术家：', style: headStyle(context)),
              TextSpan(text: track.artists?.join(' / ')),
              TextSpan(
                text: '（${track.artistsInLatin}）',
                style: descStyle(context),
              ),
              TextSpan(text: '\n专辑：', style: headStyle(context)),
              TextSpan(text: track.album),
              TextSpan(
                text: '（${track.albumInLatin}）',
                style: descStyle(context),
              ),
              TextSpan(text: '\n路径：', style: headStyle(context)),
              TextSpan(text: track.path),
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
                text: (() {
                  int tmps = (track.durationMs ~/ 1000);
                  int h = tmps ~/ 60 ~/ 60;
                  int m = tmps ~/ 60 % 60;
                  int s = tmps % 60;
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
