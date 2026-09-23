import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/application/player_controller.dart';
import 'package:linglun/src/features/player/domain/audio_processing.dart';
import 'package:linglun/src/features/player/domain/track.dart';
import 'package:linglun/src/features/player/presentation/amll_playback_page.dart';

void main() {
  testWidgets('播放页展示解析歌词并可打开队列选择曲目', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'test-1',
      title: '测试歌曲',
      artist: '测试歌手',
      album: '测试专辑',
      duration: const Duration(minutes: 3),
      lyrics: '[00:01.00]第一句歌词\n[00:03.00]第二句歌词',
      lyricsFormat: 'lrc',
    );
    final state = PlayerState(
      queue: [track, demoTracks[1]],
      currentIndex: 0,
      isPlaying: false,
      position: const Duration(seconds: 2),
      audioSettings: AudioProcessingSettings(),
    );
    Track? selectedTrack;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF80CBC4)),
        ),
        home: Scaffold(
          body: AmllPlaybackPage(
            track: track,
            state: state,
            onClose: () {},
            onPrevious: () {},
            onTogglePlay: () {},
            onNext: () {},
            onSeek: (_) {},
            onToggleShuffle: () {},
            onCycleRepeat: () {},
            onPlayTrack: (value) => selectedTrack = value,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('测试歌曲'), findsOneWidget);
    expect(find.text('测试专辑'), findsOneWidget);
    expect(find.text('第二句歌词'), findsOneWidget);
    expect(find.textContaining('[00:'), findsNothing);
    expect(find.byTooltip('上一曲'), findsOneWidget);
    expect(find.byTooltip('播放'), findsOneWidget);

    await tester.tap(find.byTooltip('打开播放队列'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('接下来播放'), findsOneWidget);

    await tester.tap(find.text('远山来信'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(selectedTrack?.id, demoTracks[1].id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄竖屏播放页使用歌词主视图且无布局溢出', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'test-portrait',
      title: '竖屏歌曲',
      artist: '测试歌手',
      album: '竖屏专辑',
      duration: const Duration(minutes: 2),
      lyrics: '[00:00.00]竖屏歌词',
      lyricsFormat: 'lrc',
    );
    final state = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: Duration.zero,
      audioSettings: AudioProcessingSettings(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AmllPlaybackPage(
            track: track,
            state: state,
            onClose: () {},
            onPrevious: () {},
            onTogglePlay: () {},
            onNext: () {},
            onSeek: (_) {},
            onToggleShuffle: () {},
            onCycleRepeat: () {},
            onPlayTrack: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('竖屏歌曲'), findsOneWidget);
    expect(find.text('竖屏歌词'), findsOneWidget);
    expect(find.byTooltip('下一曲'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄窗多行长歌词扩大行距后仍不溢出', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'lyrics-narrow-long',
      title: '长歌词排版',
      artist: '测试歌手',
      album: '测试专辑',
      duration: const Duration(minutes: 1),
      lyrics: List.generate(8, (index) {
        final timestamp = '[00:${index.toString().padLeft(2, '0')}.00]';
        return '$timestamp'
            '这是用于检查窄屏换行与行高的较长中文歌词内容第$index句\n'
            '$timestamp'
            'This is a long translated lyric used to verify that wrapped '
            'translation lines keep their measured row height $index';
      }).join('\n'),
      lyricsFormat: 'lrc',
    );
    final state = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: const Duration(seconds: 4),
      audioSettings: AudioProcessingSettings(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
              boldText: true,
            ),
            child: DefaultTextHeightBehavior(
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              child: Scaffold(
                body: AmllPlaybackPage(
                  track: track,
                  state: state,
                  onClose: () {},
                  onPrevious: () {},
                  onTogglePlay: () {},
                  onNext: () {},
                  onSeek: (_) {},
                  onToggleShuffle: () {},
                  onCycleRepeat: () {},
                  onPlayTrack: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('检查窄屏换行'), findsWidgets);
    expect(find.textContaining('long translated lyric'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('暂停与播放切换不会改变未高亮歌词的缩放目标', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'lyrics-pause-scale',
      title: '状态切换',
      artist: '测试歌手',
      album: '测试专辑',
      duration: const Duration(minutes: 1),
      lyrics: '[00:00.00]当前歌词\n[00:05.00]后续歌词',
      lyricsFormat: 'lrc',
    );
    final pausedState = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: Duration.zero,
      audioSettings: AudioProcessingSettings(),
    );

    Widget buildPage(PlayerState state) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: AmllPlaybackPage(
          track: track,
          state: state,
          onClose: () {},
          onPrevious: () {},
          onTogglePlay: () {},
          onNext: () {},
          onSeek: (_) {},
          onToggleShuffle: () {},
          onCycleRepeat: () {},
          onPlayTrack: (_) {},
        ),
      ),
    );

    final inactiveRow = find.byKey(const ValueKey('lyric-row-5000000-1'));
    final inactiveScale = find.descendant(
      of: inactiveRow,
      matching: find.byType(AnimatedScale),
    );

    await tester.pumpWidget(buildPage(pausedState));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<AnimatedScale>(inactiveScale).scale, .97);

    await tester.pumpWidget(buildPage(pausedState.copyWith(isPlaying: true)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<AnimatedScale>(inactiveScale).scale, .97);

    await tester.pumpWidget(buildPage(pausedState));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<AnimatedScale>(inactiveScale).scale, .97);
    expect(tester.takeException(), isNull);
  });

  testWidgets('歌词默认左对齐并使用紧凑翻译样式', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'lyrics-style',
      title: '样式歌曲',
      artist: '测试歌手',
      album: '样式专辑',
      duration: const Duration(minutes: 3),
      lyrics: '[00:01.00]左对齐主歌词\n[00:01.00]翻译副行',
      lyricsFormat: 'lrc',
    );
    final state = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: Duration.zero,
      audioSettings: AudioProcessingSettings(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AmllPlaybackPage(
            track: track,
            state: state,
            onClose: () {},
            onPrevious: () {},
            onTogglePlay: () {},
            onNext: () {},
            onSeek: (_) {},
            onToggleShuffle: () {},
            onCycleRepeat: () {},
            onPlayTrack: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    final mainLyric = tester.widget<Text>(find.text('左对齐主歌词'));
    expect(mainLyric.textAlign, TextAlign.start);
    expect(mainLyric.style?.fontWeight, FontWeight.w600);
    expect(mainLyric.style?.wordSpacing, 2.5);

    final translation = tester.widget<Text>(find.text('翻译副行'));
    expect(translation.textAlign, TextAlign.start);
    expect(
      translation.style?.fontSize,
      closeTo(mainLyric.style!.fontSize! * .5, .01),
    );
    expect(translation.style?.color?.a, closeTo(77 / 255, .001));
    final rowSize = tester.getSize(
      find.byKey(const ValueKey('lyric-row-1000000-0')),
    );
    expect(rowSize.height, greaterThan(100));
    expect(
      tester
          .widgetList<AnimatedScale>(find.byType(AnimatedScale))
          .any((scale) => scale.filterQuality == null),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('歌词末句仍锚定在视口高度三分之一处', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'lyrics-last-focus',
      title: '末句定位',
      artist: '测试歌手',
      album: '测试专辑',
      duration: const Duration(minutes: 3),
      lyrics: '[00:00.00]第一句\n[00:01.00]第二句\n[00:02.00]末尾歌词',
      lyricsFormat: 'lrc',
    );
    final state = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: const Duration(seconds: 20),
      audioSettings: AudioProcessingSettings(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AmllPlaybackPage(
            track: track,
            state: state,
            onClose: () {},
            onPrevious: () {},
            onTogglePlay: () {},
            onNext: () {},
            onSeek: (_) {},
            onToggleShuffle: () {},
            onCycleRepeat: () {},
            onPlayTrack: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final viewport = tester.getRect(
      find.byKey(const ValueKey('timed-lyrics-list')),
    );
    final lastLine = tester.getRect(
      find.byKey(const ValueKey('lyric-row-2000000-2')),
    );
    expect(lastLine.center.dy, closeTo(viewport.top + viewport.height / 3, 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('七秒以上的歌词间奏显示三点等待动画', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'lyrics-interlude',
      title: '间奏定位',
      artist: '测试歌手',
      album: '测试专辑',
      duration: const Duration(minutes: 1),
      lyrics: '''
<tt xmlns="http://www.w3.org/ns/ttml"><body><div>
  <p begin="0s" end="1s">前一句</p>
  <p begin="10s" end="11s">后一句</p>
</div></body></tt>
''',
      lyricsFormat: 'ttml',
    );
    final state = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: const Duration(seconds: 5),
      audioSettings: AudioProcessingSettings(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AmllPlaybackPage(
            track: track,
            state: state,
            onClose: () {},
            onPrevious: () {},
            onTogglePlay: () {},
            onNext: () {},
            onSeek: (_) {},
            onToggleShuffle: () {},
            onCycleRepeat: () {},
            onPlayTrack: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_InterludeDots',
      ),
      findsOneWidget,
    );
    final previousLine = tester.getRect(
      find.byKey(const ValueKey('lyric-row-0-0')),
    );
    final dots = tester.getRect(find.byKey(const ValueKey('interlude-dots')));
    expect(dots.top, closeTo(previousLine.bottom, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('播放头在自然前奏中打开时三点动画不误用跳转延迟', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'lyrics-intro',
      title: '前奏定位',
      artist: '测试歌手',
      album: '测试专辑',
      duration: const Duration(minutes: 1),
      lyrics: '''
<tt xmlns="http://www.w3.org/ns/ttml"><body><div>
  <p begin="10s" end="11s">第一句</p>
</div></body></tt>
''',
      lyricsFormat: 'ttml',
    );
    final state = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: const Duration(seconds: 1),
      audioSettings: AudioProcessingSettings(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AmllPlaybackPage(
            track: track,
            state: state,
            onClose: () {},
            onPrevious: () {},
            onTogglePlay: () {},
            onNext: () {},
            onSeek: (_) {},
            onToggleShuffle: () {},
            onCycleRepeat: () {},
            onPlayTrack: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final dots = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byKey(const ValueKey('interlude-dots')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(dots.opacity, greaterThan(.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('逐字高亮在整行视觉与布局路径中保持一致', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'lyrics-word-render',
      title: '逐字绘制',
      artist: '测试歌手',
      album: '测试专辑',
      duration: const Duration(minutes: 1),
      lyrics: '<00:00.00>长<00:01.20>词<00:02.40>辉<00:03.60>光',
      lyricsFormat: 'lrc',
    );
    final state = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: const Duration(seconds: 2),
      audioSettings: AudioProcessingSettings(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AmllPlaybackPage(
            track: track,
            state: state,
            onClose: () {},
            onPrevious: () {},
            onTogglePlay: () {},
            onNext: () {},
            onSeek: (_) {},
            onToggleShuffle: () {},
            onCycleRepeat: () {},
            onPlayTrack: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final painter = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(painter, isNotEmpty);
    expect(find.text('长词辉光'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('无说话者标记的对唱背景行继承主唱的右侧布局', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'duet-background',
      title: '对唱样式',
      artist: '测试歌手',
      album: '对唱专辑',
      duration: const Duration(minutes: 3),
      lyrics: '''
<tt xmlns="http://www.w3.org/ns/ttml"><body><div>
  <p begin="0s" end="1s" agent="v1">第一位歌手</p>
  <p begin="2s" end="3s" role="background">背景声部</p>
  <p begin="2s" end="3s" agent="v2">第二位歌手</p>
</div></body></tt>
''',
      lyricsFormat: 'ttml',
    );
    final state = PlayerState(
      queue: [track],
      currentIndex: 0,
      isPlaying: false,
      position: const Duration(seconds: 2),
      audioSettings: AudioProcessingSettings(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AmllPlaybackPage(
            track: track,
            state: state,
            onClose: () {},
            onPrevious: () {},
            onTogglePlay: () {},
            onNext: () {},
            onSeek: (_) {},
            onToggleShuffle: () {},
            onCycleRepeat: () {},
            onPlayTrack: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(tester.widget<Text>(find.text('背景声部')).textAlign, TextAlign.end);
    expect(tester.takeException(), isNull);
  });
}
