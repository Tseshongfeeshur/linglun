import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';
import '../domain/audio_processing.dart';

class AudioSettingsPage extends ConsumerWidget {
  const AudioSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final settings = state.audioSettings;

    final content = <Widget>[
      Text('音频设置', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text(
        '音频处理在播放链路中完成，不提供独立音量控制。',
        style: TextStyle(color: Colors.white60),
      ),
      const SizedBox(height: 24),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('音量均衡'),
              subtitle: const Text('优先使用曲目 ReplayGain，没有时使用专辑 ReplayGain'),
              value: settings.normalizationEnabled,
              onChanged: (enabled) => controller.updateAudioSettings(
                settings.copyWith(normalizationEnabled: enabled),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('输出限幅'),
              subtitle: Text(
                '峰值上限 ${settings.outputCeilingDb.toStringAsFixed(1)} dBFS',
              ),
              value: settings.limiterEnabled,
              onChanged: (enabled) => controller.updateAudioSettings(
                settings.copyWith(limiterEnabled: enabled),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ExpansionTile(
          title: const Text('参数化均衡器'),
          subtitle: Text(settings.equalizerEnabled ? '已启用' : '未启用'),
          initiallyExpanded: settings.equalizerEnabled,
          trailing: Switch(
            value: settings.equalizerEnabled,
            onChanged: (enabled) => controller.updateAudioSettings(
              settings.copyWith(equalizerEnabled: enabled),
            ),
          ),
          children: [
            const Divider(height: 1),
            _PreampControl(
              value: settings.preampDb,
              onChanged: (value) => controller.updateAudioSettings(
                settings.copyWith(preampDb: value),
              ),
            ),
            for (var index = 0; index < settings.equalizerBands.length; index++)
              _EqualizerBandControl(
                band: settings.equalizerBands[index],
                onChanged: (band) {
                  final bands = [...settings.equalizerBands];
                  bands[index] = band;
                  controller.updateAudioSettings(
                    settings.copyWith(equalizerBands: bands),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ExpansionTile(
          title: const Text('Bass 增强'),
          subtitle: Text(settings.bass.enabled ? '已启用' : '未启用'),
          trailing: Switch(
            value: settings.bass.enabled,
            onChanged: (enabled) => controller.updateAudioSettings(
              settings.copyWith(bass: settings.bass.copyWith(enabled: enabled)),
            ),
          ),
          children: [
            const Divider(height: 1),
            _LabeledSlider(
              label: '增强量',
              value: settings.bass.amountDb,
              min: 0,
              max: 12,
              suffix: ' dB',
              onChanged: (value) => controller.updateAudioSettings(
                settings.copyWith(
                  bass: settings.bass.copyWith(amountDb: value),
                ),
              ),
            ),
            _LabeledSlider(
              label: '截止频率',
              value: settings.bass.cutoffHz,
              min: 40,
              max: 240,
              suffix: ' Hz',
              onChanged: (value) => controller.updateAudioSettings(
                settings.copyWith(
                  bass: settings.bass.copyWith(cutoffHz: value),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ExpansionTile(
          title: const Text('耳机空间感'),
          subtitle: Text(_spatialLabel(settings.spatial.mode)),
          children: [
            const Divider(height: 1),
            ListTile(
              title: const Text('处理模式'),
              trailing: DropdownButton<SpatialMode>(
                value: settings.spatial.mode,
                items: const [
                  DropdownMenuItem(value: SpatialMode.off, child: Text('关闭')),
                  DropdownMenuItem(
                    value: SpatialMode.crossfeed,
                    child: Text('Crossfeed'),
                  ),
                ],
                onChanged: (mode) {
                  if (mode == null) return;
                  controller.updateAudioSettings(
                    settings.copyWith(
                      spatial: settings.spatial.copyWith(mode: mode),
                    ),
                  );
                },
              ),
            ),
            _LabeledSlider(
              label: '处理强度',
              value: settings.spatial.strength,
              min: 0,
              max: 1,
              suffix: '',
              onChanged: (value) => controller.updateAudioSettings(
                settings.copyWith(
                  spatial: settings.spatial.copyWith(strength: value),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'HRTF 和多声道上混将在原生 DSP 后端中接入。',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () =>
              controller.updateAudioSettings(AudioProcessingSettings()),
          icon: const Icon(Icons.restart_alt),
          label: const Text('恢复音频默认设置'),
        ),
      ),
    ];

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
      children: content,
    );
  }

  String _spatialLabel(SpatialMode mode) => switch (mode) {
    SpatialMode.off => '未启用',
    SpatialMode.crossfeed => 'Crossfeed',
    SpatialMode.hrtf => 'HRTF',
  };
}

class _PreampControl extends StatelessWidget {
  const _PreampControl({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledSlider(
      label: '预放大',
      value: value,
      min: -12,
      max: 12,
      suffix: ' dB',
      onChanged: onChanged,
    );
  }
}

class _EqualizerBandControl extends StatelessWidget {
  const _EqualizerBandControl({required this.band, required this.onChanged});

  final EqualizerBand band;
  final ValueChanged<EqualizerBand> onChanged;

  @override
  Widget build(BuildContext context) {
    final frequency = band.frequencyHz >= 1000
        ? '${(band.frequencyHz / 1000).toStringAsFixed(1)}k'
        : band.frequencyHz.toStringAsFixed(0);
    return _LabeledSlider(
      label: frequency,
      value: band.gainDb,
      min: -12,
      max: 12,
      suffix: ' dB',
      onChanged: (value) => onChanged(band.copyWith(gainDb: value)),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          SizedBox(width: 58, child: Text(label)),
          Expanded(
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              '${value.toStringAsFixed(1)}$suffix',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }
}
