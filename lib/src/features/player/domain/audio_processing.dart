import 'dart:convert';
import 'dart:math' as math;

/// 均衡器频段类型。
enum EqualizerBandType { peaking, lowShelf, highShelf }

/// 耳机空间处理模式。
enum SpatialMode { off, crossfeed, hrtf }

extension EqualizerBandTypeJson on EqualizerBandType {
  String get value => name;

  static EqualizerBandType parse(Object? value) {
    return EqualizerBandType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => EqualizerBandType.peaking,
    );
  }
}

extension SpatialModeJson on SpatialMode {
  String get value => name;

  static SpatialMode parse(Object? value) {
    return SpatialMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => SpatialMode.off,
    );
  }
}

/// 一个参数化均衡器频段。
class EqualizerBand {
  const EqualizerBand({
    required this.frequencyHz,
    required this.gainDb,
    required this.q,
    this.type = EqualizerBandType.peaking,
  });

  final double frequencyHz;
  final double gainDb;
  final double q;
  final EqualizerBandType type;

  EqualizerBand copyWith({
    double? frequencyHz,
    double? gainDb,
    double? q,
    EqualizerBandType? type,
  }) {
    return EqualizerBand(
      frequencyHz: frequencyHz ?? this.frequencyHz,
      gainDb: gainDb ?? this.gainDb,
      q: q ?? this.q,
      type: type ?? this.type,
    );
  }

  Map<String, Object> toJson() => {
    'frequencyHz': frequencyHz,
    'gainDb': gainDb,
    'q': q,
    'type': type.value,
  };

  factory EqualizerBand.fromJson(Map<String, Object?> json) {
    return EqualizerBand(
      frequencyHz: _asDouble(json['frequencyHz'], 1000),
      gainDb: _asDouble(json['gainDb'], 0).clamp(-12, 12).toDouble(),
      q: _asDouble(json['q'], 1).clamp(.1, 10).toDouble(),
      type: EqualizerBandTypeJson.parse(json['type']),
    );
  }
}

/// 智能 Bass 增强参数。当前 mpv 后端使用低频增强滤镜，原生后端会复用这些
/// 参数实现动态谐波增强和输出保护。
class BassEnhancementSettings {
  const BassEnhancementSettings({
    this.enabled = false,
    this.amountDb = 3,
    this.cutoffHz = 100,
    this.harmonics = .35,
  });

  final bool enabled;
  final double amountDb;
  final double cutoffHz;
  final double harmonics;

  BassEnhancementSettings copyWith({
    bool? enabled,
    double? amountDb,
    double? cutoffHz,
    double? harmonics,
  }) {
    return BassEnhancementSettings(
      enabled: enabled ?? this.enabled,
      amountDb: amountDb ?? this.amountDb,
      cutoffHz: cutoffHz ?? this.cutoffHz,
      harmonics: harmonics ?? this.harmonics,
    );
  }

  Map<String, Object> toJson() => {
    'enabled': enabled,
    'amountDb': amountDb,
    'cutoffHz': cutoffHz,
    'harmonics': harmonics,
  };

  factory BassEnhancementSettings.fromJson(Map<String, Object?> json) {
    return BassEnhancementSettings(
      enabled: json['enabled'] == true,
      amountDb: _asDouble(json['amountDb'], 3).clamp(0, 12).toDouble(),
      cutoffHz: _asDouble(json['cutoffHz'], 100).clamp(40, 240).toDouble(),
      harmonics: _asDouble(json['harmonics'], .35).clamp(0, 1).toDouble(),
    );
  }
}

/// 耳机空间处理参数。
class SpatialSettings {
  const SpatialSettings({
    this.mode = SpatialMode.off,
    this.strength = .35,
    this.sofaPath,
  });

  final SpatialMode mode;
  final double strength;
  final String? sofaPath;

  bool get enabled => mode != SpatialMode.off;

  SpatialSettings copyWith({
    SpatialMode? mode,
    double? strength,
    String? sofaPath,
  }) {
    return SpatialSettings(
      mode: mode ?? this.mode,
      strength: strength ?? this.strength,
      sofaPath: sofaPath ?? this.sofaPath,
    );
  }

  Map<String, Object?> toJson() => {
    'mode': mode.value,
    'strength': strength,
    'sofaPath': sofaPath,
  };

  factory SpatialSettings.fromJson(Map<String, Object?> json) {
    return SpatialSettings(
      mode: SpatialModeJson.parse(json['mode']),
      strength: _asDouble(json['strength'], .35).clamp(0, 1).toDouble(),
      sofaPath: json['sofaPath']?.toString(),
    );
  }
}

/// 播放链路的全部可持久化音频处理设置。
class AudioProcessingSettings {
  AudioProcessingSettings({
    this.normalizationEnabled = true,
    this.equalizerEnabled = false,
    this.preampDb = 0,
    List<EqualizerBand>? equalizerBands,
    this.bass = const BassEnhancementSettings(),
    this.spatial = const SpatialSettings(),
    this.limiterEnabled = true,
    this.outputCeilingDb = -1,
  }) : equalizerBands = List.unmodifiable(
         equalizerBands ?? defaultEqualizerBands,
       );

