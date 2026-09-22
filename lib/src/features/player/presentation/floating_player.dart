import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';
import '../domain/lyrics.dart';
import '../domain/track.dart';

const _circleSize = 72.0;
const _ringSize = 104.0;
const _ringInset = (_ringSize - _circleSize) / 2;
const _panelGap = 12.0;
const _infoPanelWidth = 286.0;
const _infoPanelHeight = 104.0;
const _controlPanelWidth = 82.0;
const _controlPanelHeight = 178.0;

/// 桌面端悬浮播放器：圆形封面是入口，控制和歌词信息按边界弹出。
class FloatingPlayer extends ConsumerStatefulWidget {
  const FloatingPlayer({super.key});

  @override
  ConsumerState<FloatingPlayer> createState() => _FloatingPlayerState();
}

class _FloatingPlayerState extends ConsumerState<FloatingPlayer>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(36, 120);
  Offset? _dragStart;
  bool _hovered = false;
  bool _dragging = false;
  bool _seeking = false;
  bool _expanded = false;
  Timer? _hoverExitTimer;
  late final AnimationController _expandController;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _hoverExitTimer?.cancel();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);
    final track = state.currentTrack;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = _clampPosition(_position, size);
        // 以完整菜单是否能放入窗口为准，避免使用固定阈值造成菜单越界。
        final canShowAbove = center.dy - _panelGap - _controlPanelHeight >= 8;
        final canShowBelow =
            center.dy + _circleSize + _panelGap + _controlPanelHeight <=
            size.height - 8;
        final spaceAbove = center.dy - 8;
        final spaceBelow = size.height - 8 - center.dy - _circleSize;
        final showAbove = canShowAbove
            ? true
            : canShowBelow
            ? false
            : spaceAbove >= spaceBelow;
        final canShowRight =
            center.dx + _circleSize + _panelGap + _infoPanelWidth <=
            size.width - 8;
        final canShowLeft = center.dx - _panelGap - _infoPanelWidth >= 8;
        final spaceRight = size.width - 8 - center.dx - _circleSize;
        final spaceLeft = center.dx - 8;
        final showLeft = canShowRight
            ? false
            : canShowLeft
            ? true
            : spaceLeft >= spaceRight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_dragging,
                child: AnimatedOpacity(
                  opacity: _dragging ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: ColoredBox(color: Colors.black.withAlpha(45)),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: _FloatingCluster(
                position: center,
                track: track,
                state: state,
                hovered: _hovered,
                dragging: _dragging,
                expanded: _expanded,
                viewport: size,
                showAbove: showAbove,
                showLeft: showLeft,
                onHover: _setHovered,
                onTapDown: (details) {
                  _seeking = _isNearSeekHandle(
                    details.globalPosition,
                    center,
                    _progress(state),
                  );
                },
                onDragStart: (details) {
                  _hoverExitTimer?.cancel();
                  _seeking = _isNearSeekHandle(
                    details.globalPosition,
                    center,
                    _progress(state),
                  );
                  _dragStart = details.globalPosition - center;
                  setState(() {
                    _hovered = true;
                    _dragging = true;
                  });
                },
                onDragUpdate: (details) {
                  if (_seeking) {
                    final local = details.globalPosition - center;
                    final angle = math.atan2(local.dy - 36, local.dx - 36);
                    final progress =
                        ((angle + math.pi / 2) / (math.pi * 2)) % 1;
                    final duration = track.duration;
                    ref
                        .read(playerControllerProvider.notifier)
                        .seek(duration * progress);
                    return;
                  }
                  setState(() {
                    _position = _clampPosition(
                      details.globalPosition - (_dragStart ?? Offset.zero),
                      size,
                    );
                  });
                },
                onDragEnd: (_) {
                  _hoverExitTimer?.cancel();
                  setState(() {
                    _dragStart = null;
                    _seeking = false;
                    _dragging = false;
                    _hovered = true;
                  });
                },
                onTap: () {
                  if (_seeking) {
                    _seeking = false;
                    return;
                  }
                  _openExpanded();
                },
              ),
            ),
            if (_expanded)
              Positioned.fill(
                child: _ExpandedPlayer(
                  track: track,
                  state: state,
                  animation: _expandController,
                  sourceCenter: center + const Offset(36, 36),
                  viewport: size,
                  onClose: _closeExpanded,
                ),
              ),
          ],
        );
      },
    );
  }

  void _openExpanded() {
    setState(() => _expanded = true);
    _expandController.forward(from: 0);
  }

  void _setHovered(bool value) {
    _hoverExitTimer?.cancel();
    if (value) {
      if (!_hovered) setState(() => _hovered = true);
      return;
    }
    // 给光标从圆移动到面板留出时间，避免经过透明间隙时面板立即收回。
    _hoverExitTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _hovered = false);
    });
  }

  void _closeExpanded() {
    _expandController.reverse().whenComplete(() {
      if (mounted) setState(() => _expanded = false);
    });
  }

  Offset _clampPosition(Offset position, Size size) {
    return Offset(
      position.dx
          .clamp(_ringInset + 8, math.max(_ringInset + 8, size.width - 96))
          .toDouble(),
      position.dy
          .clamp(_ringInset + 8, math.max(_ringInset + 8, size.height - 96))
          .toDouble(),
    );
  }

  bool _isNearSeekHandle(
    Offset globalPosition,
    Offset circlePosition,
    double progress,
  ) {
    if (!_hovered) return false;
    final local = globalPosition - circlePosition;
    final vector = local - const Offset(36, 36);
    final radius = vector.distance;
    if (radius < 35 || radius > 53) return false;

    final pointerAngle = math.atan2(vector.dy, vector.dx);
    final handleAngle = progress * math.pi * 2 - math.pi / 2;
    final delta = math
        .atan2(
          math.sin(pointerAngle - handleAngle),
          math.cos(pointerAngle - handleAngle),
        )
        .abs();
    return delta <= .3;
  }
}

