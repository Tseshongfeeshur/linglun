import 'dart:math' as math;

/// 保存流光背景的连续时间、相位和低通后的 Pulse。
class PlaybackBackgroundMotion {
  double elapsedMilliseconds = 0;
  double phase = 0;
  double pulse = 0;

  void advance(
    Duration delta, {
    required double targetPulse,
    required double flowSpeed,
  }) {
    final dt = (delta.inMicroseconds / Duration.microsecondsPerSecond).clamp(
      0.0,
      0.1,
    );
    elapsedMilliseconds += dt * 1000 * flowSpeed;

    final smoothing = 1 - math.exp(-dt / 0.12);
    pulse += (targetPulse - pulse) * smoothing;
    phase += dt * 0.1 * flowSpeed * (1 + pulse * 0.12);
  }
}
