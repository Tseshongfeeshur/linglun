import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'src/app/linglun_app.dart';

// 保留根组件导出，方便测试和后续平台入口复用应用配置。
export 'src/app/linglun_app.dart';

void main() {
  // 在创建播放器前初始化 libmpv 的平台实现。
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: LinglunApp()));
}
