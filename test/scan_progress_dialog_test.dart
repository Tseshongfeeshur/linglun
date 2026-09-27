import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/library/presentation/scan_progress_dialog.dart';

void main() {
  testWidgets('扫描歌曲弹窗展示当前阶段、文件名和路径', (tester) async {
    const filePath = '/home/music/专辑/第一首歌.flac';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScanProgressDialog(
            path: filePath,
            stage: '提取专辑封面主色',
          ),
        ),
      ),
    );

    expect(find.text('扫描歌曲'), findsOneWidget);
    expect(find.text('提取专辑封面主色'), findsOneWidget);
    expect(find.text('第一首歌.flac'), findsOneWidget);
    expect(find.text(filePath), findsOneWidget);
  });
}
