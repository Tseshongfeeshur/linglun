import 'package:linglun/data/models/window_layout.dart';
import 'package:material_ui/material_ui.dart';

/// 统一样式的浮动提示条（图标 + 文字）。宽屏时固定 600 宽，手机撑满。
void showSnackBar(BuildContext context, IconData icon, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      width: (context.layout != WindowLayout.phone) ? 400 : null,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      showCloseIcon: true,
      content: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.surface),
          const SizedBox(width: 12),
          Text(message),
        ],
      ),
    ),
  );
}
