import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/application/player_controller.dart';
import 'package:linglun/src/features/player/domain/audio_processing.dart';
import 'package:linglun/src/features/player/domain/track.dart';
import 'package:linglun/src/features/player/presentation/amll_playback_page.dart';

void main() {
  testWidgets('进度条悬停和拖动标签都显示目标主歌词', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final track = Track(
      id: 'seek-label',
      title: '标签测试',
      artist: '测试歌手',
      album: '测试专辑',
      duration: const Duration(minutes: 2),
      lyrics: '[00:00.00]开头歌词\n[01:00.00]目标主歌词\n[01:00.00]Target translation',
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
    await tester.pump(const Duration(milliseconds: 100));

    final slider = find.byType(Slider).first;
    final rect = tester.getRect(slider);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: rect.center);
    await mouse.moveTo(rect.center);
    await tester.pump();

    expect(tester.widget<Slider>(slider).label?.trim(), '目标主歌词');
    expect(tester.widget<Slider>(slider).showValueIndicator, ShowValueIndicator.alwaysVisible);

    await mouse.down(rect.center);
    await tester.pump();
    expect(tester.widget<Slider>(slider).label?.trim(), '目标主歌词');
    await mouse.up();
    await tester.pump();
    expect(tester.widget<Slider>(slider).value, closeTo(60000, 1));
    expect(tester.widget<Slider>(slider).label?.trim(), '目标主歌词');
    await mouse.removePointer();
  });
}