class _FloatingCluster extends ConsumerWidget {
  const _FloatingCluster({
    required this.position,
    required this.track,
    required this.state,
    required this.hovered,
    required this.dragging,
    required this.expanded,
    required this.viewport,
    required this.showAbove,
    required this.showLeft,
    required this.onHover,
    required this.onTapDown,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  final Offset position;
  final Track track;
  final PlayerState state;
  final bool hovered;
  final bool dragging;
  final bool expanded;
  final Size viewport;
  final bool showAbove;
  final bool showLeft;
  final ValueChanged<bool> onHover;
  final GestureTapDownCallback onTapDown;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyrics = _lyricsDocument(track);
    final currentLine = _currentLyric(lyrics, state.position);
    final lyricPosition = state.position - lyrics.offset;
    final controller = ref.read(playerControllerProvider.notifier);
    final panelsExpanded = !expanded && (hovered || dragging);
    final bubble = _MorphingGlassBubble(
      width: _controlPanelWidth,
      height: _controlPanelHeight,
      expanded: panelsExpanded,
      instant: dragging,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: controller.previous,
            tooltip: '上一曲',
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton.filled(
            onPressed: controller.togglePlay,
            tooltip: state.isPlaying ? '暂停' : '播放',
            icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            onPressed: controller.skipNext,
            tooltip: '下一曲',
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
    );
    final info = _MorphingGlassBubble(
      width: _infoPanelWidth,
      height: _infoPanelHeight,
      expanded: panelsExpanded,
      instant: dragging,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${track.title} - ${track.artist}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (currentLine == null)
            Text(
              track.lyrics == null || track.lyrics!.trim().isEmpty
                  ? '暂无歌词'
                  : lyrics.timing == LyricsTiming.none
                  ? '歌词没有时间信息'
                  : '当前没有歌词',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            )
          else ...[
            _LyricPreviewLine(line: currentLine, position: lyricPosition),
            if (currentLine.translation != null)
              _LyricPreviewVariant(
                text: currentLine.translation!,
                words: currentLine.translationWords,
                position: lyricPosition,
              ),
            for (final variant in currentLine.variants)
              _LyricPreviewVariant(
                text: variant.text,
                words: variant.words,
                position: lyricPosition,
              ),
          ],
        ],
      ),
    );

    Widget panel(Widget child) {
      return MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: IgnorePointer(
          ignoring: !hovered || dragging || expanded,
          child: child,
        ),
      );
    }

