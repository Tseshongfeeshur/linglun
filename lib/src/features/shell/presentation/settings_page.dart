import 'package:flutter/material.dart';

import '../../player/presentation/audio_settings_page.dart';

/// 应用设置页，音频处理设置统一收纳在这里。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
      children: const [
        Text('设置', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('调整伶伦的播放行为和音频处理方式。'),
        SizedBox(height: 24),
        AudioSettingsPage(embedded: true),
      ],
    );
  }
}
