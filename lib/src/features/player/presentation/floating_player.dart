import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/database/app_database.dart';
import '../application/player_controller.dart';
import '../domain/lyrics.dart';
import '../domain/track.dart';
import 'amll_playback_route.dart';
import 'playback_progress_circle.dart';

const _circleSize = playbackCircleSize;
const _ringSize = playbackRingSize;
const _ringInset = (_ringSize - _circleSize) / 2;
const _positionExtent = 96.0;
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
  bool _touchPointerDown = false;
  bool _touchMenuWasExpandedOnDown = false;
  bool _touchMenuExpanded = false;
  Timer? _hoverExitTimer;
  Timer? _touchCollapseTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFloatingPosition());
  }

  @override
  void dispose() {
    _hoverExitTimer?.cancel();
    _touchCollapseTimer?.cancel();
    super.dispose();
  }

  Offset _toLocal(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);
    final track = state.currentTrack;

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
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
              if (_dragging)
                Positioned.fill(
                  key: const ValueKey('floating-player-drag-backdrop'),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: ColoredBox(color: Colors.black.withAlpha(45)),
                  ),
                ),
              if (_touchMenuExpanded)
                Positioned.fill(
                  key: const ValueKey('floating-player-touch-dismiss-layer'),
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) {
                      if (_isTouchPointer(event.kind)) {
                        _dismissTouchMenu();
                      }
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              Positioned.fill(
                key: const ValueKey('floating-player-cluster'),
                child: _FloatingCluster(
                  position: center,
                  track: track,
                  state: state,
                  hovered: _hovered,
                  dragging: _dragging,
                  touchMenuExpanded: _touchMenuExpanded,
                  seekPreviewProgress: _seekPreviewProgress,
                  showAbove: showAbove,
                  showLeft: showLeft,
                  onHover: _setHovered,
                  onPointerDown: (event) {
                    final pointer = _toLocal(event.position);
                    _touchPointerDown = _isTouchPointer(event.kind);
                    _pointerDownPosition = pointer;
                    _seeking = _isNearSeekHandle(
                      pointer,
                      circleCenter,
                      _progress(state),
                    );
                    if (_touchPointerDown) {
                      _touchMenuWasExpandedOnDown = _touchMenuExpanded;
                      // 触摸在按下时就开始展开，和鼠标进入圆形区域时的时机一致；
                      // 抬起事件只负责区分“展开菜单”与“进入播放页”。
                      if (!_seeking && !_touchMenuExpanded) {
                        _expandTouchMenu();
                      }
                    }
                  },
                  onDragStart: (details) {
                    _hoverExitTimer?.cancel();
                    // 拖拽识别器可能越过触发阈值后才回调，起点必须使用按下位置，
                    // 避免把进度环手柄误判成封面移动。
                    _dragStart =
                        (_pointerDownPosition ?? _toLocal(details.globalPosition)) -
                        center;
                    _seekPreviewProgress = _seeking ? _progress(state) : null;
                    setState(() {
                      _hovered = true;
                      _dragging = true;
                      if (_touchPointerDown) _touchMenuExpanded = true;
                    });
                  },
                  onDragUpdate: (details) {
                    final pointer = _toLocal(details.globalPosition);
                    if (_seeking) {
                      final vector = pointer - circleCenter;
                      final angle = math.atan2(vector.dy, vector.dx);
                      final progress =
                          ((angle + math.pi / 2) / (math.pi * 2)) % 1;
                      setState(() => _seekPreviewProgress = progress);
                      return;
                    }
                    final position = _clampPosition(
                      pointer - (_dragStart ?? Offset.zero),
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
                      _touchPointerDown = false;
                      _touchMenuWasExpandedOnDown = false;
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
                      _touchPointerDown = false;
                      _touchMenuWasExpandedOnDown = false;
                      return;
                    }
                    if (_touchPointerDown) {
                      final wasExpanded = _touchMenuWasExpandedOnDown;
                      _touchPointerDown = false;
                      _touchMenuWasExpandedOnDown = false;
                      if (!wasExpanded) return;
                    }
                    _openPlaybackPage(context, circleCenter);
                  },
                  onOpenPlaybackPage: () =>
                      _openPlaybackPage(context, circleCenter),
                  onLongPress: () {
                    if (!_touchPointerDown) return;
                    _expandTouchMenu();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPlaybackPage(BuildContext context, Offset localSourceCenter) {
    _hoverExitTimer?.cancel();
    _touchCollapseTimer?.cancel();
    setState(() {
      _hovered = false;
      _touchMenuExpanded = false;
      _touchPointerDown = false;
    });
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
      _touchCollapseTimer?.cancel();
      if (!_hovered) setState(() => _hovered = true);
      return;
    }
    if (_touchMenuExpanded) return;
    // 给光标从圆移动到面板留出时间，避免经过透明间隙时面板立即收回。
    _hoverExitTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _hovered = false);
    });
  }

  void _dismissTouchMenu() {
    if (!_touchMenuExpanded || !mounted) return;
    _hoverExitTimer?.cancel();
    _touchCollapseTimer?.cancel();

    // 保留拦截层直到收起动画结束。若先移除拦截层，触摸事件会在同一帧
    // 重新命中下方内容，导致菜单直接消失而没有反向动画。
    setState(() => _hovered = false);
    _touchCollapseTimer = Timer(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      setState(() => _touchMenuExpanded = false);
      _touchCollapseTimer = null;
    });
  }

  void _expandTouchMenu() {
    if (!mounted) return;
    _hoverExitTimer?.cancel();
    _touchCollapseTimer?.cancel();
    setState(() {
      _touchMenuExpanded = true;
      _hovered = true;
    });
  }

  Offset _clampPosition(Offset position, Size size) {
    final minimum = Offset(_ringInset + 8, _ringInset + 8);
    final maximum = Offset(
      math.max(minimum.dx, size.width - _positionExtent),
      math.max(minimum.dy, size.height - _positionExtent),
    );
    return Offset(
      position.dx.clamp(minimum.dx, maximum.dx).toDouble(),
      position.dy.clamp(minimum.dy, maximum.dy).toDouble(),
    );
  }

  Offset _positionForSize(Size size) {
    final minimum = Offset(_ringInset + 8, _ringInset + 8);
    final maximum = Offset(
      math.max(minimum.dx, size.width - _positionExtent),
      math.max(minimum.dy, size.height - _positionExtent),
    );
    return Offset(
      lerpDouble(minimum.dx, maximum.dx, _positionFactor.dx)!,
      lerpDouble(minimum.dy, maximum.dy, _positionFactor.dy)!,
    );
  }

  Offset _factorForPosition(Offset position, Size size) {
    final minimum = Offset(_ringInset + 8, _ringInset + 8);
    final maximum = Offset(
      math.max(minimum.dx, size.width - _positionExtent),
      math.max(minimum.dy, size.height - _positionExtent),
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
      if (!mounted || value == null || _dragging) return;
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
    Offset localPointer,
    Offset circleCenter,
    double progress,
  ) {
    if (!_hovered) return false;
    final vector = localPointer - circleCenter;
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

  bool _isTouchPointer(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.touch || kind == PointerDeviceKind.stylus;
}

class _FloatingCluster extends ConsumerWidget {
  const _FloatingCluster({
    required this.position,
    required this.track,
    required this.state,
    required this.hovered,
    required this.dragging,
    required this.touchMenuExpanded,
    required this.seekPreviewProgress,
    required this.showAbove,
    required this.showLeft,
    required this.onHover,
    required this.onPointerDown,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
    required this.onOpenPlaybackPage,
    required this.onLongPress,
  });

  final Offset position;
  final Track track;
  final PlayerState state;
  final bool hovered;
  final bool dragging;
  final bool touchMenuExpanded;
  final double? seekPreviewProgress;
  final bool showAbove;
  final bool showLeft;
  final ValueChanged<bool> onHover;
  final ValueChanged<PointerDownEvent> onPointerDown;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onTap;
  final VoidCallback onOpenPlaybackPage;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyrics = _lyricsDocument(track);
    final currentLine = _currentLyric(lyrics, state.position);
    final lyricPosition = state.position - lyrics.offset;
    final controller = ref.read(playerControllerProvider.notifier);
    final panelsExpanded = hovered || dragging;
    final bubbleContent = Column(
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
    );
    final infoContent = Column(
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
              height: 1,
              decoration: TextDecoration.none,
            ),
            textHeightBehavior: _floatingLyricTextHeightBehavior,
          )
        else ...[
          _LyricPreviewLine(
            line: currentLine,
            position: lyricPosition,
            animate: panelsExpanded && state.isPlaying,
          ),
          if (currentLine.translation != null)
            _LyricPreviewVariant(text: currentLine.translation!),
          for (final variant in currentLine.variants)
            _LyricPreviewVariant(text: variant.text),
        ],
      ],
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
      childBuilder: (progress) => panel(
        Padding(
          padding: infoOuterPadding,
          child: _MorphingGlassBubble(
            expansion: progress,
            maxWidth: MediaQuery.sizeOf(context).width * .4,
            collapseToHeight: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            child: infoContent,
          ),
        ),
      ),
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
      childBuilder: (progress) => panel(
        Padding(
          padding: controlOuterPadding,
          child: _MorphingGlassBubble(
            expansion: progress,
            child: bubbleContent,
          ),
        ),
      ),
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
                onLongPress: onLongPress,
                onPanStart: onDragStart,
                onPanUpdate: onDragUpdate,
                onPanEnd: onDragEnd,
                // 只裁切内部封面。进度环和手柄位于封面外侧，若在这里裁切
                // 整个组件，手柄经过圆周边缘时会被截断。
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PlaybackProgressCircle(
                      track: track,
                      progress: seekPreviewProgress ?? _progress(state),
                      bufferProgress: state.beatAnalysisProgress,
                      hovered: hovered,
                      dragging: dragging,
                      touchMenuExpanded: touchMenuExpanded,
                      onOpenPlaybackPage: onOpenPlaybackPage,
                    ),
                  ],
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
    required this.childBuilder,
  });

  final bool expanded;
  final bool instant;
  final Offset collapsedAnchor;
  final Offset expandedAnchor;
  final Offset collapsedTranslation;
  final Offset expandedTranslation;
  final Widget Function(double progress) childBuilder;

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
          child: FractionalTranslation(
            translation: translation,
            child: widget.childBuilder(progress),
          ),
        );
      },
    );
  }
}

