import 'package:material_ui/material_ui.dart';

extension WindowInfo on BuildContext {
  /// 当前窗口的逻辑像素尺寸
  Size get screenSize => MediaQuery.sizeOf(this);

  /// 窗口比例是否为横屏
  bool get isLandscape => screenSize.width > screenSize.height;

  /// 窗口尺寸是否为宽屏
  bool get isWideScreen => screenSize.width > 600;
}
