import 'package:flutter/material.dart';

void main() {
  runApp(const LinglunApp());
}

/// 伶伦应用的根组件，集中配置应用名称、主题和初始页面。
class LinglunApp extends StatelessWidget {
  const LinglunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '伶伦',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// 项目初始化阶段的占位首页，后续将在此接入音乐库与播放功能。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('伶伦')),
      body: const Center(child: Text('本地音乐播放器')),
    );
  }
}
