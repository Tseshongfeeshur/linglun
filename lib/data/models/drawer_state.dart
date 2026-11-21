import 'package:linglun/data/models/window_layout.dart';

/// 侧边栏（抽屉）的展开状态。按窗口布局分别记录：
/// 手机/平板/桌面的默认展开状态不同，且互不影响。
// TODO: 没有重写 ==/hashCode。Riverpod 靠 == 判断状态是否变化，
// 所以每次 switchExtendingAt 都会产生"不相等"的新对象并通知所有监听者，
// 哪怕展开状态其实没变（见 drawer_provider.dart 与 frame.dart 的 TapRegion）。
class DrawerState {
  // TODO: 这个 Map 对外可变（调用方可以直接 extended[x] = ...），
  // 与"不可变状态"的约定冲突。可用 Map.unmodifiable 包一层，
  // 或者干脆改成三个 bool 字段（布局只有三档）。
  final Map<WindowLayout, bool> extended;

  new({required this.extended});

  bool extendedAt(WindowLayout layout) => extended[layout] ?? false;

  DrawerState switchExtendingAt(WindowLayout layout, {bool? target}) =>
      DrawerState(
        extended: {...extended, layout: target ?? !extendedAt(layout)},
      );
}
