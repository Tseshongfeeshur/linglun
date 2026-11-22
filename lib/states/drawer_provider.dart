import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/drawer_state.dart';
import 'package:linglun/data/models/window_layout.dart';

/// 抽屉展开状态：桌面默认展开，手机/平板默认收起（重启后回到默认，不持久化）。
class _DrawerNotifier extends Notifier<DrawerState> {
  @override
  DrawerState build() {
    return DrawerState(
      extended: {
        WindowLayout.phone: false,
        WindowLayout.tablet: false,
        WindowLayout.desktop: true,
      },
    );
  }

  void switchExtendingAt(WindowLayout layout, {bool? target}) {
    // 目标状态与当前相同时不生成新 DrawerState，避免频繁通知
    if (state.extendedAt(layout) == target) return;
    state = state.switchExtendingAt(layout, target: target);
  }
}

final drawerProvider = NotifierProvider<_DrawerNotifier, DrawerState>(
  _DrawerNotifier.new,
);
