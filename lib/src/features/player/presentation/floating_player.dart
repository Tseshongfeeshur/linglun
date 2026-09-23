import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../application/player_controller.dart';
import '../domain/lyrics.dart';
import '../domain/track.dart';
import 'amll_playback_page.dart';

const _circleSize = 72.0;
const _ringSize = 104.0;
const _ringInset = (_ringSize - _circleSize) / 2;
const _panelGap = 12.0;
const _infoPanelMaxWidth = 286.0;
const _floatingPositionSettingKey = 'player.floating.position.v1';

/// 桌面端悬浮播放器：圆形封面是入口，控制和歌词信息按边界弹出。
class FloatingPlayer extends ConsumerStatefulWidget {
  const FloatingPlayer({super.key});

  @override
  ConsumerState<FloatingPlayer> createState() => _FloatingPlayerState();
}

class _FloatingPlayerState extends ConsumerState<FloatingPlayer>
    with SingleTickerProviderStateMixin {
  // 使用归一化坐标保存位置，这样窗口尺寸变化后仍能保持相同的相对位置。
  Offset _positionFactor = const Offset(0, 1);
  Offset? _dragStart;
  Offset? _pointerDownPosition;
  double? _seekPreviewProgress;
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
    unawaited(_loadFloatingPosition());
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
        final center = _positionForSize(size);
        final circleCenter =
            center + const Offset(_circleSize / 2, _circleSize / 2);
        // 方向只由专辑封面圆心所在的窗口半区决定，不再用菜单尺寸或边距
        // 参与判断：上半区向下展开，下半区向上展开；左半区向右展开，
        // 右半区向左展开。圆心位于中线时，控制菜单向下、歌词菜单向左。
        final showAbove = circleCenter.dy > size.height / 2;
        final showLeft = circleCenter.dx >= size.width / 2;

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
                seekPreviewProgress: _seekPreviewProgress,
                showAbove: showAbove,
                showLeft: showLeft,
                onHover: _setHovered,
                onPointerDown: (event) {
                  _pointerDownPosition = event.position;
                  _seeking = _isNearSeekHandle(
                    event.position,
                    center,
                    _progress(state),
                  );
                },
                onDragStart: (details) {
                  _hoverExitTimer?.cancel();
                  // 拖拽识别器可能越过触发阈值后才回调，起点必须使用按下位置，
                  // 避免把进度环手柄误判成封面移动。
                  _dragStart =
                      (_pointerDownPosition ?? details.globalPosition) - center;
                  _seekPreviewProgress = _seeking ? _progress(state) : null;
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
                    setState(() => _seekPreviewProgress = progress);
                    return;
                  }
                  final position = _clampPosition(
                    details.globalPosition - (_dragStart ?? Offset.zero),
                    size,
                  );
                  setState(() {
                    _positionFactor = _factorForPosition(position, size);
                  });
                },
                onDragEnd: (_) {
                  _hoverExitTimer?.cancel();
                  final seekProgress = _seekPreviewProgress;
                  final shouldSeek = _seeking && seekProgress != null;
                  final shouldPersist = !_seeking;
                  setState(() {
                    _dragStart = null;
                    _pointerDownPosition = null;
                    _seekPreviewProgress = null;
                    _seeking = false;
                    _dragging = false;
                    _hovered = true;
                  });
                  if (shouldSeek) {
                    ref
                        .read(playerControllerProvider.notifier)
                        .seek(track.duration * seekProgress);
                  } else if (shouldPersist) {
                    unawaited(_persistFloatingPosition());
                  }
                },
                onTap: () {
                  if (_seeking) {
                    _seeking = false;
                    _pointerDownPosition = null;
                    _seekPreviewProgress = null;
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
                  onPrevious: ref
                      .read(playerControllerProvider.notifier)
                      .previous,
                  onTogglePlay: ref
                      .read(playerControllerProvider.notifier)
                      .togglePlay,
                  onNext: ref.read(playerControllerProvider.notifier).skipNext,
                  onSeek: ref.read(playerControllerProvider.notifier).seek,
                  onToggleShuffle: ref
                      .read(playerControllerProvider.notifier)
                      .toggleShuffle,
                  onCycleRepeat: ref
                      .read(playerControllerProvider.notifier)
                      .cycleRepeatMode,
                  onPlayTrack: ref
                      .read(playerControllerProvider.notifier)
                      .playTrack,
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
    final minimum = Offset(_ringInset + 8, _ringInset + 8);
    final maximum = Offset(
      math.max(minimum.dx, size.width - 96),
      math.max(minimum.dy, size.height - 96),
    );
    return Offset(
      position.dx.clamp(minimum.dx, maximum.dx).toDouble(),
      position.dy.clamp(minimum.dy, maximum.dy).toDouble(),
    );
  }

  Offset _positionForSize(Size size) {
    final minimum = Offset(_ringInset + 8, _ringInset + 8);
    final maximum = Offset(
      math.max(minimum.dx, size.width - 96),
      math.max(minimum.dy, size.height - 96),
    );
    return Offset(
      lerpDouble(minimum.dx, maximum.dx, _positionFactor.dx)!,
      lerpDouble(minimum.dy, maximum.dy, _positionFactor.dy)!,
    );
  }

  Offset _factorForPosition(Offset position, Size size) {
    final minimum = Offset(_ringInset + 8, _ringInset + 8);
    final maximum = Offset(
      math.max(minimum.dx, size.width - 96),
      math.max(minimum.dy, size.height - 96),
    );
    final xRange = maximum.dx - minimum.dx;
    final yRange = maximum.dy - minimum.dy;
    return Offset(
      xRange == 0
          ? 0
          : ((position.dx - minimum.dx) / xRange).clamp(0, 1).toDouble(),
      yRange == 0
          ? 0
          : ((position.dy - minimum.dy) / yRange).clamp(0, 1).toDouble(),
    );
  }

  Future<void> _loadFloatingPosition() async {
    try {
      final database = await sharedLinglunDatabase();
      final value = await database.loadSetting(_floatingPositionSettingKey);
      if (!mounted || value == null) return;
      final decoded = jsonDecode(value);
      if (decoded is! Map) return;
      final x = (decoded['x'] as num?)?.toDouble();
      final y = (decoded['y'] as num?)?.toDouble();
      if (x == null || y == null) return;
      setState(() {
        _positionFactor = Offset(
          x.clamp(0, 1).toDouble(),
          y.clamp(0, 1).toDouble(),
        );
      });
    } catch (_) {
      // 位置设置读取失败不应影响播放器显示，继续使用左下角默认位置。
    }
  }

  Future<void> _persistFloatingPosition() async {
    try {
      final database = await sharedLinglunDatabase();
      await database.saveSetting(
        _floatingPositionSettingKey,
        jsonEncode({'x': _positionFactor.dx, 'y': _positionFactor.dy}),
      );
    } catch (_) {
      // 设置保存失败不应阻断播放或拖动交互。
    }
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
    required this.seekPreviewProgress,
    required this.showAbove,
    required this.showLeft,
    required this.onHover,
    required this.onPointerDown,
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
  final double? seekPreviewProgress;
  final bool showAbove;
  final bool showLeft;
  final ValueChanged<bool> onHover;
  final ValueChanged<PointerDownEvent> onPointerDown;
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
      maxWidth: _infoPanelMaxWidth,
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
            style: const TextStyle(color: Colors.white60),
          ),
          if (currentLine == null)
            Text(
              track.lyrics == null || track.lyrics!.trim().isEmpty
                  ? '暂无歌词'
                  : lyrics.timing == LyricsTiming.none
                  ? '歌词没有时间信息'
                  : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
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
    final circleCenterX = position.dx + _circleSize / 2;
    final circleCenterY = position.dy + _circleSize / 2;
    final infoRightAnchor = position.dx - _panelGap;
    final infoLeftAnchor = position.dx + _circleSize + _panelGap;
    final controlTopAnchor = position.dy - _panelGap;
    final controlBottomAnchor = position.dy + _circleSize + _panelGap;

    // 菜单的外层锚点只负责从圆心移动到目标边缘，尺寸由内容自身决定。
    // 这样窗口大小或拖动位置变化时可以立即重定位，而悬停状态变化仍有
    // 独立的展开动画。
    final infoMenu = _MenuMotion(
      expanded: panelsExpanded,
      instant: dragging,
      collapsedAnchor: Offset(circleCenterX, circleCenterY),
      expandedAnchor: Offset(
        showLeft ? infoRightAnchor : infoLeftAnchor,
        circleCenterY,
      ),
      collapsedTranslation: const Offset(-.5, -.5),
      expandedTranslation: showLeft
          ? const Offset(-1, -.5)
          : const Offset(0, -.5),
      child: panel(info),
    );
    final controlMenu = _MenuMotion(
      expanded: panelsExpanded,
      instant: dragging,
      collapsedAnchor: Offset(circleCenterX, circleCenterY),
      expandedAnchor: Offset(
        circleCenterX,
        showAbove ? controlTopAnchor : controlBottomAnchor,
      ),
      collapsedTranslation: const Offset(-.5, -.5),
      expandedTranslation: showAbove
          ? const Offset(-.5, -1)
          : const Offset(-.5, 0),
      child: panel(bubble),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 透明桥接区只在菜单已经打开后出现，避免未悬停时扩大封面圆的
        // 命中范围；菜单位置变化时桥接区也会立即跟随新锚点。
        if (!expanded && hovered)
          Positioned(
            left: showLeft ? infoRightAnchor : position.dx + _circleSize,
            top: position.dy,
            width: _panelGap,
            height: _circleSize,
            child: MouseRegion(
              opaque: false,
              onEnter: (_) => onHover(true),
              onExit: (_) => onHover(false),
              child: const SizedBox.expand(),
            ),
          ),
        if (!expanded && hovered)
          Positioned(
            left: position.dx,
            top: showAbove
                ? position.dy - _panelGap
                : position.dy + _circleSize,
            width: _circleSize,
            height: _panelGap,
            child: MouseRegion(
              opaque: false,
              onEnter: (_) => onHover(true),
              onExit: (_) => onHover(false),
              child: const SizedBox.expand(),
            ),
          ),
        if (!expanded) infoMenu,
        if (!expanded) controlMenu,
        Positioned(
          left: circleLeft,
          top: circleTop,
          width: _ringSize,
          height: _ringSize,
          child: MouseRegion(
            onEnter: (_) => onHover(true),
            onExit: (_) => onHover(false),
            child: Listener(
              onPointerDown: onPointerDown,
              child: GestureDetector(
                onTap: dragging ? null : onTap,
                onPanStart: onDragStart,
                onPanUpdate: onDragUpdate,
                onPanEnd: onDragEnd,
                // 只裁切内部封面。进度环和手柄位于封面外侧，若在这里裁切
                // 整个组件，手柄经过圆周边缘时会被截断。
                child: _ProgressCircle(
                  track: track,
                  progress: seekPreviewProgress ?? _progress(state),
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

/// 只在“展开/收起”状态变化时播放位移动画。
///
/// 圆被拖动或窗口尺寸变化时，锚点会立即更新，不会因为新的目标位置
/// 触发一段额外的位移动画，从而避免菜单与圆产生滞后。
class _MenuMotion extends StatefulWidget {
  const _MenuMotion({
    required this.expanded,
    required this.instant,
    required this.collapsedAnchor,
    required this.expandedAnchor,
    required this.collapsedTranslation,
    required this.expandedTranslation,
    required this.child,
  });

  final bool expanded;
  final bool instant;
  final Offset collapsedAnchor;
  final Offset expandedAnchor;
  final Offset collapsedTranslation;
  final Offset expandedTranslation;
  final Widget child;

  @override
  State<_MenuMotion> createState() => _MenuMotionState();
}

class _MenuMotionState extends State<_MenuMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: widget.expanded ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _MenuMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.instant) {
      _controller.value = widget.expanded ? 1 : 0;
    } else if (widget.expanded != oldWidget.expanded) {
      _controller.animateTo(
        widget.expanded ? 1 : 0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_controller.value);
        final anchor = Offset.lerp(
          widget.collapsedAnchor,
          widget.expandedAnchor,
          progress,
        )!;
        final translation = Offset.lerp(
          widget.collapsedTranslation,
          widget.expandedTranslation,
          progress,
        )!;
        return Positioned(
          left: anchor.dx,
          top: anchor.dy,
          child: FractionalTranslation(translation: translation, child: child),
        );
      },
    );
  }
}

class _MorphingGlassBubble extends StatelessWidget {
  const _MorphingGlassBubble({
    required this.child,
    required this.expanded,
    required this.instant,
    this.maxWidth,
  });

  final Widget child;
  final bool expanded;
  final bool instant;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final duration = instant
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final constraints = maxWidth == null
        ? const BoxConstraints()
        : BoxConstraints(maxWidth: maxWidth!);
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        constraints: constraints,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(22),
          border: Border.all(color: Colors.white.withAlpha(28)),
          borderRadius: BorderRadius.circular(expanded ? 34 : 99),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(expanded ? 34 : 99),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: child,
                  )
                : const SizedBox.square(dimension: _circleSize),
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
          fontSize: 15,
          fontWeight: FontWeight.w600,
          wordSpacing: 1,
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
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white54,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
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
        style: const TextStyle(color: Colors.white54, fontSize: 13),
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
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
    required this.onSeek,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
    required this.onPlayTrack,
  });

  final Track track;
  final PlayerState state;
  final Animation<double> animation;
  final Offset sourceCenter;
  final Size viewport;
  final VoidCallback onClose;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;
  final ValueChanged<Track> onPlayTrack;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
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
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: curved,
                child: AmllPlaybackPage(
                  track: track,
                  state: state,
                  onClose: onClose,
                  onPrevious: onPrevious,
                  onTogglePlay: onTogglePlay,
                  onNext: onNext,
                  onSeek: onSeek,
                  onToggleShuffle: onToggleShuffle,
                  onCycleRepeat: onCycleRepeat,
                  onPlayTrack: onPlayTrack,
                ),
              ),
              Positioned(
                left: coverCenter.dx - 52,
                top: coverCenter.dy - 52,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (1 - value).clamp(0, 1),
                    child: _ProgressCircle(
                      track: track,
                      progress: _progress(state),
                      hovered: false,
                      dragging: false,
                    ),
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