class _MorphingGlassBubble extends StatefulWidget {
  const _MorphingGlassBubble({
    required this.child,
    required this.expansion,
    this.contentPadding = const EdgeInsets.all(8),
    this.collapseToHeight = false,
    this.maxWidth,
  });

  final Widget child;
  final double expansion;
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
    final expandedSize = _expandedSize(context);
    final collapsedSize = math.min(
      widget.collapseToHeight ? expandedSize.height : expandedSize.width,
      _circleSize,
    );
    final expansion = widget.expansion.clamp(0.0, 1.0).toDouble();
    final size = Size.lerp(
      Size.square(collapsedSize),
      expandedSize,
      expansion,
    )!;
    final maxContentWidth = math.max(
      1.0,
      (widget.maxWidth ?? expandedSize.width) -
          widget.contentPadding.horizontal,
    );

    return Container(
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
            padding: EdgeInsets.lerp(
              EdgeInsets.zero,
              widget.contentPadding,
              expansion,
            )!,
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
  const _LyricPreviewLine({
    required this.line,
    required this.position,
    required this.animate,
  });

  final LyricLine line;
  final Duration position;
  final bool animate;

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
          decoration: TextDecoration.none,
        ),
        textHeightBehavior: _floatingLyricTextHeightBehavior,
      );
    }

    return _SimpleKaraokeText(
      text: line.text,
      words: line.words,
      position: position,
      animate: animate,
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
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 14,
        height: 1,
        decoration: TextDecoration.none,
      ),
      textHeightBehavior: _floatingLyricTextHeightBehavior,
    );
  }
}

