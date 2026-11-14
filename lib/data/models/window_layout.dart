import 'package:material_ui/material_ui.dart';

enum WindowLayout { phone, tablet, desktop }

extension WindowLayoutContext on BuildContext {
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
