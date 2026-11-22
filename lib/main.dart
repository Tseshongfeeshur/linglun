import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/ui/frame/frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MainApp()));
}

// TODO: 主题（ThemeData / 深浅色）和路由都还没配置：目前靠 Frame 里的
// pageIndex 切页。计划后续接 Go Router，届时由路由驱动页面切换。
class MainApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(), home: const Frame());
  }
}
