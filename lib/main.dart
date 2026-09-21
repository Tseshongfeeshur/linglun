import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/linglun_app.dart';

// 保留根组件导出，方便测试和后续平台入口复用应用配置。
export 'src/app/linglun_app.dart';

void main() {
  runApp(const ProviderScope(child: LinglunApp()));
}
