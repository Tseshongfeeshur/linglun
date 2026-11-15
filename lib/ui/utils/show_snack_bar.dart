import 'package:material_ui/material_ui.dart';

void showSnackBar(BuildContext context, IconData icon, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
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
