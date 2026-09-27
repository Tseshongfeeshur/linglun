import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_typography.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/player/application/player_controller.dart';

/// 伶伦应用根组件，统一配置主题和桌面端的初始页面。
class LinglunApp extends ConsumerWidget {
  const LinglunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const background = Color(0xFF101314);
    final playerState = ref.watch(playerControllerProvider);
    final defaultSeed = const Color(0xFF80CBC4);
    final seed = playerState.backgroundSettings.followCoverColor
        ? Color(playerState.currentTrack.coverColor)
        : defaultSeed;
    final dynamicScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    final scheme = dynamicScheme.copyWith(
      surface: Color.lerp(const Color(0xFF181C1D), dynamicScheme.surface, .35),
      primary: Color.lerp(defaultSeed, dynamicScheme.primary, .82),
    );

    return MaterialApp(
      title: '伶伦',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: linglunFontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: scheme,
        cardTheme: CardThemeData(
          color: scheme.surface,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        sliderTheme: const SliderThemeData(
          trackHeight: 3,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
