import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/track_info.dart';

/// 全局曲库（含被标记 removed 的曲目）。扫描完成后整体替换。
// TODO: 类名拼写：_TracksNotifer → _TracksNotifier。
class _TracksNotifer extends Notifier<List<TrackInfo>> {
  @override
  List<TrackInfo> build() {
    // TODO: 从数据库获取
    return [];
  }

  // TODO: 参数可空并在内部忽略 null，是为了迁就"弹窗取消时返回 null"的调用方，
  // 把"取消"的判断藏进了这里。更清楚的做法：调用方判断 null，
  // 这里只接收非空列表；方法名也可改成 replaceAll。
  void update(List<TrackInfo>? tracks) {
    if (tracks != null) state = tracks;
  }
}

final tracksProvider = NotifierProvider<_TracksNotifer, List<TrackInfo>>(
  _TracksNotifer.new,
);
