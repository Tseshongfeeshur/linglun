import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglun/data/utils/string_to_latin.dart';
import 'package:linglun/ui/frame/frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initRomanize();
  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Frame());
  }
}
