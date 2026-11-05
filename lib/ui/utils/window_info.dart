import 'package:material_ui/material_ui.dart';

extension WindowInfoUtils on BuildContext {
  /// 当前窗口的逻辑像素尺寸
  Size get windowSize => MediaQuery.sizeOf(this);

  /// 窗口尺寸是否为宽屏
  bool get isWideScreen => windowSize.width >= 600;
}
