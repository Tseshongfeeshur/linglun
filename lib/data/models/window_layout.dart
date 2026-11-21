import 'package:material_ui/material_ui.dart';

/// 窗口布局档位，只看窗口宽度（Material 3 的窗口尺寸分档）：
/// < 600 手机；< 840 平板；其余桌面。
// 注意：全项目的断点都应出自这里，不要在别处再写死 600
// （list_page_actions.dart 里目前就有两处，已标 TODO）。
enum WindowLayout { phone, tablet, desktop }

extension WindowLayoutContext on BuildContext {
  /// 当前窗口所属档位。内部用 MediaQuery.sizeOf，所以窗口宽度每变一次
  /// （拖动窗口边缘时是每一帧），调用它的 build 都会重建；
  /// 如果那个 build 很重（如 TrackLib 里的排序+分组），要把重计算挪出 build。
  WindowLayout get layout {
    switch (MediaQuery.sizeOf(this).width) {
      case < 600:
        return WindowLayout.phone;
      case < 840:
        return WindowLayout.tablet;
      default:
        return WindowLayout.desktop;
    }
  }
}
