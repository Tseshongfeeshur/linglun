import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../application/player_controller.dart';
import '../domain/lyrics.dart';
import '../domain/track.dart';
import 'amll_playback_route.dart';
import 'playback_progress_circle.dart';

const _circleSize = playbackCircleSize;
const _ringSize = playbackRingSize;
const _ringInset = (_ringSize - _circleSize) / 2;
const _panelGap = 12.0;
const _floatingPositionSettingKey = 'player.floating.position.v1';

/// 桌面端悬浮播放器：圆形封面是入口，控制和歌词信息按边界弹出。
class FloatingPlayer extends ConsumerStatefulWidget {
  const FloatingPlayer({super.key});

  @override
  ConsumerState<FloatingPlayer> createState() => _FloatingPlayerState();
}

class _FloatingPlayerState extends ConsumerState<FloatingPlayer> {
  // 使用归一化坐标保存位置，这样窗口尺寸变化后仍能保持相同的相对位置。
  Offset _positionFactor = const Offset(0, 1);
  Offset? _dragStart;
  Offset? _pointerDownPosition;
  double? _seekPreviewProgress;
  bool _hovered = false;
  bool _dragging = false;
  bool _seeking = false;
  Timer? _hoverExitTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFloatingPosition());
  }

  @override
  void dispose() {
    _hoverExitTimer?.cancel();
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
                  _openPlaybackPage(context, circleCenter);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openPlaybackPage(BuildContext context, Offset localSourceCenter) {
    _hoverExitTimer?.cancel();
    setState(() => _hovered = false);
    final renderBox = context.findRenderObject() as RenderBox;
    final sourceCenter = renderBox.localToGlobal(localSourceCenter);
    unawaited(
      Navigator.of(context).push<void>(
        AmllPlaybackPageRoute(
          sourceCenter: sourceCenter,
          settings: const RouteSettings(name: '/playback'),
        ),
      ),
    );
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
    final panelsExpanded = hovered || dragging;
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
      maxWidth: MediaQuery.sizeOf(context).width * .4,
      expanded: panelsExpanded,
      instant: dragging,
      collapseToHeight: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: showLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentLine == null)
            Text(
              track.lyrics == null || track.lyrics!.trim().isEmpty
                  ? '暂无歌词'
                  : lyrics.timing == LyricsTiming.none
                  ? '歌词没有时间信息'
                  : '暂无歌词',
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
              _LyricPreviewVariant(text: currentLine.translation!),
            for (final variant in currentLine.variants)
              _LyricPreviewVariant(text: variant.text),
          ],
        ],
      ),
    );

    Widget panel(Widget child) {
      return MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: IgnorePointer(ignoring: !hovered || dragging, child: child),
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
    final infoOuterPadding = showLeft
        ? const EdgeInsets.only(right: 14)
        : const EdgeInsets.only(left: 14);
    final controlOuterPadding = showAbove
        ? const EdgeInsets.only(bottom: 14)
        : const EdgeInsets.only(top: 14);
    final collapsedInfoAnchor = Offset(
      circleCenterX +
          (showLeft ? infoOuterPadding.right / 2 : -infoOuterPadding.left / 2),
      circleCenterY,
    );
    final collapsedControlAnchor = Offset(
      circleCenterX,
      circleCenterY +
          (showAbove
              ? controlOuterPadding.bottom / 2
              : -controlOuterPadding.top / 2),
    );

    // 菜单的外层锚点只负责从圆心移动到目标边缘，尺寸由内容自身决定。
    // 这样窗口大小或拖动位置变化时可以立即重定位，而悬停状态变化仍有
    // 独立的展开动画。
    final infoMenu = _MenuMotion(
      expanded: panelsExpanded,
      instant: dragging,
      collapsedAnchor: collapsedInfoAnchor,
      expandedAnchor: Offset(
        showLeft ? infoRightAnchor : infoLeftAnchor,
        circleCenterY,
      ),
      collapsedTranslation: const Offset(-.5, -.5),
      expandedTranslation: showLeft
          ? const Offset(-1, -.5)
          : const Offset(0, -.5),
      child: panel(Padding(padding: infoOuterPadding, child: info)),
    );
    final controlMenu = _MenuMotion(
      expanded: panelsExpanded,
      instant: dragging,
      collapsedAnchor: collapsedControlAnchor,
      expandedAnchor: Offset(
        circleCenterX,
        showAbove ? controlTopAnchor : controlBottomAnchor,
      ),
      collapsedTranslation: const Offset(-.5, -.5),
      expandedTranslation: showAbove
          ? const Offset(-.5, -1)
          : const Offset(-.5, 0),
      child: panel(Padding(padding: controlOuterPadding, child: bubble)),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 透明桥接区只在菜单已经打开后出现，避免未悬停时扩大封面圆的
        // 命中范围；菜单位置变化时桥接区也会立即跟随新锚点。
        if (hovered)
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
        if (hovered)
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
        infoMenu,
        controlMenu,
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
                child: PlaybackProgressCircle(
                  track: track,
                  progress: seekPreviewProgress ?? _progress(state),
                  bufferProgress: state.beatAnalysisProgress,
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
        curve: Curves.easeInOutCubic,
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
        final progress = Curves.easeInOutCubic.transform(_controller.value);
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

class _MorphingGlassBubble extends StatefulWidget {
  const _MorphingGlassBubble({
    required this.child,
    required this.expanded,
    required this.instant,
    this.contentPadding = const EdgeInsets.all(8),
    this.collapseToHeight = false,
    this.maxWidth,
  });

  final Widget child;
  final bool expanded;
  final bool instant;
  final EdgeInsets contentPadding;
  final bool collapseToHeight;
  final double? maxWidth;

  @override
  State<_MorphingGlassBubble> createState() => _MorphingGlassBubbleState();
}

class _MorphingGlassBubbleState extends State<_MorphingGlassBubble> {
  Size? _measuredContentSize;

  void _onContentSizeChanged(Size size) {
    if (!mounted || size == _measuredContentSize) return;
    setState(() => _measuredContentSize = size);
  }

  Size _expandedSize(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = widget.maxWidth ?? viewportWidth;
    final content =
        _measuredContentSize ?? const Size(_circleSize, _circleSize);
    final padding = widget.contentPadding;
    final width = (content.width + padding.horizontal)
        .clamp(1.0, maxWidth)
        .toDouble();
    final height = content.height + padding.vertical;
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.instant
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final expandedSize = _expandedSize(context);
    final collapsedSize = math.min(
      widget.collapseToHeight ? expandedSize.height : expandedSize.width,
      _circleSize,
    );
    final size = widget.expanded ? expandedSize : Size.square(collapsedSize);
    final maxContentWidth = math.max(
      1.0,
      (widget.maxWidth ?? expandedSize.width) -
          widget.contentPadding.horizontal,
    );

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOutCubic,
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        border: Border.all(color: Colors.white.withAlpha(28)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: widget.expanded ? widget.contentPadding : EdgeInsets.zero,
            child: OverflowBox(
              alignment: Alignment.center,
              maxWidth: maxContentWidth,
              maxHeight: MediaQuery.sizeOf(context).height,
              child: _BubbleSizeReporter(
                onSizeChanged: _onContentSizeChanged,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: IntrinsicWidth(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleSizeReporter extends SingleChildRenderObjectWidget {
  const _BubbleSizeReporter({required this.onSizeChanged, super.child});

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _BubbleSizeReporterRenderObject(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _BubbleSizeReporterRenderObject renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _BubbleSizeReporterRenderObject extends RenderProxyBox {
  _BubbleSizeReporterRenderObject(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _lastReportedSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _lastReportedSize) return;
    _lastReportedSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSizeChanged(size);
    });
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
          height: 1,
          fontWeight: FontWeight.w400,
          wordSpacing: 1,
        ),
      );
    }

    return _SimpleKaraokeText(
      text: line.text,
      words: line.words,
      position: position,
      fontSize: 15,
      baseAlpha: .35,
      highlightAlpha: .95,
    );
  }
}

class _LyricPreviewVariant extends StatelessWidget {
  const _LyricPreviewVariant({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1),
    );
  }
}

/// 浮动歌词菜单的轻量逐字高亮：只改变颜色和右侧羽化，不改变排版。
class _SimpleKaraokeText extends StatelessWidget {
  const _SimpleKaraokeText({
    required this.text,
    required this.words,
    required this.position,
    required this.fontSize,
    required this.baseAlpha,
    required this.highlightAlpha,
  });

  final String text;
  final List<LyricWord> words;
  final Duration position;
  final double fontSize;
  final double baseAlpha;
  final double highlightAlpha;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      height: 1,
      fontWeight: FontWeight(480),
    );
    return CustomPaint(
      painter: _SimpleKaraokePainter(
        text: text,
        words: words,
        position: position,
        style: style,
        baseAlpha: baseAlpha,
        highlightAlpha: highlightAlpha,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(color: Colors.transparent),
      ),
    );
  }
}

class _SimpleKaraokePainter extends CustomPainter {
  _SimpleKaraokePainter({
    required this.text,
    required this.words,
    required this.position,
    required this.style,
    required this.baseAlpha,
    required this.highlightAlpha,
  }) : _ranges = _simpleKaraokeWordRanges(text, words);

  final String text;
  final List<LyricWord> words;
  final Duration position;
  final TextStyle style;
  final double baseAlpha;
  final double highlightAlpha;
  final List<(int, int)> _ranges;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width);
    final brightPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width);

    final base = baseAlpha.clamp(0.0, 1.0);
    if (base < 1) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withAlpha((base * 255).round()),
      );
    }
    painter.paint(canvas, Offset.zero);
    if (base < 1) canvas.restore();

    for (var index = 0; index < words.length; index++) {
      final range = index < _ranges.length ? _ranges[index] : (0, 0);
      if (range.$2 <= range.$1) continue;
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: range.$1, extentOffset: range.$2),
      );
      if (boxes.isEmpty) continue;

      final word = words[index];
      final end =
          word.end ??
          (index + 1 < words.length
              ? words[index + 1].start
              : word.start + const Duration(milliseconds: 350));
      final duration = end - word.start;
      final progress = duration <= Duration.zero
          ? (position >= word.start ? 1.0 : 0.0)
          : ((position - word.start).inMicroseconds / duration.inMicroseconds)
                .clamp(0.0, 1.0);
      if (progress <= 0) continue;

      for (final box in boxes) {
        final rect = box.toRect();
        if (rect.isEmpty) continue;
        if (progress >= 1) {
          canvas.save();
          canvas.clipRect(rect);
          brightPainter.paint(canvas, Offset.zero);
          canvas.restore();
          continue;
        }

        final feather = math.min(.45, rect.height * .6 / rect.width);
        final leadingStop = (progress - feather / 2).clamp(0.0, 1.0);
        final trailingStop = (progress + feather / 2).clamp(0.0, 1.0);
        final shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Colors.white,
            Colors.white,
            Colors.transparent,
            Colors.transparent,
          ],
          stops: [0, leadingStop, trailingStop, 1],
        ).createShader(rect);

        canvas.saveLayer(
          rect,
          Paint()
            ..color = Colors.white.withAlpha(
              (highlightAlpha.clamp(0.0, 1.0) * 255).round(),
            ),
        );
        canvas.clipRect(rect);
        brightPainter.paint(canvas, Offset.zero);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = shader
            ..blendMode = BlendMode.dstIn,
        );
        canvas.restore();
      }
    }

    painter.dispose();
    brightPainter.dispose();
  }

  @override
  bool shouldRepaint(covariant _SimpleKaraokePainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.words != words ||
      oldDelegate.position != position ||
      oldDelegate.style != style ||
      oldDelegate.baseAlpha != baseAlpha ||
      oldDelegate.highlightAlpha != highlightAlpha;
}

List<(int, int)> _simpleKaraokeWordRanges(String text, List<LyricWord> words) {
  final ranges = <(int, int)>[];
  var cursor = 0;
  for (final word in words) {
    var start = text.indexOf(word.text, cursor);
    if (start < 0) start = cursor;
    final end = math.min(text.length, start + word.text.length);
    ranges.add((start, end));
    cursor = end;
  }
  return ranges;
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
