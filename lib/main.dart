import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/ui/frame/frame.dart';
import 'package:system_theme/system_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载强调色
  SystemTheme.fallbackColor = const Color(0xFF581BFF);
  await SystemTheme.accentColor.load();
  const keyColors = FlexKeyColors(
    useKeyColors: true, // 种子生成
    useSecondary: false, // 关闭双种子，由主种子推导
    useTertiary: false, // 关闭三种子，由主种子推导
  );
  // 根据强调色构造主题
  ThemeData buildLightTheme(Color seed) {
    return FlexThemeData.light(
      colors: FlexSchemeColor(primary: seed, secondary: seed),
      keyColors: keyColors,
      tones: FlexTones.material(Brightness.light),
      useMaterial3: true,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        useMaterial3Typography: true,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  ThemeData buildDarkTheme(Color seed) {
    return FlexThemeData.dark(
      colors: FlexSchemeColor(primary: seed, secondary: seed),
      keyColors: keyColors,
      tones: FlexTones.material(Brightness.dark),
      useMaterial3: true,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        useMaterial3Typography: true,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  // TODO: 计划后续接 Go Router，届时由路由驱动页面切换。
  runApp(
    ProviderScope(
      child: SystemThemeBuilder(
        builder: (context, color) {
          return MaterialApp(
            theme: buildLightTheme(color.accent),
            darkTheme: buildDarkTheme(color.accent),
            themeMode: ThemeMode.system,
            home: const Frame(),
          );
        },
      ),
    ),
  );
}
