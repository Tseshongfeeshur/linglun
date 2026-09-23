import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/main.dart';
import 'package:linglun/src/features/player/application/player_controller.dart';
import 'package:linglun/src/features/player/domain/track.dart';
import 'package:linglun/src/features/player/presentation/floating_player.dart';

void main() {
  testWidgets('曲库首页显示应用名称和示例曲目', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LinglunApp()));

    expect(find.text('伶伦'), findsOneWidget);
    expect(find.text('曲库'), findsNWidgets(2));
    expect(find.text('雾中回声'), findsOneWidget);
    expect(find.byType(FloatingPlayer), findsOneWidget);
  });

  testWidgets('悬停封面后歌词菜单能够展开', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LinglunApp()));
    await tester.pumpAndSettle();

    final playerRect = tester.getRect(find.byType(FloatingPlayer));
    final hoverPosition = Offset(playerRect.left + 60, playerRect.bottom - 60);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: hoverPosition);
    await tester.pump();
    await mouse.moveTo(hoverPosition);
    await tester.pumpAndSettle();

    expect(find.textContaining('雾中回声 -'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });

  testWidgets('拖动进度环只在释放时提交定位', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LinglunApp(),
      ),
    );
    await tester.pumpAndSettle();

    final progressFinder = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ProgressCircle',
    );
    final ringCenter = tester.getRect(progressFinder).center;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: ringCenter);
    await tester.pump();
    await mouse.moveTo(ringCenter);
    await tester.pumpAndSettle();

    final handleStart = ringCenter + const Offset(0, -46);
    final seekTarget = ringCenter + const Offset(46, 0);
    await mouse.moveTo(handleStart);
    await tester.pump();
    await mouse.down(handleStart);
    final slopTarget = handleStart + const Offset(0, 12);
    await mouse.moveTo(slopTarget, timeStamp: const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 16));
    await mouse.moveTo(
      seekTarget,
      timeStamp: const Duration(milliseconds: 100),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(container.read(playerControllerProvider).position, Duration.zero);
    expect(
      (tester.widget(progressFinder) as dynamic).progress,
      closeTo(.25, .05),
    );

    await mouse.up(timeStamp: const Duration(milliseconds: 120));
    await tester.pump();

    expect(
      container.read(playerControllerProvider).position.inMilliseconds,
      closeTo(demoTracks.first.duration.inMilliseconds * .25, 20),
    );
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });
}
