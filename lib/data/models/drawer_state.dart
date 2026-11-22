import 'package:flutter/foundation.dart';
import 'package:linglun/data/models/window_layout.dart';

/// 侧边栏（抽屉）的展开状态。按窗口布局分别记录：
/// 手机/平板/桌面的默认展开状态不同，且互不影响。
class DrawerState {
  final Map<WindowLayout, bool> extended;

  // 令 extended 在外部不可变。
  new({required Map<WindowLayout, bool> extended})
    : extended = Map.unmodifiable(extended);

  // 重载相等运算符，避免频繁重建。
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawerState && mapEquals(other.extended, extended);
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    extended.entries.map((e) => Object.hash(e.key, e.value)),
  );

  bool extendedAt(WindowLayout layout) => extended[layout] ?? false;

  DrawerState switchExtendingAt(WindowLayout layout, {bool? target}) =>
      DrawerState(
        extended: {...extended, layout: target ?? !extendedAt(layout)},
      );
}