const _floatingLyricTextHeightBehavior = TextHeightBehavior(
  // 两端都参与行高分配，单行歌词放进气泡后才能按完整行框垂直居中。
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
);

/// 浮动歌词菜单的轻量逐字高亮：缓存排版结果，动画帧只更新绘制进度。
class _SimpleKaraokeText extends StatefulWidget {
  const _SimpleKaraokeText({
    required this.text,
    required this.words,
    required this.position,
    required this.animate,
    required this.fontSize,
    required this.baseAlpha,
    required this.highlightAlpha,
  });

  final String text;
  final List<LyricWord> words;
  final Duration position;
  final bool animate;
  final double fontSize;
  final double baseAlpha;
  final double highlightAlpha;

  @override
  State<_SimpleKaraokeText> createState() => _SimpleKaraokeTextState();
}

class _SimpleKaraokeTextState extends State<_SimpleKaraokeText>
    with SingleTickerProviderStateMixin {
  _SimpleKaraokeLayout? _layout;
  Object? _layoutSignature;
  late final Ticker _ticker;
  late final ValueNotifier<Duration> _visualPosition;
  final Stopwatch _clock = Stopwatch();
  late Duration _anchorPosition;

  @override
  void initState() {
    super.initState();
    _anchorPosition = widget.position;
    _visualPosition = ValueNotifier(widget.position);
    _ticker = createTicker(_tick);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant _SimpleKaraokeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lyricChanged =
        oldWidget.text != widget.text || oldWidget.words != widget.words;
    if (lyricChanged || oldWidget.position != widget.position) {
      _anchorPosition = widget.position;
      _clock
        ..stop()
        ..reset();
      if (widget.animate) _clock.start();
      _visualPosition.value = widget.position;
    }
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.animate) {
      if (!_clock.isRunning) _clock.start();
      if (!_ticker.isActive) _ticker.start();
    } else {
      _clock.stop();
      if (_ticker.isActive) _ticker.stop();
      _visualPosition.value = widget.position;
    }
  }

  void _tick(Duration _) {
    final position = _anchorPosition + _clock.elapsed;
    if (_visualPosition.value != position) _visualPosition.value = position;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _layoutSignature = null;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _visualPosition.dispose();
    _layout?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: widget.fontSize,
      height: 1,
      fontWeight: FontWeight(480),
      decoration: TextDecoration.none,
    );
    final signature = Object.hashAll([
      widget.text,
      widget.words,
      style,
      widget.baseAlpha,
      widget.highlightAlpha,
      Directionality.of(context),
      Localizations.maybeLocaleOf(context),
      MediaQuery.textScalerOf(context),
    ]);
    if (_layoutSignature != signature) {
      _layout?.dispose();
      _layout = _SimpleKaraokeLayout(
        text: widget.text,
        words: widget.words,
        style: style,
        baseAlpha: widget.baseAlpha,
        highlightAlpha: widget.highlightAlpha,
        textDirection: Directionality.of(context),
        locale: Localizations.maybeLocaleOf(context),
        textScaler: MediaQuery.textScalerOf(context),
      );
      _layoutSignature = signature;
    }
    final layout = _layout!;
    return Semantics(
      label: widget.text,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SimpleKaraokePainter(
            layout: layout,
            words: widget.words,
            positionListenable: _visualPosition,
          ),
          child: SizedBox(width: layout.width, height: layout.height),
        ),
      ),
    );
  }
}

