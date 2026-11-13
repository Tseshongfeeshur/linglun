import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/track_info_model.dart';

class _TracksNotifer extends Notifier<List<TrackInfo>> {
  @override
  List<TrackInfo> build() {
    // TODO: 从数据库获取
    return [];
  }

  void update(List<TrackInfo>? tracks) {
    if (tracks != null) state = tracks;
  }
}

final tracksProvider = NotifierProvider<_TracksNotifer, List<TrackInfo>>(
  _TracksNotifer.new,
);
