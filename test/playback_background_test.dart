import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/domain/playback_background.dart';
import 'package:linglun/src/features/player/domain/visual_analysis.dart';

void main() {
  test('背景设置会限制范围并保持版本化 JSON', () {
    final settings = const PlaybackBackgroundSettings().copyWith(
      flowSpeed: 99,
      fps: 1000,
      beatEnabled: true,
    );

    expect(settings.flowSpeed, 10);
    expect(settings.fps, 120);
    expect(settings.beatEnabled, isTrue);

    final decoded = PlaybackBackgroundSettings.decode(settings.encode());
    expect(decoded.flowSpeed, 10);
    expect(decoded.fps, 120);
    expect(decoded.beatEnabled, isTrue);
  });

  test('损坏的背景设置回退到默认值', () {
    final settings = PlaybackBackgroundSettings.decode('{bad json');
    expect(settings.flowSpeed, 4);
    expect(settings.fps, 30);
  });

  test('节拍序列按播放位置插值', () {
    const envelope = BeatEnvelope(
      durationMs: 1000,
      sampleRate: 2,
      values: [0, 1, 0],
    );

    expect(envelope.valueAt(Duration.zero), 0);
    expect(envelope.valueAt(const Duration(milliseconds: 250)), .5);
    expect(envelope.valueAt(const Duration(milliseconds: 500)), 1);
    expect(envelope.valueAt(const Duration(seconds: 2)), 0);
  });

  test('分析中的节拍序列只覆盖已经计算到的播放区间', () {
    const envelope = BeatEnvelope(
      durationMs: 2000,
      analyzedDurationMs: 500,
      sampleRate: 20,
      values: [0, 1, 0],
    );

    expect(envelope.isComplete, isFalse);
    expect(envelope.valueAt(const Duration(milliseconds: 125)), .5);
    expect(envelope.valueAt(const Duration(milliseconds: 750)), 0);
  });

  test('节拍 JSON 会保存已分析覆盖时长', () {
    final envelope = BeatEnvelope.fromJson({
      'version': 2,
      'durationMs': 1000,
      'analyzedDurationMs': 1000,
      'sampleRate': 20,
      'values': [0, 1],
    });

    expect(envelope.isComplete, isTrue);
    expect(envelope.analyzedDurationMs, 1000);
  });

  test('四色调色板可以往返 JSON', () {
    final palette = FluidPalette([0x102030, 0x405060, 0x708090, 0xA0B0C0]);
    expect(FluidPalette.fromJson(palette.toJson()).colors, palette.colors);
  });
}
