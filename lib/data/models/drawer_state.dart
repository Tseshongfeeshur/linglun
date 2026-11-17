import 'package:linglun/data/models/window_layout.dart';

class DrawerState {
  final Map<WindowLayout, bool> extended;

  new({required this.extended});

  bool extendedAt(WindowLayout layout) => extended[layout] ?? false;

  DrawerState switchExtendingAt(WindowLayout layout, {bool? target}) =>
      DrawerState(
        extended: {...extended, layout: target ?? !extendedAt(layout)},
      );
}