  final bool normalizationEnabled;
  final bool equalizerEnabled;
  final double preampDb;
  final List<EqualizerBand> equalizerBands;
  final BassEnhancementSettings bass;
  final SpatialSettings spatial;
  final bool limiterEnabled;
  final double outputCeilingDb;

  static const defaultFrequencies = [
    31.0,
    62.0,
    125.0,
    250.0,
    500.0,
    1000.0,
    2000.0,
    4000.0,
    8000.0,
    16000.0,
  ];

  static final defaultEqualizerBands = [
    for (final frequency in defaultFrequencies)
      EqualizerBand(frequencyHz: frequency, gainDb: 0, q: 1),
  ];

  AudioProcessingSettings copyWith({
    bool? normalizationEnabled,
    bool? equalizerEnabled,
    double? preampDb,
    List<EqualizerBand>? equalizerBands,
    BassEnhancementSettings? bass,
    SpatialSettings? spatial,
    bool? limiterEnabled,
    double? outputCeilingDb,
  }) {
    return AudioProcessingSettings(
      normalizationEnabled: normalizationEnabled ?? this.normalizationEnabled,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      preampDb: preampDb ?? this.preampDb,
      equalizerBands: equalizerBands ?? this.equalizerBands,
      bass: bass ?? this.bass,
      spatial: spatial ?? this.spatial,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      outputCeilingDb: outputCeilingDb ?? this.outputCeilingDb,
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'normalizationEnabled': normalizationEnabled,
    'equalizerEnabled': equalizerEnabled,
    'preampDb': preampDb,
    'equalizerBands': equalizerBands.map((band) => band.toJson()).toList(),
    'bass': bass.toJson(),
    'spatial': spatial.toJson(),
    'limiterEnabled': limiterEnabled,
    'outputCeilingDb': outputCeilingDb,
  };

  String encode() => jsonEncode(toJson());

  factory AudioProcessingSettings.decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return AudioProcessingSettings.fromJson(
          decoded.map((key, item) => MapEntry(key.toString(), item)),
        );
      }
    } on Object {
      // 损坏的设置回退到默认值，不能阻止播放器启动。
    }
    return AudioProcessingSettings();
  }

  factory AudioProcessingSettings.fromJson(Map<String, Object?> json) {
    final rawBands = json['equalizerBands'];
    final bands = rawBands is List
        ? [
            for (final item in rawBands)
              if (item is Map)
                EqualizerBand.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
          ]
        : <EqualizerBand>[];
    final rawBass = json['bass'];
    final rawSpatial = json['spatial'];
    return AudioProcessingSettings(
      normalizationEnabled: json['normalizationEnabled'] != false,
      equalizerEnabled: json['equalizerEnabled'] == true,
      preampDb: _asDouble(json['preampDb'], 0).clamp(-12, 12).toDouble(),
      equalizerBands: bands.isEmpty ? null : bands,
      bass: rawBass is Map
          ? BassEnhancementSettings.fromJson(
              rawBass.map((key, value) => MapEntry(key.toString(), value)),
            )
          : const BassEnhancementSettings(),
      spatial: rawSpatial is Map
          ? SpatialSettings.fromJson(
              rawSpatial.map((key, value) => MapEntry(key.toString(), value)),
            )
          : const SpatialSettings(),
      limiterEnabled: json['limiterEnabled'] != false,
      outputCeilingDb: _asDouble(
        json['outputCeilingDb'],
        -1,
      ).clamp(-6, 0).toDouble(),
    );
  }
}

/// 根据当前设置生成 mpv 的 libavfilter 音频链。
class MpvFilterGraphBuilder {
  const MpvFilterGraphBuilder();

  String? build(AudioProcessingSettings settings) {
    final filters = <String>[];
    if (settings.preampDb.abs() > .01) {
      filters.add('volume=${_format(settings.preampDb)}dB');
    }
    if (settings.equalizerEnabled) {
      for (final band in settings.equalizerBands) {
        if (band.gainDb.abs() < .01) continue;
        filters.add(
          '${_filterName(band.type)}=f=${_format(band.frequencyHz)}'
          ':t=q:w=${_format(band.q)}:g=${_format(band.gainDb)}',
        );
      }
    }
    if (settings.bass.enabled) {
      filters.add(
        'bass=g=${_format(settings.bass.amountDb)}'
        ':f=${_format(settings.bass.cutoffHz)}',
      );
    }
    if (settings.spatial.mode == SpatialMode.crossfeed) {
      filters.add('crossfeed=strength=${_format(settings.spatial.strength)}');
    }
    if (settings.limiterEnabled) {
      final linearLimit = _dbToLinear(settings.outputCeilingDb);
      filters.add('alimiter=limit=${_format(linearLimit)}');
    }
    if (filters.isEmpty) return null;
    return 'lavfi=[${filters.join(',')}]';
  }

  String _filterName(EqualizerBandType type) => switch (type) {
    EqualizerBandType.peaking => 'equalizer',
    EqualizerBandType.lowShelf => 'lowshelf',
    EqualizerBandType.highShelf => 'highshelf',
  };

  double _dbToLinear(double db) => math.pow(10, db / 20).toDouble();

  String _format(double value) => value.toStringAsFixed(4);
}

double _asDouble(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
