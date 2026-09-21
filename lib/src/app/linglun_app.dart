import 'package:flutter/material.dart';

import '../features/shell/presentation/app_shell.dart';

/// 伶伦应用根组件，统一配置主题和桌面端的初始页面。
class LinglunApp extends StatelessWidget {
  const LinglunApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF101314);
    const surface = Color(0xFF181C1D);
    const accent = Color(0xFF80CBC4);

    return MaterialApp(
      title: '伶伦',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: Color(0xFFFFB86C),
          surface: surface,
        ),
        cardTheme: const CardThemeData(
          color: surface,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
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
