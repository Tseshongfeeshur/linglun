import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' show MaterialApp, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/main.dart';
import 'package:linglun/src/core/theme/app_typography.dart';
import 'package:linglun/src/features/player/application/player_controller.dart';
import 'package:linglun/src/features/player/domain/track.dart';
import 'package:linglun/src/features/player/presentation/amll_playback_page.dart';
import 'package:linglun/src/features/player/presentation/floating_player.dart';

void main() {
  testWidgets('曲库首页显示导航提示和示例曲目', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LinglunApp()));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.textTheme.bodyMedium?.fontFamily, linglunFontFamily);
    expect(find.byTooltip('曲库'), findsOneWidget);
    expect(find.byTooltip('年度总结'), findsNothing);
    expect(find.text('曲库'), findsOneWidget);
    expect(find.text('雾中回声'), findsOneWidget);
    expect(find.byType(FloatingPlayer), findsOneWidget);
  });

  testWidgets('曲库在窄窗口下不产生横向溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: LinglunApp()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
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
      (widget) => widget.runtimeType.toString() == 'PlaybackProgressCircle',
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

  testWidgets('播放页路由打开后不会响应主页导航点击', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LinglunApp()));
    await tester.pumpAndSettle();

    final progressFinder = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == 'PlaybackProgressCircle',
    );
    await tester.tap(progressFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AmllPlaybackPage), findsOneWidget);

    await tester.tap(find.byTooltip('设置'), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(AmllPlaybackPage), findsOneWidget);

    await tester.tap(find.byTooltip('收起播放页'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AmllPlaybackPage), findsNothing);
    expect(find.text('你的本地音乐，从这里开始。'), findsOneWidget);
  });
}
