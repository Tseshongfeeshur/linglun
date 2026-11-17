import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/models/drawer_state.dart';
import 'package:linglun/data/models/window_layout.dart';

class _DrawerNotifier extends Notifier<DrawerState> {
  @override
  build() {
    return DrawerState(
      extended: {
        WindowLayout.phone: false,
        WindowLayout.tablet: false,
        WindowLayout.desktop: true,
      },
    );
  }

  void switchExtendingAt(WindowLayout layout, {bool? target}) =>
      state = state.switchExtendingAt(layout, target: target);
}

final drawerProvider = NotifierProvider<_DrawerNotifier, DrawerState>(
  _DrawerNotifier.new,
);
