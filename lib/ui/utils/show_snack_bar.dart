import 'package:linglun/data/models/window_layout.dart';
import 'package:material_ui/material_ui.dart';

void showSnackBar(BuildContext context, IconData icon, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      width: (context.layout != WindowLayout.phone) ? 600 : null,
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
