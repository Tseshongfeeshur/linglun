import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/main.dart';

void main() {
  testWidgets('曲库首页显示应用名称和示例曲目', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LinglunApp()));

    expect(find.text('伶伦'), findsOneWidget);
    expect(find.text('曲库'), findsOneWidget);
    expect(find.text('雾中回声'), findsOneWidget);
  });
}