class _SimpleKaraokeLayout {
  _SimpleKaraokeLayout({
    required String text,
    required List<LyricWord> words,
    required TextStyle style,
    required double baseAlpha,
    required double highlightAlpha,
    required TextDirection textDirection,
    required Locale? locale,
    required TextScaler textScaler,
  }) : basePainter = TextPainter(
         text: TextSpan(
           text: text,
           style: style.copyWith(
             color: (style.color ?? Colors.white).withAlpha(
               (baseAlpha.clamp(0.0, 1.0) * 255).round(),
             ),
           ),
         ),
         textDirection: textDirection,
         textAlign: TextAlign.start,
         locale: locale,
         textScaler: textScaler,
         textHeightBehavior: _floatingLyricTextHeightBehavior,
         maxLines: 1,
       )..layout(),
       brightPainter = TextPainter(
         text: TextSpan(
           text: text,
           style: style.copyWith(
             color: (style.color ?? Colors.white).withAlpha(
               (highlightAlpha.clamp(0.0, 1.0) * 255).round(),
             ),
           ),
         ),
         textDirection: textDirection,
         textAlign: TextAlign.start,
         locale: locale,
         textScaler: textScaler,
         textHeightBehavior: _floatingLyricTextHeightBehavior,
         maxLines: 1,
       )..layout(),
       ranges = _simpleKaraokeWordRanges(text, words) {
    boxes = [
      for (final range in ranges)
        basePainter.getBoxesForSelection(
          TextSelection(baseOffset: range.$1, extentOffset: range.$2),
        ),
    ];
  }

