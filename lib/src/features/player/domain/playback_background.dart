import 'dart:convert';

/// 播放页流光背景设置。
class PlaybackBackgroundSettings {
  const PlaybackBackgroundSettings({
    this.flowSpeed = 4,
    this.fps = 30,
    this.freezeOnPause = false,
    this.beatEnabled = false,
    this.followCoverColor = true,
  });

  final double flowSpeed;
  final int fps;
  final bool freezeOnPause;
  final bool beatEnabled;
  final bool followCoverColor;

  PlaybackBackgroundSettings copyWith({
    double? flowSpeed,
    int? fps,
    bool? freezeOnPause,
    bool? beatEnabled,
    bool? followCoverColor,
  }) {
    return PlaybackBackgroundSettings(
      flowSpeed: _clampSpeed(flowSpeed ?? this.flowSpeed),
      fps: _clampFps(fps ?? this.fps),
      freezeOnPause: freezeOnPause ?? this.freezeOnPause,
      beatEnabled: beatEnabled ?? this.beatEnabled,
      followCoverColor: followCoverColor ?? this.followCoverColor,
    );
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'flowSpeed': flowSpeed,
    'fps': fps,
    'freezeOnPause': freezeOnPause,
    'beatEnabled': beatEnabled,
    'followCoverColor': followCoverColor,
  };

  String encode() => jsonEncode(toJson());

  factory PlaybackBackgroundSettings.decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return const PlaybackBackgroundSettings();
      return PlaybackBackgroundSettings(
        flowSpeed: _clampSpeed(_asDouble(decoded['flowSpeed'], 4)),
        fps: _clampFps(_asInt(decoded['fps'], 30)),
        freezeOnPause: decoded['freezeOnPause'] == true,
        beatEnabled: decoded['beatEnabled'] == true,
        followCoverColor: decoded['followCoverColor'] != false,
      );
    } on Object {
      return const PlaybackBackgroundSettings();
    }
  }

  static double _clampSpeed(double value) => value.clamp(.1, 10).toDouble();
  static int _clampFps(int value) => value.clamp(24, 120);

  static double _asDouble(Object? value, double fallback) =>
      value is num ? value.toDouble() : fallback;

  static int _asInt(Object? value, int fallback) =>
      value is num ? value.round() : fallback;
}
