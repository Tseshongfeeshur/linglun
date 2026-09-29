import 'dart:math' as math;

/// 保存流光背景的连续时间、相位和低通后的 Pulse。
class PlaybackBackgroundMotion {
  static const _attack = 0.03;
  static const _release = 0.35;
  static const _speedBoost = 4.0;

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

    // 鼓点需要快速建立、缓慢衰减，既保留冲击感又避免相位瞬移。
    final tau = targetPulse > pulse ? _attack : _release;
    final smoothing = 1 - math.exp(-dt / tau);
    pulse += (targetPulse - pulse) * smoothing;
    phase += dt * 0.1 * flowSpeed * (1 + pulse * _speedBoost);
  }
}
