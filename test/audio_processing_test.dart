import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/domain/audio_processing.dart';

void main() {
  test('音频设置可以序列化并恢复', () {
    final original = AudioProcessingSettings(
      normalizationEnabled: false,
      equalizerEnabled: true,
      preampDb: -3,
      equalizerBands: [
        const EqualizerBand(frequencyHz: 1000, gainDb: 4, q: 1.2),
      ],
      bass: const BassEnhancementSettings(
        enabled: true,
        amountDb: 5,
        cutoffHz: 120,
        harmonics: .5,
      ),
      spatial: const SpatialSettings(mode: SpatialMode.crossfeed, strength: .6),
      limiterEnabled: true,
      outputCeilingDb: -2,
    );

    final restored = AudioProcessingSettings.decode(original.encode());

    expect(restored.normalizationEnabled, isFalse);
    expect(restored.equalizerEnabled, isTrue);
    expect(restored.preampDb, -3);
    expect(restored.equalizerBands.single.frequencyHz, 1000);
    expect(restored.equalizerBands.single.gainDb, 4);
    expect(restored.bass.cutoffHz, 120);
    expect(restored.spatial.mode, SpatialMode.crossfeed);
    expect(restored.outputCeilingDb, -2);
  });

  test('默认设置生成安全限幅滤镜', () {
    final graph = const MpvFilterGraphBuilder().build(
      AudioProcessingSettings(),
    );

    expect(graph, contains('lavfi=['));
    expect(graph, contains('alimiter='));
  });

  test('负分贝输出上限转换为小于 1 的线性限幅值', () {
    final graph = const MpvFilterGraphBuilder().build(
      AudioProcessingSettings(outputCeilingDb: -6),
    );

    expect(graph, contains('alimiter=limit=0.5012'));
  });

  test('EQ、Bass 和 Crossfeed 按顺序生成滤镜链', () {
    final settings = AudioProcessingSettings(
      equalizerEnabled: true,
      equalizerBands: [const EqualizerBand(frequencyHz: 1000, gainDb: 3, q: 1)],
      bass: const BassEnhancementSettings(enabled: true),
      spatial: const SpatialSettings(mode: SpatialMode.crossfeed),
    );

    final graph = const MpvFilterGraphBuilder().build(settings)!;

    expect(graph.indexOf('equalizer='), lessThan(graph.indexOf('bass=')));
    expect(graph.indexOf('bass='), lessThan(graph.indexOf('crossfeed=')));
    expect(graph.indexOf('crossfeed='), lessThan(graph.indexOf('alimiter=')));
  });
}
