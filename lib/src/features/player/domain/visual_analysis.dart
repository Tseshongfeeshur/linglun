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
  });

  final int durationMs;
  final int sampleRate;
  final List<double> values;

  double valueAt(Duration position) {
    if (values.isEmpty || durationMs <= 0) return 0;
    final ratio = (position.inMilliseconds / durationMs).clamp(0.0, 1.0);
    final location = ratio * (values.length - 1);
    final lower = location.floor();
    final upper = location.ceil();
    if (lower == upper) return values[lower];
    final amount = location - lower;
    return values[lower] + (values[upper] - values[lower]) * amount;
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'durationMs': durationMs,
    'sampleRate': sampleRate,
    'values': values,
  };

  String encode() => jsonEncode(toJson());

  factory BeatEnvelope.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('节拍数据格式错误');
    final values = value['values'];
    if (values is! List) throw const FormatException('节拍序列格式错误');
    return BeatEnvelope(
      durationMs: _asInt(value['durationMs']),
      sampleRate: _asInt(value['sampleRate']),
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
