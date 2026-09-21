import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/main.dart';

void main() {
  testWidgets('首页显示应用名称与项目定位', (WidgetTester tester) async {
    await tester.pumpWidget(const LinglunApp());

    expect(find.text('伶伦'), findsOneWidget);
    expect(find.text('本地音乐播放器'), findsOneWidget);
  });
}