  final TextPainter basePainter;
  final TextPainter brightPainter;
  final List<(int, int)> ranges;
  late final List<List<TextBox>> boxes;

  double get width => basePainter.width;
  double get height => basePainter.height;

  void dispose() {
    basePainter.dispose();
    brightPainter.dispose();
  }
}

class _SimpleKaraokePainter extends CustomPainter {
  _SimpleKaraokePainter({
    required this.layout,
    required this.words,
    required this.positionListenable,
  }) : super(repaint: positionListenable);

  final _SimpleKaraokeLayout layout;
  final List<LyricWord> words;
  final ValueListenable<Duration> positionListenable;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final completedPath = Path();
    final partialBoxes = <(Rect, double)>[];
    var focusX = 0.0;
    final position = positionListenable.value;

    for (var index = 0; index < words.length; index++) {
      final boxes = index < layout.boxes.length
          ? layout.boxes[index]
          : const <TextBox>[];
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
      final firstRect = boxes.first.toRect();
      final lastRect = boxes.last.toRect();
      if (progress <= 0) break;
      focusX = lerpDouble(firstRect.left, lastRect.right, progress)!;
      for (final box in boxes) {
        final rect = box.toRect();
        if (rect.isEmpty) continue;
        if (progress >= 1) {
          completedPath.addRect(rect);
          continue;
        }
        partialBoxes.add((rect, progress));
      }
      if (progress < 1) break;
    }

    final maxScroll = math.max(0.0, layout.width - size.width);
    final scrollOffset = (focusX - size.width / 2)
        .clamp(0.0, maxScroll)
        .toDouble();
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(-scrollOffset, 0);
    layout.basePainter.paint(canvas, Offset.zero);
    if (!completedPath.getBounds().isEmpty) {
      canvas
        ..save()
        ..clipPath(completedPath);
      layout.brightPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
    for (final partial in partialBoxes) {
      final rect = partial.$1;
      final progress = partial.$2;
      final feather = rect.width <= 0
          ? 0.0
          : math.min(.45, rect.height * .6 / rect.width);
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
      canvas.saveLayer(rect, Paint());
      canvas.clipRect(rect);
      layout.brightPainter.paint(canvas, Offset.zero);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SimpleKaraokePainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.words != words ||
      oldDelegate.positionListenable != positionListenable;
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
  var low = 0;
  var high = document.lines.length - 1;
  var result = -1;
  while (low <= high) {
    final middle = low + ((high - low) >> 1);
    if (document.lines[middle].start <= adjusted) {
      result = middle;
      low = middle + 1;
    } else {
      high = middle - 1;
    }
  }
  if (result < 0) return null;
  final line = document.lines[result];
  final adjustedEnd = line.end;
  if (adjustedEnd != null && adjusted >= adjustedEnd) return null;
  return line;
}

double _progress(PlayerState state) {
  final duration = state.currentTrack.duration.inMilliseconds;
  if (duration <= 0) return 0;
  return (state.position.inMilliseconds / duration).clamp(0, 1).toDouble();
}
