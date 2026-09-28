import 'dart:convert';

/// 封面驱动的四颜色流体调色板。
class FluidPalette {
  FluidPalette(Iterable<int> colors)
    : colors = List.unmodifiable(
        colors.map((color) => color & 0x00FFFFFF).take(4).toList(),
      ) {
    if (this.colors.length != 4) {
      throw ArgumentError('流体调色板必须包含四种颜色');
    }
  }

  final List<int> colors;

  int operator [](int index) => colors[index];

  List<int> toJson() => colors;

  factory FluidPalette.fromJson(Object? value) {
    if (value is! List || value.length != 4) {
      throw const FormatException('流体调色板格式错误');
    }
    return FluidPalette(value.map((item) => _asInt(item)));
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.parse(value.toString());
  }
}

/// PCM 分析生成的低频能量序列。
class BeatEnvelope {
  const BeatEnvelope({
    required this.durationMs,
    required this.sampleRate,
    required this.values,
    int? analyzedDurationMs,
  }) : analyzedDurationMs = analyzedDurationMs ?? durationMs;

  final int durationMs;
  final int sampleRate;
  final List<double> values;

  /// 当前包络已经覆盖的音频时长。分析中允许小于歌曲总时长。
  final int analyzedDurationMs;

  bool get isComplete => analyzedDurationMs >= durationMs;

  double valueAt(Duration position) {
    if (values.isEmpty || durationMs <= 0 || analyzedDurationMs <= 0) return 0;
    final positionMs = position.inMilliseconds;
    if (positionMs < 0 || positionMs > analyzedDurationMs) return 0;
    final ratio = (positionMs / analyzedDurationMs).clamp(0.0, 1.0);
    final location = ratio * (values.length - 1);
    final lower = location.floor();
    final upper = location.ceil();
    if (lower == upper) return values[lower];
    final amount = location - lower;
    return values[lower] + (values[upper] - values[lower]) * amount;
  }

  Map<String, Object> toJson() => {
    'version': 2,
    'durationMs': durationMs,
    'analyzedDurationMs': analyzedDurationMs,
    'sampleRate': sampleRate,
    'values': values,
  };

  String encode() => jsonEncode(toJson());

  factory BeatEnvelope.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('节拍数据格式错误');
    final values = value['values'];
    if (values is! List) throw const FormatException('节拍序列格式错误');
    final analyzedDurationMs = value['analyzedDurationMs'];
    if (analyzedDurationMs == null) {
      throw const FormatException('节拍覆盖时长缺失');
    }
    return BeatEnvelope(
      durationMs: _asInt(value['durationMs']),
      sampleRate: _asInt(value['sampleRate']),
      analyzedDurationMs: _asInt(analyzedDurationMs),
      values: [
        for (final item in values) (_asDouble(item)).clamp(0.0, 1.0).toDouble(),
      ],
    );
  }

  static int _asInt(Object? value) =>
      value is int ? value : int.parse(value.toString());

  static double _asDouble(Object? value) =>
      value is num ? value.toDouble() : double.parse(value.toString());
}
