import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../domain/playback_background.dart';
import '../domain/track.dart';

/// Flutter 版 Isolation 流体背景。
class IsolationBackground extends StatefulWidget {
  const IsolationBackground({
    required this.track,
    required this.settings,
    required this.isPlaying,
    required this.position,
    super.key,
  });

  final Track track;
  final PlaybackBackgroundSettings settings;
  final bool isPlaying;
  final Duration position;

  @override
  State<IsolationBackground> createState() => _IsolationBackgroundState();
}

class _IsolationBackgroundState extends State<IsolationBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Duration _lastPaint = Duration.zero;
  double _elapsed = 0;
  FluidPaletteState? _previousPalette;
  FluidPaletteState? _currentPalette;
  DateTime? _paletteChangedAt;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _loadProgram();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant IsolationBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _previousPalette = _currentPalette;
      _currentPalette = _paletteFor(widget.track);
      _paletteChangedAt = DateTime.now();
    }
    _syncTicker();
  }

  Future<void> _loadProgram() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/isolation.frag',
      );
      if (!mounted) return;
      setState(() => _program = program);
    } on Object {
      // Shader 不可用时保留静态四色背景，不能影响播放页其它功能。
    }
  }

  FluidPaletteState _paletteFor(Track track) {
    final palette =
        track.fluidPalette?.colors ?? _fallbackPalette(Color(track.coverColor));
    return FluidPaletteState([
      for (final color in palette)
        [
          ((color >> 16) & 0xFF) / 255,
          ((color >> 8) & 0xFF) / 255,
          (color & 0xFF) / 255,
        ],
    ]);
  }

  List<int> _fallbackPalette(Color color) {
    final hsl = HSLColor.fromColor(color);
    return [
      color.toARGB32() & 0x00FFFFFF,
      hsl
              .withLightness((hsl.lightness + .12).clamp(0.0, 1.0))
              .toColor()
              .toARGB32() &
          0x00FFFFFF,
      hsl
              .withLightness((hsl.lightness * .72).clamp(0.0, 1.0))
              .toColor()
              .toARGB32() &
          0x00FFFFFF,
      hsl
              .withSaturation((hsl.saturation * .72).clamp(0.0, 1.0))
              .toColor()
              .toARGB32() &
          0x00FFFFFF,
    ];
  }

  void _onTick(Duration elapsed) {
    final delta = _lastTick == Duration.zero
        ? Duration.zero
        : elapsed - _lastTick;
    _lastTick = elapsed;
    final frozen = !widget.isPlaying && widget.settings.freezeOnPause;
    if (!frozen) {
      _elapsed +=
          delta.inMicroseconds /
          Duration.microsecondsPerMillisecond *
          widget.settings.flowSpeed;
    }
    final frameInterval = Duration(
      microseconds: (Duration.microsecondsPerSecond / widget.settings.fps)
          .round(),
    );
    if (mounted && elapsed - _lastPaint >= frameInterval) {
      _lastPaint = elapsed;
      setState(() {});
    }
  }

  void _syncTicker() {
    final shouldTick = widget.isPlaying || !widget.settings.freezeOnPause;
    if (shouldTick && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!shouldTick && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _currentPalette ??= _paletteFor(widget.track);
    final transition = _paletteChangedAt == null
        ? 1.0
        : ((DateTime.now().difference(_paletteChangedAt!).inMilliseconds) /
                  1000)
              .clamp(0.0, 1.0);
    final pulse = widget.settings.beatEnabled
        ? widget.track.beatEnvelope?.valueAt(widget.position) ?? 0.0
        : 0.0;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _IsolationPainter(
          program: _program,
          elapsed: _elapsed,
          fps: widget.settings.fps,
          pulse: pulse,
          previousPalette: _previousPalette,
          palette: _currentPalette!,
          paletteProgress: Curves.easeInOut.transform(transition),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class FluidPaletteState {
  FluidPaletteState(this.colors);

  final List<List<double>> colors;
}

class _IsolationPainter extends CustomPainter {
  const _IsolationPainter({
    required this.program,
    required this.elapsed,
    required this.fps,
    required this.pulse,
    required this.previousPalette,
    required this.palette,
    required this.paletteProgress,
  });

  final ui.FragmentProgram? program;
  final double elapsed;
  final int fps;
  final double pulse;
  final FluidPaletteState? previousPalette;
  final FluidPaletteState palette;
  final double paletteProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final fallback = Paint()
      ..color = _colorAt(palette.colors[0])
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, fallback);
    final currentProgram = program;
    if (currentProgram == null || size.isEmpty) return;

    final shader = currentProgram.fragmentShader();
    var uniform = 0;
    shader.setFloat(uniform++, size.width);
    shader.setFloat(uniform++, size.height);
    shader.setFloat(uniform++, elapsed / 1000);
    shader.setFloat(uniform++, pulse);
    shader.setFloat(uniform++, 1 / math.max(1, fps));
    for (var index = 0; index < 4; index++) {
      final color = _interpolatedColor(index);
      shader.setFloat(uniform++, color[0]);
      shader.setFloat(uniform++, color[1]);
      shader.setFloat(uniform++, color[2]);
    }
    shader.setFloat(uniform++, .17);
    shader.setFloat(uniform++, .41);
    shader.setFloat(uniform++, .83);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  List<double> _interpolatedColor(int index) {
    final to = palette.colors[index];
    final from = previousPalette?.colors[index] ?? to;
    return [
      for (var channel = 0; channel < 3; channel++)
        from[channel] + (to[channel] - from[channel]) * paletteProgress,
    ];
  }

  Color _colorAt(List<double> color) => Color.fromARGB(
    255,
    (color[0] * 255).round().clamp(0, 255).toInt(),
    (color[1] * 255).round().clamp(0, 255).toInt(),
    (color[2] * 255).round().clamp(0, 255).toInt(),
  );

  @override
  bool shouldRepaint(_IsolationPainter oldDelegate) =>
      oldDelegate.program != program ||
      oldDelegate.elapsed != elapsed ||
      oldDelegate.fps != fps ||
      oldDelegate.pulse != pulse ||
      oldDelegate.paletteProgress != paletteProgress ||
      oldDelegate.palette != palette;
}
