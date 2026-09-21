import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';
import '../domain/lyrics.dart';
import '../domain/track.dart';

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
  bool _expanded = false;
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
        final showAbove = center.dy >= 180;
        final showLeft = center.dx + 72 + 238 > size.width;

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
            AnimatedPositioned(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              left: center.dx,
              top: center.dy,
              child: _FloatingCluster(
                track: track,
                state: state,
                hovered: _hovered,
                dragging: _dragging,
                expanded: _expanded,
                showAbove: showAbove,
                showLeft: showLeft,
                onHover: (value) => setState(() => _hovered = value),
                onDragStart: (details) {
                  _dragStart = details.globalPosition - center;
                  setState(() => _dragging = true);
                },
                onDragUpdate: (details) {
                  setState(() {
                    _position = _clampPosition(
                      details.globalPosition - (_dragStart ?? Offset.zero),
                      size,
                    );
                  });
                },
                onDragEnd: (_) => setState(() {
                  _dragStart = null;
                  _dragging = false;
                }),
                onTap: _openExpanded,
              ),
            ),
            if (_expanded)
              Positioned.fill(
                child: _ExpandedPlayer(
                  track: track,
                  state: state,
                  animation: _expandController,
                  origin: Alignment(
                    ((center.dx + 36) / size.width) * 2 - 1,
                    ((center.dy + 36) / size.height) * 2 - 1,
                  ),
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

  void _closeExpanded() {
    _expandController.reverse().whenComplete(() {
      if (mounted) setState(() => _expanded = false);
    });
  }

  Offset _clampPosition(Offset position, Size size) {
    return Offset(
      position.dx.clamp(14, math.max(14, size.width - 78)).toDouble(),
      position.dy.clamp(14, math.max(14, size.height - 78)).toDouble(),
    );
  }
}

class _FloatingCluster extends ConsumerWidget {
  const _FloatingCluster({
    required this.track,
    required this.state,
    required this.hovered,
    required this.dragging,
    required this.expanded,
    required this.showAbove,
    required this.showLeft,
    required this.onHover,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  final Track track;
  final PlayerState state;
  final bool hovered;
  final bool dragging;
  final bool expanded;
  final bool showAbove;
  final bool showLeft;
  final ValueChanged<bool> onHover;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLine = _currentLyric(track, state.position);
    final controller = ref.read(playerControllerProvider.notifier);
    final bubble = _GlassBubble(
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
    final info = _GlassBubble(
      width: 238,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(track.artist, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 6),
          if (currentLine == null)
            Text(
              '暂无歌词',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            )
          else ...[
            _LyricPreviewLine(line: currentLine, position: state.position),
            if (currentLine.translation != null)
              Text(
                currentLine.translation!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ],
      ),
    );

    final panelsVisible = !dragging && !expanded && hovered;

    Widget panel(Widget child) {
      return MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: IgnorePointer(
          ignoring: !panelsVisible,
          child: AnimatedOpacity(
            opacity: panelsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: child,
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!expanded)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: showLeft ? -252 : 82,
            top: 0,
            child: panel(info),
          ),
        if (!expanded)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: 0,
            top: showAbove ? -166 : 82,
            child: panel(bubble),
          ),
        MouseRegion(
          onEnter: (_) => onHover(true),
          onExit: (_) => onHover(false),
          child: GestureDetector(
            onTap: dragging ? null : onTap,
            onPanStart: onDragStart,
            onPanUpdate: onDragUpdate,
            onPanEnd: onDragEnd,
            child: _ProgressCircle(
              track: track,
              progress: _progress(state),
              hovered: hovered,
              dragging: dragging,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassBubble extends StatelessWidget {
  const _GlassBubble({required this.child, this.width = 72});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(22),
            border: Border.all(color: Colors.white.withAlpha(28)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        height: 72,
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
        child: CustomPaint(
          foregroundPainter: _ProgressPainter(progress),
          child: ClipOval(
            child: track.coverBytes == null
                ? ColoredBox(
                    color: Color(track.coverColor),
                    child: const Icon(Icons.music_note, color: Colors.white70),
                  )
                : Image.memory(track.coverBytes!, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF80CBC4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Offset.zero & size, 0, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ExpandedPlayer extends StatelessWidget {
  const _ExpandedPlayer({
    required this.track,
    required this.state,
    required this.animation,
    required this.origin,
    required this.onClose,
  });

  final Track track;
  final PlayerState state;
  final Animation<double> animation;
  final Alignment origin;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        alignment: origin,
        scale: Tween<double>(begin: .18, end: 1).animate(curved),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor.withAlpha(244),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProgressCircle(
                        track: track,
                        progress: _progress(state),
                        hovered: false,
                        dragging: false,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        track.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        track.artist,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 22,
                  right: 22,
                  child: IconButton(
                    onPressed: onClose,
                    tooltip: '关闭播放页',
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

LyricLine? _currentLyric(Track track, Duration position) {
  if (track.lyrics == null) return null;
  final document = parseLyricsFile(
    track.lyrics!,
    extension: track.lyricsFormat,
  );
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
