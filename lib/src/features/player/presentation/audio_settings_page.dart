import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';

class AudioSettingsPage extends ConsumerWidget {
  const AudioSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
      children: [
        Text('音频设置', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          '播放链路会优先使用曲目中的 ReplayGain 信息，在不同录音之间保持更稳定的感知响度。',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 24),
        Card(
          child: SwitchListTile(
            title: const Text('音量均衡'),
            subtitle: const Text('读取 ReplayGain；没有标签时保持原始增益'),
            value: state.normalizationEnabled,
            onChanged: controller.setNormalizationEnabled,
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '当前优先级：曲目增益 > 专辑增益。增益会受到播放器安全范围限制，不提供独立音量滑块。',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ),
      ],
    );
  }
}
