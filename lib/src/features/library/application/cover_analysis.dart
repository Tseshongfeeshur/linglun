import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:material_color_utilities/material_color_utilities.dart';

import '../../player/domain/visual_analysis.dart';

const _sampleSize = 64;
const _edgeMargin = 3;

/// 负责在扫描阶段生成播放页所需的封面颜色数据。
class CoverAnalysis {
  const CoverAnalysis({required this.primaryColor, required this.palette});

  final int primaryColor;
  final FluidPalette palette;
}

CoverAnalysis? analyzeCover(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null || decoded.width == 0 || decoded.height == 0) return null;

  final scale = math.min(
    1.0,
    _sampleSize / math.max(decoded.width, decoded.height),
  );
  final sampled = scale == 1
      ? decoded
      : image.copyResize(
          decoded,
          width: math.max(1, (decoded.width * scale).round()),
          height: math.max(1, (decoded.height * scale).round()),
          interpolation: image.Interpolation.average,
        );

  final histogram = <int, _ColorBucket>{};
  for (final pixel in sampled) {
    if (pixel.a < 16) continue;
    if (pixel.x < _edgeMargin ||
        pixel.y < _edgeMargin ||
        pixel.x >= sampled.width - _edgeMargin ||
        pixel.y >= sampled.height - _edgeMargin) {
      continue;
    }
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    final maxChannel = math.max(r, math.max(g, b));
    final minChannel = math.min(r, math.min(g, b));
    final chroma = maxChannel - minChannel;
    final key = ((r ~/ 16) << 8) | ((g ~/ 16) << 4) | (b ~/ 16);
    final weight = _sampleWeight(
      pixel.x,
      pixel.y,
      sampled.width,
      sampled.height,
    );
    final bucket = histogram.putIfAbsent(key, () => _ColorBucket(r, g, b));
    bucket.count += weight;
    bucket.chroma = math.max(bucket.chroma, chroma);
  }
  if (histogram.isEmpty) return null;

  final totalPopulation = histogram.values.fold<double>(
    0,
    (sum, bucket) => sum + bucket.count,
  );
  final colorfulPopulation = histogram.values
      .where((bucket) => _hctFor(bucket).chroma >= 8)
      .fold<double>(0, (sum, bucket) => sum + bucket.count);
  final colorfulEnough =
      totalPopulation > 0 && colorfulPopulation / totalPopulation >= .12;
  final candidates =
      histogram.values.where((bucket) {
        final hct = _hctFor(bucket);
        return !colorfulEnough ||
            (hct.chroma >= 8 && hct.tone >= 10 && hct.tone <= 94);
      }).toList()..sort((a, b) {
        final score = _colorScore(
          b,
          histogram.values,
        ).compareTo(_colorScore(a, histogram.values));
        if (score != 0) return score;
        return b.count.compareTo(a.count);
      });
  final primary = candidates.first;
  final selected = <_ColorBucket>[];
  for (final candidate in candidates) {
    if (selected.every((item) => _colorDistance(item, candidate) > 26) ||
        selected.isEmpty) {
      selected.add(candidate);
    }
    if (selected.length == 4) {
      break;
    }
  }
  while (selected.length < 4) {
    selected.add(primary);
  }

  final primaryHct = _hctFor(primary);
  final primaryColor = Hct.from(
    primaryHct.hue,
    primaryHct.chroma.clamp(12, 64),
    primaryHct.tone.clamp(28, 72),
  ).toInt();
  return CoverAnalysis(
    primaryColor: primaryColor,
    palette: FluidPalette(selected.map((item) => _rgb(item.r, item.g, item.b))),
  );
}

double _sampleWeight(int x, int y, int width, int height) {
  final dx = (x - width / 2) / width;
  final dy = (y - height / 2) / height;
  final radius = math.sqrt(dx * dx + dy * dy);
  if (radius < .34) return 3;
  if (radius < .58) return 2;
  return 1;
}

double _colorScore(_ColorBucket color, Iterable<_ColorBucket> all) {
  final maxCount = all.fold<double>(
    0,
    (maximum, candidate) => math.max(maximum, candidate.count),
  );
  final hct = _hctFor(color);
  final chromaScore = (hct.chroma / 52).clamp(0.0, 1.0);
  final toneScore = 1 - ((hct.tone - 58).abs() / 58).clamp(0.0, 1.0);
  final populationScore = maxCount == 0
      ? 0.0
      : math.pow(color.count / maxCount, .72).toDouble();
  return populationScore * .58 + chromaScore * .28 + toneScore * .14;
}

Hct _hctFor(_ColorBucket color) =>
    Hct.fromInt(_argb(color.r, color.g, color.b));

double _colorDistance(_ColorBucket a, _ColorBucket b) {
  final dr = a.r - b.r;
  final dg = a.g - b.g;
  final db = a.b - b.b;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

int _rgb(int r, int g, int b) => (r << 16) | (g << 8) | b;
int _argb(int r, int g, int b) => 0xFF000000 | _rgb(r, g, b);

class _ColorBucket {
  _ColorBucket(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
  double count = 0;
  int chroma = 0;
}
