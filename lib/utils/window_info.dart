import 'package:flutter/material.dart';

extension WindowInfo on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isLandscape => screenSize.width > screenSize.height;
}
