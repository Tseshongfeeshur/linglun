import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/drawer_state.dart';
import 'package:linglun/data/models/window_layout.dart';

/// 抽屉展开状态：桌面默认展开，手机/平板默认收起（重启后回到默认，不持久化）。
class _DrawerNotifier extends Notifier<DrawerState> {
  // TODO: build 补上返回类型（DrawerState build()），与 tracks_provider 里保持一致。
  @override
  build() {
    return DrawerState(
      extended: {
        WindowLayout.phone: false,
        WindowLayout.tablet: false,
        WindowLayout.desktop: true,
      },
    );
  }

  // TODO: 目标状态与当前相同时仍会生成新 DrawerState 并通知监听者。
  // Frame 的 TapRegion 在手机/平板上每次点击"抽屉外"都会调用 target:false，
  // 也就是说那两种布局下每次点击屏幕都会让所有 watch 了 drawerProvider 的页面
  // （Frame、TrackLib……）重建，TrackLib 还会重新排序+分组。
  // 修法：这里先判断 extendedAt(layout) == target 就直接 return；
  // 或给 DrawerState 实现 ==；各页面也可以只 select 自己需要的那一位。
  void switchExtendingAt(WindowLayout layout, {bool? target}) =>
      state = state.switchExtendingAt(layout, target: target);
}

final drawerProvider = NotifierProvider<_DrawerNotifier, DrawerState>(
  _DrawerNotifier.new,
);
