import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';
import '../domain/playback_background.dart';

class PlaybackBackgroundSettingsPage extends ConsumerWidget {
  const PlaybackBackgroundSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      playerControllerProvider.select((state) => state.backgroundSettings),
    );
    final controller = ref.read(playerControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('播放页背景', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          '使用封面颜色驱动的 Isolation 流体背景。提高帧率会增加显卡负载。',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _SettingSlider(
                label: '流动速度',
                description: '流体背景的动画流动速度',
                value: settings.flowSpeed,
                min: .1,
                max: 10,
                divisions: 99,
                valueLabel: settings.flowSpeed.toStringAsFixed(1),
                onChanged: (value) => controller.updateBackgroundSettings(
                  settings.copyWith(flowSpeed: value),
                ),
              ),
              const Divider(height: 1),
              _SettingSlider(
                label: '动画帧率',
                description: '帧率越高越流畅，也越消耗资源',
                value: settings.fps.toDouble(),
                min: 24,
                max: 120,
                divisions: 48,
                valueLabel: '${settings.fps} FPS',
                onChanged: (value) => controller.updateBackgroundSettings(
                  settings.copyWith(fps: (value / 2).round() * 2),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('暂停时冻结'),
                subtitle: const Text('暂停播放时同时停止流体背景动画'),
                value: settings.freezeOnPause,
                onChanged: (value) => controller.updateBackgroundSettings(
                  settings.copyWith(freezeOnPause: value),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('背景跳动'),
                subtitle: const Text('根据扫描时生成的低频节拍数据调制流体'),
                value: settings.beatEnabled,
                onChanged: (value) => controller.updateBackgroundSettings(
                  settings.copyWith(beatEnabled: value),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('跟随封面主色'),
                subtitle: const Text('让全局 Material 主题跟随当前曲目封面'),
                value: settings.followCoverColor,
                onChanged: (value) => controller.updateBackgroundSettings(
                  settings.copyWith(followCoverColor: value),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => controller.updateBackgroundSettings(
              const PlaybackBackgroundSettings(),
            ),
            icon: const Icon(Icons.restart_alt),
            label: const Text('恢复背景默认设置'),
          ),
        ),
      ],
    );
  }
}

class _SettingSlider extends StatelessWidget {
  const _SettingSlider({
    required this.label,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final String description;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(valueLabel, style: const TextStyle(color: Colors.white60)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
