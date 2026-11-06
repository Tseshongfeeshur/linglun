import 'package:material_ui/material_ui.dart';

extension WindowInfoUtils on BuildContext {
  /// 当前窗口的逻辑像素尺寸
  Size get windowSize => MediaQuery.sizeOf(this);

  /// 窗口尺寸是否大于 600
  bool get isTablet => windowSize.width >= 600;

  /// 窗口尺寸是否大于 960
  bool get isDesktop => windowSize.width >= 960;
}