    final circleLeft = position.dx - _ringInset;
    final circleTop = position.dy - _ringInset;
    final maxInfoLeft = math.max(8.0, viewport.width - _infoPanelWidth - 8);
    final maxInfoTop = math.max(8.0, viewport.height - _infoPanelHeight - 8);
    final maxControlLeft = math.max(
      8.0,
      viewport.width - _controlPanelWidth - 8,
    );
    final maxControlTop = math.max(
      8.0,
      viewport.height - _controlPanelHeight - 8,
    );
    final infoTargetLeft =
        (showLeft
                ? position.dx - _panelGap - _infoPanelWidth
                : position.dx + _circleSize + _panelGap)
            .clamp(8.0, maxInfoLeft)
            .toDouble();
    final infoTargetTop = (position.dy + (_circleSize - _infoPanelHeight) / 2)
        .clamp(8.0, maxInfoTop)
        .toDouble();
    final controlTargetLeft =
        (position.dx + (_circleSize - _controlPanelWidth) / 2)
            .clamp(8.0, maxControlLeft)
            .toDouble();
    final controlTargetTop =
        (showAbove
                ? position.dy - _panelGap - _controlPanelHeight
                : position.dy + _circleSize + _panelGap)
            .clamp(8.0, maxControlTop)
            .toDouble();
    final collapsedInfoLeft = position.dx + (_circleSize - _circleSize) / 2;
    final collapsedInfoTop = position.dy + (_circleSize - _circleSize) / 2;
    final collapsedControlLeft = position.dx + (_circleSize - _circleSize) / 2;
    final collapsedControlTop = position.dy + (_circleSize - _circleSize) / 2;
    final infoBridgeStart = showLeft
        ? infoTargetLeft + _infoPanelWidth
        : position.dx + _circleSize;
    final infoBridgeEnd = showLeft ? position.dx : infoTargetLeft;
    final infoBridgeLeft = math.min(infoBridgeStart, infoBridgeEnd);
    final infoBridgeWidth = (infoBridgeEnd - infoBridgeStart).abs();
    final controlBridgeStart = showAbove
        ? controlTargetTop + _controlPanelHeight
        : position.dy + _circleSize;
    final controlBridgeEnd = showAbove ? position.dy : controlTargetTop;
    final controlBridgeTop = math.min(controlBridgeStart, controlBridgeEnd);
    final controlBridgeHeight = (controlBridgeEnd - controlBridgeStart).abs();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!expanded && hovered && infoBridgeWidth > 0)
          Positioned(
            left: infoBridgeLeft,
            top: infoTargetTop,
            width: infoBridgeWidth,
            height: _infoPanelHeight,
            child: MouseRegion(
              opaque: false,
              onEnter: (_) => onHover(true),
              onExit: (_) => onHover(false),
              child: const SizedBox.expand(),
            ),
          ),
        if (!expanded && hovered && controlBridgeHeight > 0)
          Positioned(
            left: controlTargetLeft,
            top: controlBridgeTop,
            width: _controlPanelWidth,
            height: controlBridgeHeight,
            child: MouseRegion(
              opaque: false,
              onEnter: (_) => onHover(true),
              onExit: (_) => onHover(false),
              child: const SizedBox.expand(),
            ),
          ),
        if (!expanded)
          AnimatedPositioned(
            duration: dragging
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            left: panelsExpanded ? infoTargetLeft : collapsedInfoLeft,
            top: panelsExpanded ? infoTargetTop : collapsedInfoTop,
            width: panelsExpanded ? _infoPanelWidth : _circleSize,
            height: panelsExpanded ? _infoPanelHeight : _circleSize,
            child: panel(info),
          ),
        if (!expanded)
          AnimatedPositioned(
            duration: dragging
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            left: panelsExpanded ? controlTargetLeft : collapsedControlLeft,
            top: panelsExpanded ? controlTargetTop : collapsedControlTop,
            width: panelsExpanded ? _controlPanelWidth : _circleSize,
            height: panelsExpanded ? _controlPanelHeight : _circleSize,
            child: panel(bubble),
          ),
        Positioned(
          left: circleLeft,
          top: circleTop,
          width: _ringSize,
          height: _ringSize,
          child: MouseRegion(
            onEnter: (_) => onHover(true),
            onExit: (_) => onHover(false),
            child: GestureDetector(
              onTapDown: onTapDown,
              onTap: dragging ? null : onTap,
              onPanStart: onDragStart,
              onPanUpdate: onDragUpdate,
              onPanEnd: onDragEnd,
              child: ClipOval(
                child: _ProgressCircle(
                  track: track,
                  progress: _progress(state),
                  hovered: hovered,
                  dragging: dragging,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MorphingGlassBubble extends StatelessWidget {
  const _MorphingGlassBubble({
    required this.child,
    required this.width,
    required this.height,
    required this.expanded,
    required this.instant,
  });

  final Widget child;
  final double width;
  final double height;
  final bool expanded;
  final bool instant;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: instant ? Duration.zero : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: expanded ? width : _circleSize,
        height: expanded ? height : _circleSize,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(22),
          border: Border.all(color: Colors.white.withAlpha(28)),
          borderRadius: BorderRadius.circular(34),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: 0,
                maxWidth: width - 24,
                minHeight: 0,
                maxHeight: height - 20,
                child: SizedBox(
                  width: width - 24,
                  height: height - 20,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LyricPreviewLine extends StatelessWidget {
  const _LyricPreviewLine({required this.line, required this.position});

  final LyricLine line;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    if (!line.isWordSynchronized) {
      return Text(
        line.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 13,
        ),
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          for (final word in line.words)
            TextSpan(
              text: word.text,
              style: TextStyle(
                color: word.start <= position
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

class _LyricPreviewVariant extends StatelessWidget {
  const _LyricPreviewVariant({
    required this.text,
    required this.words,
    required this.position,
  });

  final String text;
  final List<LyricWord> words;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      );
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          for (final word in words)
            TextSpan(
              text: word.text,
              style: TextStyle(
                color: word.start <= position ? Colors.white70 : Colors.white38,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle({
    required this.track,
    required this.progress,
    required this.hovered,
    required this.dragging,
  });

  final Track track;
  final double progress;
  final bool hovered;
  final bool dragging;

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
        width: _ringSize,
        height: _ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(_ringSize),
              painter: _ProgressPainter(progress: progress, hovered: hovered),
            ),
            Container(
              width: _circleSize,
              height: _circleSize,
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
          ],
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({required this.progress, required this.hovered});

  final double progress;
  final bool hovered;

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
      ..color = const Color(0xFF80CBC4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hovered ? 4.2 : 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(bounds, 0, math.pi * 2, false, trackPaint);
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
        Paint()..color = const Color(0xFFB2DFDB),
      );
      canvas.drawCircle(
        handleCenter,
        3,
        Paint()..color = const Color(0xFF244744),
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.hovered != hovered;
}

class _ExpandedPlayer extends StatelessWidget {
  const _ExpandedPlayer({
    required this.track,
    required this.state,
    required this.animation,
    required this.sourceCenter,
    required this.viewport,
    required this.onClose,
  });

  final Track track;
  final PlayerState state;
  final Animation<double> animation;
  final Offset sourceCenter;
  final Size viewport;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    final pageCenter = Offset(viewport.width / 2, viewport.height / 2);
    final maxRadius =
        math.sqrt(
          viewport.width * viewport.width + viewport.height * viewport.height,
        ) +
        20;

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final value = curved.value;
        final coverCenter = Offset.lerp(sourceCenter, pageCenter, value)!;
        return ClipPath(
          clipper: _ExpandingCircleClipper(
            center: sourceCenter,
            radius: lerpDouble(_ringSize / 2, maxRadius, value)!,
          ),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor
                      .withAlpha(244),
                  child: Stack(
                    children: [
                      Positioned(
                        left: coverCenter.dx - 52,
                        top: coverCenter.dy - 52,
                        child: _ProgressCircle(
                          track: track,
                          progress: _progress(state),
                          hovered: false,
                          dragging: false,
                        ),
                      ),
                      Opacity(
                        opacity: value,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 180),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  track.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                Text(
                                  track.artist,
                                  style: const TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 22,
                        right: 22,
                        child: Opacity(
                          opacity: value,
                          child: IconButton(
                            onPressed: onClose,
                            tooltip: '关闭播放页',
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpandingCircleClipper extends CustomClipper<Path> {
  const _ExpandingCircleClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_ExpandingCircleClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}

LyricsDocument _lyricsDocument(Track track) {
  return track.lyricsDocument;
}

LyricLine? _currentLyric(LyricsDocument document, Duration position) {
  if (!document.hasTimestamps) return null;
  final adjusted = position - document.offset;
  LyricLine? current;
  for (final line in document.lines) {
    if (line.start <= adjusted) current = line;
  }
  return current;
}

double _progress(PlayerState state) {
  final duration = state.currentTrack.duration.inMilliseconds;
  if (duration <= 0) return 0;
  return (state.position.inMilliseconds / duration).clamp(0, 1).toDouble();
}
