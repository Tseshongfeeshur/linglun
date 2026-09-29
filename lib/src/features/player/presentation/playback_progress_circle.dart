import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/track.dart';

const playbackCircleSize = 72.0;
const playbackRingSize = 104.0;

/// 绘制悬浮播放器和播放页揭示动画共用的圆形进度控件。
class PlaybackProgressCircle extends StatelessWidget {
  const PlaybackProgressCircle({
    required this.track,
    required this.progress,
    required this.hovered,
    required this.dragging,
    this.touchMenuExpanded = false,
    this.onOpenPlaybackPage,
    this.bufferProgress,
    super.key,
  });

  final Track track;
  final double progress;
  final bool hovered;
  final bool dragging;
  final bool touchMenuExpanded;
  final VoidCallback? onOpenPlaybackPage;
  final double? bufferProgress;

  @override
  Widget build(BuildContext context) {
    final scale = dragging
        ? .94
        : hovered
        ? 1.08
        : 1.0;
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: playbackRingSize,
        height: playbackRingSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(playbackRingSize),
              painter: _ProgressPainter(
                progress: progress,
                bufferProgress: bufferProgress,
                hovered: hovered,
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
            Container(
              width: playbackCircleSize,
              height: playbackCircleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(hovered ? 105 : 70),
                    blurRadius: hovered ? 32 : 22,
                    spreadRadius: hovered ? 5 : 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: track.coverBytes == null
                    ? ColoredBox(
                        color: Color(track.coverColor),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white70,
                        ),
                      )
                    : Image.memory(track.coverBytes!, fit: BoxFit.cover),
              ),
            ),
            IgnorePointer(
              ignoring: !touchMenuExpanded || dragging,
              child: ClipOval(
                child: AnimatedOpacity(
                  opacity: touchMenuExpanded ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: ColoredBox(
                    color: Colors.black.withAlpha(58),
                    child: const SizedBox(
                      width: playbackCircleSize,
                      height: playbackCircleSize,
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !touchMenuExpanded || dragging,
              child: AnimatedOpacity(
                opacity: touchMenuExpanded ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: IconButton(
                  onPressed: onOpenPlaybackPage,
                  tooltip: '进入播放页',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: playbackCircleSize,
                    height: playbackCircleSize,
                  ),
                  iconSize: 30,
                  color: Colors.white,
                  icon: const Icon(Icons.fullscreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({
    required this.progress,
    required this.bufferProgress,
    required this.hovered,
    required this.colorScheme,
  });

  final double progress;
  final double? bufferProgress;
  final bool hovered;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = hovered ? 46.0 : 39.0;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = Colors.white.withAlpha(hovered ? 70 : 34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hovered ? 3.5 : 3.2;
    final progressPaint = Paint()
      ..color = colorScheme.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = hovered ? 4.2 : 3.2
      ..strokeCap = StrokeCap.round;
    final bufferPaint = Paint()
      ..color = colorScheme.secondary.withAlpha(105)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hovered ? 3.8 : 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(bounds, 0, math.pi * 2, false, trackPaint);
    final buffered = bufferProgress;
    if (buffered != null && buffered > 0) {
      canvas.drawArc(
        bounds,
        -math.pi / 2,
        math.pi * 2 * buffered.clamp(0.0, 1.0),
        false,
        bufferPaint,
      );
    }
    canvas.drawArc(
      bounds,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );

    if (hovered) {
      final angle = -math.pi / 2 + math.pi * 2 * progress;
      final handleCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(
        handleCenter,
        6.5,
        Paint()..color = colorScheme.secondaryContainer,
      );
      canvas.drawCircle(
        handleCenter,
        3,
        Paint()..color = colorScheme.onSecondaryContainer,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.bufferProgress != bufferProgress ||
      oldDelegate.hovered != hovered ||
      oldDelegate.colorScheme != colorScheme;
}
