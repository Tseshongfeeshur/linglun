import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show ValueListenable, precisionErrorTolerance;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_typography.dart';
import '../application/player_controller.dart';
import '../domain/lyrics.dart';
import '../domain/track.dart';
import 'lyric_emphasis.dart';

const _pageAnimationCurve = Curves.easeOutCubic;
const _lyricDefaultFontSize = 38.0;
const _lyricLetterSpacing = .1;
const _lyricMainFontWeight = FontWeight(450);
const _lyricTranslationFontWeight = FontWeight.w500;
const _lyricBackgroundFontWeight = FontWeight.w600;
const _lyricVerticalPaddingEm = .4;
const _lyricFocusPosition = 1 / 3;
const _lyricLineMotionDuration = Duration(milliseconds: 1400);
const _lyricLineStaggerBaseDelay = Duration(milliseconds: 28);
const _lyricLineStaggerCompression = 1.05;
const _lyricLineUpperLead = Duration(milliseconds: 36);
const _lyricSpringMass = 1.4;
// 欠阻尼使动画从零初速自然加速，并以小幅过冲逐步衰减到目标位置。
const _lyricSpringDampingRatio = .8;
const _synchronizedLyricScrollDuration = Duration(milliseconds: 480);
const _minimumInterludeGap = Duration(seconds: 7);
const _lyricAutoFollowDelay = Duration(seconds: 3);
const _lyricWheelScrollFactor = 4.0;

typedef _LyricSeekRequest = ({int generation, Duration position});

/// 让歌词滚轮采用短时缓动，避免 Linux 鼠标滚轮每个离散事件都瞬移一段距离。
class _SmoothLyricsScrollController extends ScrollController {
  _SmoothLyricsScrollController({this.onUserScroll});

  final VoidCallback? onUserScroll;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SmoothLyricsScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
      onUserScroll: onUserScroll,
    );
  }
}

class _SmoothLyricsScrollPosition extends ScrollPositionWithSingleContext {
  _SmoothLyricsScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
    this.onUserScroll,
  });

  final VoidCallback? onUserScroll;

  @override
  void pointerScroll(double delta) {
    if (delta == 0) {
      super.pointerScroll(delta);
      return;
    }

    final target = (pixels + delta * _lyricWheelScrollFactor).clamp(
      minScrollExtent,
      maxScrollExtent,
    );
    if ((target - pixels).abs() <= precisionErrorTolerance) return;

    // 新的滚轮事件会自然打断上一段短动画，从而兼容连续滚轮和触控板输入。
    onUserScroll?.call();
    unawaited(
      animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

/// AMLL 风格的首个播放页：宽屏突出封面与歌词双栏，窄屏切换为歌词主视图。
class AmllPlaybackPage extends StatefulWidget {
  const AmllPlaybackPage({
    required this.track,
    required this.state,
    required this.onClose,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
    required this.onSeek,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
    required this.onPlayTrack,
    super.key,
  });

  final Track track;
  final PlayerState state;
  final VoidCallback onClose;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;
  final ValueChanged<Track> onPlayTrack;

  @override
  State<AmllPlaybackPage> createState() => _AmllPlaybackPageState();
}

class _AmllPlaybackPageState extends State<AmllPlaybackPage> {
  bool _portraitLyricsVisible = false;
  bool _showQueue = false;
  bool _showRemainingTime = false;
  late final ValueNotifier<_LyricSeekRequest> _seekRequest;

  @override
  void initState() {
    super.initState();
    _seekRequest = ValueNotifier((generation: 0, position: Duration.zero));
  }

  @override
  void dispose() {
    _seekRequest.dispose();
    super.dispose();
  }

  void _handleSeek(Duration position) {
    final previous = _seekRequest.value;
    _seekRequest.value = (
      generation: previous.generation + 1,
      position: position,
    );
    widget.onSeek(position);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _AmllAmbientBackground(
          track: widget.track,
          color: Color(widget.track.coverColor),
        ),
        SafeArea(
          child: Column(
            children: [
              _PageHeader(onClose: widget.onClose),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= constraints.maxHeight;
                    return wide
                        ? _WidePlaybackLayout(
                            track: widget.track,
                            state: widget.state,
                            seekRequest: _seekRequest,
                            onSeek: _handleSeek,
                            showRemainingTime: _showRemainingTime,
                            onRemainingTimeChanged: (value) =>
                                setState(() => _showRemainingTime = value),
                            onPrevious: widget.onPrevious,
                            onTogglePlay: widget.onTogglePlay,
                            onNext: widget.onNext,
                            onToggleShuffle: widget.onToggleShuffle,
                            onCycleRepeat: widget.onCycleRepeat,
                          )
                        : _NarrowPlaybackLayout(
                            track: widget.track,
                            state: widget.state,
                            seekRequest: _seekRequest,
                            onSeek: _handleSeek,
                            showLyrics: _portraitLyricsVisible,
                            onToggleLyrics: () => setState(
                              () => _portraitLyricsVisible =
                                  !_portraitLyricsVisible,
                            ),
                            showRemainingTime: _showRemainingTime,
                            onRemainingTimeChanged: (value) =>
                                setState(() => _showRemainingTime = value),
                            onPrevious: widget.onPrevious,
                            onTogglePlay: widget.onTogglePlay,
                            onNext: widget.onNext,
                            onToggleShuffle: widget.onToggleShuffle,
                            onCycleRepeat: widget.onCycleRepeat,
                          );
                  },
                ),
              ),
              _PageFooter(
                showQueue: _showQueue,
                onToggleQueue: () => setState(() => _showQueue = !_showQueue),
              ),
            ],
          ),
        ),
        if (_showQueue)
          _QueueOverlay(
            state: widget.state,
            onClose: () => setState(() => _showQueue = false),
            onSelectTrack: (track) {
              widget.onPlayTrack(track);
              setState(() => _showQueue = false);
            },
          ),
      ],
    );
  }
}

class _AmllAmbientBackground extends StatefulWidget {
  const _AmllAmbientBackground({required this.track, required this.color});

  final Track track;
  final Color color;

  @override
  State<_AmllAmbientBackground> createState() => _AmllAmbientBackgroundState();
}

class _AmllAmbientBackgroundState extends State<_AmllAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambientController,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.track.coverBytes != null)
            Transform.scale(
              scale: 1.24,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 56, sigmaY: 56),
                child: Image.memory(
                  widget.track.coverBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            )
          else
            ColoredBox(color: widget.color),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x66333B3F),
                  Color(0xCC101315),
                  Color(0xF20A0C0D),
                ],
              ),
            ),
          ),
          const ColoredBox(color: Color(0x55000000)),
        ],
      ),
      builder: (context, child) {
        final phase = Curves.easeInOutSine.transform(_ambientController.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AmbientWashPainter(
                    color: widget.color,
                    phase: phase,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AmbientWashPainter extends CustomPainter {
  const _AmbientWashPainter({required this.color, required this.phase});

  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final direction = .2 + phase * .6;
    final bounds = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-direction, -direction),
        end: Alignment(direction, direction),
        colors: [color.withAlpha(22), Colors.transparent, color.withAlpha(12)],
      ).createShader(bounds);
    canvas.drawRect(bounds, paint);
  }

  @override
  bool shouldRepaint(_AmbientWashPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.phase != phase;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            onPressed: onClose,
            tooltip: '收起播放页',
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _WidePlaybackLayout extends StatelessWidget {
  const _WidePlaybackLayout({
    required this.track,
    required this.state,
    required this.seekRequest,
    required this.onSeek,
    required this.showRemainingTime,
    required this.onRemainingTimeChanged,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
  });

  final Track track;
  final PlayerState state;
  final ValueListenable<_LyricSeekRequest> seekRequest;
  final ValueChanged<Duration> onSeek;
  final bool showRemainingTime;
  final ValueChanged<bool> onRemainingTimeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 26, 0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox.expand(
              key: const ValueKey('wide-track-pane'),
              child: _WideTrackColumn(
                track: track,
                state: state,
                showRemainingTime: showRemainingTime,
                onRemainingTimeChanged: onRemainingTimeChanged,
                onPrevious: onPrevious,
                onTogglePlay: onTogglePlay,
                onNext: onNext,
                onSeek: onSeek,
                onToggleShuffle: onToggleShuffle,
                onCycleRepeat: onCycleRepeat,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: SizedBox.expand(
              key: const ValueKey('wide-lyrics-pane'),
              child: _LyricsViewport(
                key: const ValueKey('wide-lyrics'),
                track: track,
                state: state,
                onSeek: onSeek,
                seekRequest: seekRequest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideTrackColumn extends StatelessWidget {
  const _WideTrackColumn({
    required this.track,
    required this.state,
    required this.showRemainingTime,
    required this.onRemainingTimeChanged,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
    required this.onSeek,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
  });

  final Track track;
  final PlayerState state;
  final bool showRemainingTime;
  final ValueChanged<bool> onRemainingTimeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context);
        final standardCoverSize = math.min(
          math.min(viewport.height * .45, viewport.width * .38),
          math.min(constraints.maxWidth, constraints.maxHeight),
        );
        final coverDetailsGap = _wideCoverDetailsGap(constraints.maxHeight);
        final coverSize = standardCoverSize;
        return Center(
          child: SizedBox(
            key: const ValueKey('wide-track-content'),
            width: coverSize,
            child: Column(
              key: const ValueKey('wide-track-stack'),
              mainAxisSize: MainAxisSize.min,
              children: [
                _AlbumCover(track: track, size: coverSize),
                SizedBox(
                  key: const ValueKey('wide-cover-details-gap'),
                  height: coverDetailsGap,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TrackMetadata(
                      track: track,
                      compact: false,
                      alignStart: true,
                      horizontalArtistsAlbum: true,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      key: const ValueKey('seek-control-container'),
                      child: _SeekControl(
                        width: coverSize,
                        track: track,
                        position: state.position,
                        showRemainingTime: showRemainingTime,
                        onRemainingTimeChanged: onRemainingTimeChanged,
                        onSeek: onSeek,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      key: const ValueKey('playback-controls-container'),
                      child: _PlaybackControls(
                        state: state,
                        onPrevious: onPrevious,
                        onTogglePlay: onTogglePlay,
                        onNext: onNext,
                        onToggleShuffle: onToggleShuffle,
                        onCycleRepeat: onCycleRepeat,
                        compact: coverSize < 320,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NarrowPlaybackLayout extends StatefulWidget {
  const _NarrowPlaybackLayout({
    required this.track,
    required this.state,
    required this.seekRequest,
    required this.onSeek,
    required this.showLyrics,
    required this.onToggleLyrics,
    required this.showRemainingTime,
    required this.onRemainingTimeChanged,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
  });

  final Track track;
  final PlayerState state;
  final ValueListenable<_LyricSeekRequest> seekRequest;
  final ValueChanged<Duration> onSeek;
  final bool showLyrics;
  final VoidCallback onToggleLyrics;
  final bool showRemainingTime;
  final ValueChanged<bool> onRemainingTimeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;

  @override
  State<_NarrowPlaybackLayout> createState() => _NarrowPlaybackLayoutState();
}

class _NarrowPlaybackLayoutState extends State<_NarrowPlaybackLayout> {
  final _coverKey = GlobalKey();
  double? _renderedCoverWidth;

  void _measureCoverAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.showLyrics) return;
      final renderObject = _coverKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final width = renderObject.size.width;
      if (_renderedCoverWidth == null ||
          (width - _renderedCoverWidth!).abs() > .01) {
        setState(() => _renderedCoverWidth = width);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _measureCoverAfterLayout();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final controlCoverSize = math
              .min(width * .76, height * .58)
              .toDouble();
          final seekWidth = widget.showLyrics
              ? controlCoverSize
              : (_renderedCoverWidth ?? controlCoverSize);
          return Column(
            children: [
              Expanded(
                child: _PortraitMainArea(
                  track: widget.track,
                  state: widget.state,
                  showLyrics: widget.showLyrics,
                  onToggleLyrics: widget.onToggleLyrics,
                  onSeek: widget.onSeek,
                  seekRequest: widget.seekRequest,
                  controlCoverSize: controlCoverSize,
                  coverKey: _coverKey,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                key: const ValueKey('seek-control-container'),
                width: seekWidth,
                child: _SeekControl(
                  width: seekWidth,
                  track: widget.track,
                  position: widget.state.position,
                  showRemainingTime: widget.showRemainingTime,
                  onRemainingTimeChanged: widget.onRemainingTimeChanged,
                  onSeek: widget.onSeek,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                key: const ValueKey('playback-controls-container'),
                width: seekWidth,
                child: _PlaybackControls(
                  state: widget.state,
                  onPrevious: widget.onPrevious,
                  onTogglePlay: widget.onTogglePlay,
                  onNext: widget.onNext,
                  onToggleShuffle: widget.onToggleShuffle,
                  onCycleRepeat: widget.onCycleRepeat,
                  compact: true,
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

class _PortraitMainArea extends StatelessWidget {
  const _PortraitMainArea({
    required this.track,
    required this.state,
    required this.showLyrics,
    required this.onToggleLyrics,
    required this.onSeek,
    required this.seekRequest,
    required this.controlCoverSize,
    required this.coverKey,
  });

  final Track track;
  final PlayerState state;
  final bool showLyrics;
  final VoidCallback onToggleLyrics;
  final ValueChanged<Duration> onSeek;
  final ValueListenable<_LyricSeekRequest> seekRequest;
  final double controlCoverSize;
  final GlobalKey coverKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final infoHeight = 66.0;
        final coverSize = math
            .min(controlCoverSize, math.max(0.0, height - infoHeight - 26))
            .toDouble();
        final initialTop = math
            .max(0.0, (height - coverSize - infoHeight - 18) / 2)
            .toDouble();
        final compactCoverSize = math
            .min(112.0, math.min(width * .27, height * .18))
            .toDouble();
        const infoGap = 16.0;
        final h = compactCoverSize + infoGap;
        final infoWidth = math.max(0.0, width - h).toDouble();
        final headerHeight = math.max(compactCoverSize, 86.0).toDouble();

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (showLyrics)
              Positioned(
                left: 0,
                right: 0,
                top: headerHeight + 12,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 350),
                  curve: _pageAnimationCurve,
                  child: _LyricsViewport(
                    key: const ValueKey('portrait-lyrics'),
                    track: track,
                    state: state,
                    onSeek: onSeek,
                    seekRequest: seekRequest,
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 560),
              curve: Curves.easeInOutCubic,
              left: showLyrics ? 0.0 : (width - coverSize) / 2,
              top: showLyrics ? 8.0 : initialTop,
              width: showLyrics ? compactCoverSize : coverSize,
              height: showLyrics ? compactCoverSize : coverSize,
              child: KeyedSubtree(
                key: coverKey,
                child: GestureDetector(
                  key: const ValueKey('portrait-cover-shared-element'),
                  onTap: onToggleLyrics,
                  child: _AlbumCoverArtwork(
                    key: const ValueKey('amll-album-cover'),
                    track: track,
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 560),
              curve: Curves.easeInOutCubic,
              left: showLyrics ? h : (width - infoWidth) / 2,
              top: showLyrics ? 8.0 : initialTop + coverSize + 16,
              // 两种状态始终使用同一个最大宽度，避免标题测量结果在过渡中反复变化。
              width: infoWidth,
              height: showLyrics ? headerHeight : infoHeight,
              child: Align(
                alignment: showLyrics
                    ? Alignment.centerLeft
                    : Alignment.topLeft,
                child: _TrackMetadata(
                  track: track,
                  compact: true,
                  alignStart: showLyrics,
                  horizontalArtistsAlbum: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlbumCover extends StatelessWidget {
  const _AlbumCover({required this.track, required this.size});

  final Track track;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: _AlbumCoverArtwork(
        key: const ValueKey('amll-album-cover'),
        track: track,
      ),
    );
  }
}

/// 封面图像本身独立出来，竖屏切换时可在同一个定位节点内做共享元素过渡。
class _AlbumCoverImage extends StatelessWidget {
  const _AlbumCoverImage({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return track.coverBytes == null
        ? ColoredBox(
            color: Color(track.coverColor),
            child: const Center(
              child: Icon(Icons.album_rounded, color: Colors.white70, size: 78),
            ),
          )
        : Image.memory(
            track.coverBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          );
  }
}

class _AlbumCoverArtwork extends StatelessWidget {
  const _AlbumCoverArtwork({required this.track, super.key});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final radius = math.max(10.0, size * .025);
        return SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(95),
                  blurRadius: size * .09,
                  spreadRadius: 2,
                  offset: Offset(0, size * .025),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: _AlbumCoverImage(track: track),
            ),
          ),
        );
      },
    );
  }
}

class _TrackMetadata extends StatelessWidget {
  const _TrackMetadata({
    required this.track,
    required this.compact,
    this.alignStart = false,
    this.horizontalArtistsAlbum = false,
  });

  final Track track;
  final bool compact;
  final bool alignStart;
  final bool horizontalArtistsAlbum;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 21 : 24,
      fontWeight: FontWeight.w600,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        _ScrollingTrackTitle(
          text: track.title,
          style: titleStyle,
          textAlign: alignStart ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 4),
        if (horizontalArtistsAlbum)
          Text(
            _artistAlbumLabel(track.artist, track.album),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              fontSize: compact ? 14 : 15,
            ),
          )
        else ...[
          Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: compact ? 15 : 16,
            ),
          ),
          if (track.album.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              track.album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignStart ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(135),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ScrollingTrackTitle extends StatefulWidget {
  const _ScrollingTrackTitle({
    required this.text,
    required this.style,
    required this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  State<_ScrollingTrackTitle> createState() => _ScrollingTrackTitleState();
}

class _ScrollingTrackTitleState extends State<_ScrollingTrackTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _startTimer;
  double _overflow = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void didUpdateWidget(covariant _ScrollingTrackTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _startTimer?.cancel();
      _controller
        ..stop()
        ..value = 0;
      _overflow = 0;
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _updateOverflow(double value) {
    if ((_overflow - value).abs() < .5) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (_overflow - value).abs() < .5) return;
      setState(() => _overflow = value);
      _startTimer?.cancel();
      _controller
        ..stop()
        ..value = 0;
      if (value > 0) {
        _startTimer = Timer.periodic(const Duration(seconds: 2), (_) {
          if (!mounted) return;
          final target = _controller.value < .5 ? 1.0 : 0.0;
          unawaited(
            _controller.animateTo(
              target,
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeInOutCubic,
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final naturalWidth = painter.width;
        final overflow = math.max(0.0, naturalWidth - constraints.maxWidth);
        _updateOverflow(overflow);
        return ClipRect(
          child: SizedBox(
            height: painter.height,
            width: constraints.maxWidth,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  -_overflow * Curves.easeInOut.transform(_controller.value),
                  0,
                ),
                child: child,
              ),
              child: SizedBox(
                width: math.max(naturalWidth, constraints.maxWidth),
                child: Text(
                  widget.text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: widget.textAlign,
                  style: widget.style,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeekControl extends StatefulWidget {
  const _SeekControl({
    required this.width,
    required this.track,
    required this.position,
    required this.showRemainingTime,
    required this.onRemainingTimeChanged,
    required this.onSeek,
  });

  final double width;
  final Track track;
  final Duration position;
  final bool showRemainingTime;
  final ValueChanged<bool> onRemainingTimeChanged;
  final ValueChanged<Duration> onSeek;

  @override
  State<_SeekControl> createState() => _SeekControlState();
}

class _SeekControlState extends State<_SeekControl> {
  double? _previewMs;
  bool _dragging = false;
  bool _hovered = false;

  @override
  void didUpdateWidget(covariant _SeekControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.position != widget.position) {
      _previewMs = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = math.max(1, widget.track.duration.inMilliseconds);
    final currentMs = _previewMs ?? widget.position.inMilliseconds.toDouble();
    final boundedMs = currentMs.clamp(0, durationMs.toDouble()).toDouble();
    final shownPosition = Duration(milliseconds: boundedMs.round());
    final rightTime = widget.showRemainingTime
        ? widget.track.duration - shownPosition
        : widget.track.duration;
    final showHandle = _hovered || _dragging;
    final trackHeight = _seekTrackHeight(MediaQuery.sizeOf(context).height);

    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: trackHeight,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withAlpha(65),
              // 始终保留相同的手柄和覆盖层尺寸，避免 Flutter 重新计算轨道
              // 两端内缩量；非悬浮时只隐藏绘制，不改变进度条几何尺寸。
              thumbColor: showHandle ? Colors.white : Colors.transparent,
              disabledThumbColor: Colors.transparent,
              overlayColor: showHandle
                  ? Colors.white.withAlpha(35)
                  : Colors.transparent,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 5,
                elevation: showHandle ? 1 : 0,
                pressedElevation: showHandle ? 6 : 0,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) {
                if (!_dragging) setState(() => _hovered = false);
              },
              child: Slider(
                min: 0,
                max: durationMs.toDouble(),
                value: boundedMs,
                onChangeStart: (_) => setState(() => _dragging = true),
                onChanged: widget.track.duration <= Duration.zero
                    ? null
                    : (value) => setState(() => _previewMs = value),
                onChangeEnd: (value) {
                  setState(() {
                    _previewMs = null;
                    _dragging = false;
                  });
                  widget.onSeek(Duration(milliseconds: value.round()));
                },
              ),
            ),
          ),
          SizedBox(
            key: const ValueKey('seek-time-row'),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              key: const ValueKey('seek-chip-row'),
              children: [
                Text(
                  _formatDuration(shownPosition),
                  maxLines: 1,
                  style: _timeTextStyle,
                ),
                Flexible(child: _AudioQualityBadge(track: widget.track)),
                Text(
                  widget.showRemainingTime
                      ? '-${_formatDuration(rightTime)}'
                      : _formatDuration(rightTime),
                  maxLines: 1,
                  style: _timeTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _timeTextStyle = TextStyle(
  color: Color(0xBFFFFFFF),
  fontSize: 11,
  fontFeatures: [ui.FontFeature.tabularFigures()],
);

double _seekTrackHeight(double windowHeight) {
  // 只做轻微变化，避免大窗口下进度条显得过重，小窗口下又过细。
  final progress = ((windowHeight - 600) / 500).clamp(0.0, 1.0);
  return 3 + progress * 1.2;
}

class _AudioQualityBadge extends StatelessWidget {
  const _AudioQualityBadge({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final format =
        track.metadata['文件格式'] ??
        (track.path?.split('.').last.toUpperCase() ?? '本地音频');
    final sampleRate = track.metadata['采样率'];
    final label = sampleRate == null ? format : '$format · $sampleRate';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withAlpha(80)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.state,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
    this.compact = false,
  });

  final PlayerState state;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mainSize = compact ? 50.0 : 58.0;
    final sideSize = compact ? 40.0 : 46.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onToggleShuffle,
          tooltip: state.shuffleEnabled ? '关闭随机播放' : '开启随机播放',
          color: state.shuffleEnabled
              ? Theme.of(context).colorScheme.primary
              : Colors.white.withAlpha(180),
          icon: const Icon(Icons.shuffle_rounded),
          iconSize: compact ? 19 : 21,
        ),
        IconButton(
          onPressed: onPrevious,
          tooltip: '上一曲',
          color: Colors.white,
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: sideSize,
        ),
        SizedBox.square(
          dimension: mainSize,
          child: IconButton.filled(
            onPressed: onTogglePlay,
            tooltip: state.isPlaying ? '暂停' : '播放',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF101315),
            ),
            icon: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: mainSize * .62,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: '下一曲',
          color: Colors.white,
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: sideSize,
        ),
        IconButton(
          onPressed: onCycleRepeat,
          tooltip: switch (state.repeatMode) {
            RepeatMode.off => '开启列表循环',
            RepeatMode.all => '切换单曲循环',
            RepeatMode.one => '关闭循环',
          },
          color: state.repeatMode == RepeatMode.off
              ? Colors.white.withAlpha(180)
              : Theme.of(context).colorScheme.primary,
          icon: Icon(
            state.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
          ),
          iconSize: compact ? 20 : 22,
        ),
      ],
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({required this.showQueue, required this.onToggleQueue});

  final bool showQueue;
  final VoidCallback onToggleQueue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 24),
          IconButton(
            onPressed: onToggleQueue,
            tooltip: showQueue ? '关闭播放队列' : '打开播放队列',
            color: showQueue
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withAlpha(185),
            icon: const Icon(Icons.queue_music_rounded),
            iconSize: 20,
          ),
          const Spacer(),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _LyricsViewport extends StatefulWidget {
  const _LyricsViewport({
    required this.track,
    required this.state,
    required this.onSeek,
    required this.seekRequest,
    super.key,
  });

  final Track track;
  final PlayerState state;
  final ValueChanged<Duration> onSeek;
  final ValueListenable<_LyricSeekRequest> seekRequest;

  @override
  State<_LyricsViewport> createState() => _LyricsViewportState();
}

class _LyricsViewportState extends State<_LyricsViewport>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _lineMotion;
  late final ValueNotifier<Duration> _playhead;
  late LyricsDocument _document;
  final Stopwatch _clock = Stopwatch();
  Duration _anchorPosition = Duration.zero;
  int _activeIndex = -1;
  int _scrollFocusIndex = -1;
  int _lineStaggerIndex = 0;
  int? _pendingActiveIndex;
  int? _pendingScrollFocusIndex;
  int _activeSyncGeneration = 0;
  Map<String, int> _speakerOrder = const {};
  double _lyricsWidth = 0;
  double _lyricsHeight = 0;
  double _listTopPadding = 0;
  double _listBottomPadding = 0;
  double _lyricFontSize = _lyricDefaultFontSize;
  bool _isLyricsHovered = false;
  Duration? _interludeResetPosition;
  double _lineScrollDelta = 0;
  bool _synchronizeLineMotion = false;
  bool _hasSyncedInitialFocus = false;
  Size? _previousLyricsSize;
  late final _SmoothLyricsScrollController _scrollController;
  Timer? _autoFollowTimer;
  bool _userScrollSuppressed = false;
  bool _userDragActive = false;
  bool _synchronizeNextLineMotion = false;
  bool _explicitSeekPending = false;
  Duration? _pendingSeekPosition;
  Duration? _seekOriginPosition;
  Timer? _seekReconciliationTimer;
  ({Duration start, Duration end, int anchor})? _visibleInterlude;
  int _interludeMotionAnchor = -2;
  double _interludeMotionOffset = 0;
  int _scrollAnimationGeneration = 0;
  late final VoidCallback _seekGenerationListener;

  @override
  void initState() {
    super.initState();
    _seekGenerationListener = _handleSeekGenerationChanged;
    widget.seekRequest.addListener(_seekGenerationListener);
    _scrollController = _SmoothLyricsScrollController(
      onUserScroll: _noteUserScroll,
    );
    _document = widget.track.lyricsDocument;
    _speakerOrder = _buildSpeakerOrder(_document);
    final initialPosition = widget.state.position;
    _anchorPosition = initialPosition;
    _playhead = ValueNotifier(initialPosition);
    _lineMotion = AnimationController(
      vsync: this,
      duration: _lyricLineMotionDuration,
      value: 1,
    )..addStatusListener(_handleLineMotionStatusChanged);
    _ticker = createTicker(_tick);
    if (widget.state.isPlaying) _clock.start();
    _setPlaying(widget.state.isPlaying);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncActiveLine(initialPosition);
    });
  }

  @override
  void didUpdateWidget(covariant _LyricsViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seekRequest != widget.seekRequest) {
      oldWidget.seekRequest.removeListener(_seekGenerationListener);
      widget.seekRequest.addListener(_seekGenerationListener);
    }
    final trackChanged = oldWidget.track.id != widget.track.id;
    final playbackChanged = oldWidget.state.isPlaying != widget.state.isPlaying;
    if (trackChanged) {
      _document = widget.track.lyricsDocument;
      _speakerOrder = _buildSpeakerOrder(_document);
      _interludeResetPosition = null;
      _activeIndex = -1;
      _scrollFocusIndex = -1;
      _pendingActiveIndex = null;
      _pendingScrollFocusIndex = null;
      _activeSyncGeneration++;
      _hasSyncedInitialFocus = false;
      _lineMotion.value = 1;
      _lineScrollDelta = 0;
      _synchronizeLineMotion = false;
      _autoFollowTimer?.cancel();
      _userScrollSuppressed = false;
      _userDragActive = false;
      _synchronizeNextLineMotion = false;
      _explicitSeekPending = false;
      _pendingSeekPosition = null;
      _seekOriginPosition = null;
      _seekReconciliationTimer?.cancel();
      _seekReconciliationTimer = null;
      _visibleInterlude = null;
      _interludeMotionAnchor = -2;
      _interludeMotionOffset = 0;
      _scrollAnimationGeneration++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
    if (trackChanged || playbackChanged) {
      final currentPosition = trackChanged
          ? widget.state.position
          : oldWidget.state.isPlaying
          ? _anchorPosition + _clock.elapsed
          : _playhead.value;
      _anchorPosition = currentPosition;
      _clock
        ..stop()
        ..reset();
      if (widget.state.isPlaying) _clock.start();
      _playhead.value = currentPosition;
      _syncActiveLine(currentPosition);
    } else if (oldWidget.state.position != widget.state.position) {
      final reported = widget.state.position;
      final estimated = _estimatedPlayhead;
      final correction = reported - estimated;
      final requested = _pendingSeekPosition;
      final seekOrigin = _seekOriginPosition;
      if (requested != null && seekOrigin != null) {
        final stalePosition = requested > seekOrigin
            ? reported < requested
            : requested < seekOrigin
            ? reported > requested
            : (reported - requested).abs() > const Duration(milliseconds: 40);
        if (stalePosition) {
          // 定位期间只接受已经越过目标的回报，防止相邻歌词间的旧位置回退。
          _setPlaying(widget.state.isPlaying);
          return;
        }
      }
      if (_explicitSeekPending) {
        // 定位请求已先更新本地播放头。旧位置回报被上面的方向检查过滤，
        // 只有确认方向正确后才重新锚定播放器时钟。
        _explicitSeekPending = false;
        _anchorPosition = reported;
        _clock
          ..stop()
          ..reset();
        if (widget.state.isPlaying) _clock.start();
        _playhead.value = reported;
        _syncActiveLine(reported);
      } else if (!widget.state.isPlaying ||
          correction.abs() >= const Duration(milliseconds: 450)) {
        // 大幅偏差通常表示用户跳转；常规播放器进度上报只做小幅校正。
        if (!_userScrollSuppressed) {
          _synchronizeNextLineMotion = true;
          _userScrollSuppressed = false;
          _userDragActive = false;
          _autoFollowTimer?.cancel();
          _autoFollowTimer = null;
        }
        _anchorPosition = reported;
        _clock
          ..stop()
          ..reset();
        if (widget.state.isPlaying) _clock.start();
        _playhead.value = reported;
        _syncActiveLine(reported);
      } else if (correction != Duration.zero) {
        _anchorPosition += Duration(
          microseconds: (correction.inMicroseconds * .12).round(),
        );
      }
    }
    _setPlaying(widget.state.isPlaying);
  }

  Duration get _estimatedPlayhead => widget.state.isPlaying
      ? _anchorPosition + _clock.elapsed
      : _playhead.value;

  @override
  void dispose() {
    _autoFollowTimer?.cancel();
    _seekReconciliationTimer?.cancel();
    widget.seekRequest.removeListener(_seekGenerationListener);
    _ticker.dispose();
    _lineMotion.dispose();
    _playhead.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setPlaying(bool isPlaying) {
    final needsTicker = isPlaying && _document.hasTimestamps;
    if (needsTicker && !_ticker.isActive) _ticker.start();
    if (!needsTicker && _ticker.isActive) _ticker.stop();
  }

  void _seekToLyric(Duration position) {
    _interludeResetPosition = position - _document.offset;
    widget.onSeek(position);
  }

  void _handleSeekGenerationChanged() {
    if (!mounted) return;
    final request = widget.seekRequest.value;
    _seekReconciliationTimer?.cancel();
    _seekOriginPosition = _playhead.value;
    _explicitSeekPending = true;
    _pendingSeekPosition = request.position;
    _interludeResetPosition = request.position - _document.offset;
    _anchorPosition = request.position;
    _clock
      ..stop()
      ..reset();
    if (widget.state.isPlaying) _clock.start();
    _playhead.value = request.position;
    _synchronizeNextLineMotion = true;
    _userScrollSuppressed = false;
    _userDragActive = false;
    _autoFollowTimer?.cancel();
    _autoFollowTimer = null;
    _syncActiveLine(request.position);
    _seekReconciliationTimer = Timer(const Duration(milliseconds: 900), () {
      _explicitSeekPending = false;
      _pendingSeekPosition = null;
      _seekOriginPosition = null;
      _seekReconciliationTimer = null;
    });
  }

  void _handleLineMotionStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _lineScrollDelta = 0;
    _interludeMotionAnchor = -2;
    _interludeMotionOffset = 0;
    _synchronizeLineMotion = false;
    if (mounted) setState(() {});
  }

  void _noteUserScroll() {
    // 让尚未执行的自动跟随回调失效，避免用户拖动后被旧回调拉回原处。
    _activeSyncGeneration++;
    _pendingActiveIndex = null;
    _pendingScrollFocusIndex = null;
    _scrollAnimationGeneration++;
    _userScrollSuppressed = true;
    _autoFollowTimer?.cancel();
    _autoFollowTimer = Timer(_lyricAutoFollowDelay, _resumeAutoFollow);
  }

  bool _handleLyricsScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;

    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userDragActive = true;
      _noteUserScroll();
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      _userDragActive = true;
      _noteUserScroll();
    } else if (notification is ScrollEndNotification && _userDragActive) {
      _userDragActive = false;
      _noteUserScroll();
    }
    return false;
  }

  void _resumeAutoFollow() {
    _autoFollowTimer = null;
    if (!mounted || _userDragActive) {
      if (_userDragActive) {
        _autoFollowTimer = Timer(_lyricAutoFollowDelay, _resumeAutoFollow);
      }
      return;
    }
    _userScrollSuppressed = false;
    if (!_hasSyncedInitialFocus ||
        !_scrollController.hasClients ||
        _lyricsWidth <= 0) {
      return;
    }

    final maxOffset = _scrollController.position.maxScrollExtent;
    if (_scrollFocusIndex < 0) {
      _scrollToInterlude(maxOffset, synchronize: true);
    } else {
      _scrollToLine(_scrollFocusIndex, maxOffset, synchronize: true);
    }
  }

  void _tick(Duration _) {
    final duration = _anchorPosition + _clock.elapsed;
    final limit = widget.track.duration;
    final nextPosition = limit > Duration.zero && duration > limit
        ? limit
        : duration;
    if (_playhead.value != nextPosition) {
      _playhead.value = nextPosition;
      _syncActiveLine(nextPosition);
    }
  }

  void _syncActiveLine(Duration position) {
    if (!_document.hasTimestamps) return;
    final adjustedPosition = position - _document.offset;
    final activeInterlude = _activeLyricInterlude(
      _document.lines,
      adjustedPosition,
    );
    final nextInterlude = _displayableInterlude(adjustedPosition);
    var nextIndex = _activeLineIndex(_document.lines, adjustedPosition);
    var nextScrollFocusIndex = nextIndex;
    if (activeInterlude != null) {
      nextIndex = -1;
      nextScrollFocusIndex = nextInterlude != null
          ? -1
          : math.min(_document.lines.length - 1, activeInterlude.anchor + 1);
    }
    final visibleIndex = _pendingActiveIndex ?? _activeIndex;
    final visibleFocusIndex = _pendingScrollFocusIndex ?? _scrollFocusIndex;
    final previousInterlude = _visibleInterlude;
    final interludeChanged = previousInterlude != nextInterlude;
    if (nextIndex == visibleIndex &&
        nextScrollFocusIndex == visibleFocusIndex &&
        !interludeChanged &&
        _hasSyncedInitialFocus) {
      // 跳转发生在同一歌词行内时没有列表位移；不要把本次同步标记泄漏到
      // 下一次正常播放的歌词切换。
      _synchronizeNextLineMotion = false;
      return;
    }
    final transitionInterlude = nextInterlude ?? activeInterlude;
    _lineStaggerIndex = transitionInterlude == null
        ? nextIndex.clamp(0, math.max(0, _document.lines.length - 1))
        : math.max(0, transitionInterlude.anchor + 1);
    final animateLayout = _hasSyncedInitialFocus;
    final synchronizeLayout = _synchronizeNextLineMotion;
    final animateInterludeStructure =
        interludeChanged &&
        animateLayout &&
        !_userScrollSuppressed &&
        ((previousInterlude == null) != (nextInterlude == null));
    if (animateInterludeStructure) {
      final spacer = _interludeSpacerExtent(
        _lyricFontSize,
        MediaQuery.sizeOf(context).height,
      );
      if (nextInterlude != null) {
        _interludeMotionAnchor = nextInterlude.anchor;
        _interludeMotionOffset = spacer;
      } else {
        _interludeMotionAnchor = previousInterlude!.anchor;
        _interludeMotionOffset = -spacer;
      }
      _lineMotion
        ..stop()
        ..value = 0;
    } else if (interludeChanged) {
      _interludeMotionAnchor = -2;
      _interludeMotionOffset = 0;
    }
    _visibleInterlude = nextInterlude;
    _synchronizeNextLineMotion = false;
    final generation = ++_activeSyncGeneration;
    _pendingActiveIndex = nextIndex;
    _pendingScrollFocusIndex = nextScrollFocusIndex;
    _hasSyncedInitialFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _activeSyncGeneration) return;
      _activeIndex = nextIndex;
      _scrollFocusIndex = nextScrollFocusIndex;
      _pendingActiveIndex = null;
      _pendingScrollFocusIndex = null;
      if (_userScrollSuppressed) {
        // 用户正在浏览歌词时只更新高亮，不抢回用户已经滚到的位置。
        _lineScrollDelta = 0;
        _synchronizeLineMotion = false;
        _lineMotion.value = 1;
        _synchronizeNextLineMotion = false;
        _interludeMotionAnchor = -2;
        _interludeMotionOffset = 0;
        setState(() {});
        return;
      }

      // 先提交新的列表结构，再在下一帧读取新的 maxScrollExtent 并定位。
      // 这样间奏占位的加入/移除不会使用旧列表几何量计算目标位置。
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            generation != _activeSyncGeneration ||
            !_scrollController.hasClients) {
          return;
        }
        final maxOffset = _scrollController.position.maxScrollExtent;
        if (nextScrollFocusIndex < 0) {
          _scrollToInterlude(
            maxOffset,
            animate: animateLayout,
            synchronize: synchronizeLayout,
          );
        } else {
          _scrollToLine(
            nextScrollFocusIndex,
            maxOffset,
            animate: animateLayout,
            synchronize: synchronizeLayout,
          );
        }
      });
    });
  }

  void _scrollToInterlude(
    double maxOffset, {
    bool animate = true,
    bool synchronize = false,
  }) {
    final interlude = _displayableInterlude(_playhead.value - _document.offset);
    if (interlude == null || _lyricsWidth <= 0) return;
    final compact = MediaQuery.sizeOf(context).width <= 768;
    var focalCenter = _listTopPadding;
    if (interlude.anchor >= 0) {
      for (var index = 0; index <= interlude.anchor; index++) {
        focalCenter += _measureLyricRowExtent(
          _document.lines[index],
          _lyricsWidth,
          Directionality.of(context),
          context: context,
          compact: compact,
          defaultTextStyle: DefaultTextStyle.of(context).style,
          textHeightBehavior: _effectiveTextHeightBehavior(context),
          textScaler: MediaQuery.textScalerOf(context),
          lyricFontSize: _lyricFontSize,
        );
      }
    }
    focalCenter +=
        _interludeSpacerExtent(
          _lyricFontSize,
          MediaQuery.sizeOf(context).height,
        ) /
        2;
    final target = (focalCenter - _lyricsHeight * _lyricFocusPosition)
        .clamp(0, maxOffset)
        .toDouble();
    _moveListTo(target, animate: animate, synchronize: synchronize);
  }

  ({Duration start, Duration end, int anchor})? _displayableInterlude(
    Duration position,
  ) {
    final interlude = _activeLyricInterlude(_document.lines, position);
    if (interlude == null) return null;

    final resetCandidate = _interludeResetPosition;
    final resetPosition =
        resetCandidate != null &&
            resetCandidate >= interlude.start &&
            resetCandidate < interlude.end
        ? resetCandidate
        : null;
    final animationStart = resetPosition ?? interlude.start;
    if (!_interludeCanDisplay(
      interlude.end - animationStart,
      intro: interlude.anchor < 0,
      forceReset: resetPosition != null,
    )) {
      return null;
    }
    return interlude;
  }

  void _scrollToLine(
    int index,
    double maxOffset, {
    bool animate = true,
    bool synchronize = false,
  }) {
    if (_lyricsWidth <= 0 || index < 0 || index >= _document.lines.length) {
      return;
    }
    final compact = MediaQuery.sizeOf(context).width <= 768;
    final direction = Directionality.of(context);
    var precedingExtent = 0.0;
    for (var lineIndex = 0; lineIndex < index; lineIndex++) {
      final line = _document.lines[lineIndex];
      precedingExtent += _measureLyricRowExtent(
        line,
        _lyricsWidth,
        direction,
        context: context,
        compact: compact,
        defaultTextStyle: DefaultTextStyle.of(context).style,
        textHeightBehavior: _effectiveTextHeightBehavior(context),
        textScaler: MediaQuery.textScalerOf(context),
        lyricFontSize: _lyricFontSize,
      );
    }
    final line = _document.lines[index];
    final extent = _measureLyricRowExtent(
      line,
      _lyricsWidth,
      direction,
      context: context,
      compact: compact,
      defaultTextStyle: DefaultTextStyle.of(context).style,
      textHeightBehavior: _effectiveTextHeightBehavior(context),
      textScaler: MediaQuery.textScalerOf(context),
      lyricFontSize: _lyricFontSize,
    );
    final target =
        (precedingExtent +
                _listTopPadding +
                extent / 2 -
                _lyricsHeight * _lyricFocusPosition)
            .clamp(0, maxOffset)
            .toDouble();
    _moveListTo(target, animate: animate, synchronize: synchronize);
  }

  void _moveListTo(
    double target, {
    required bool animate,
    bool synchronize = false,
  }) {
    if (!_scrollController.hasClients) return;
    final scrollPosition = _scrollController.position;
    final clampedTarget = target
        .clamp(scrollPosition.minScrollExtent, scrollPosition.maxScrollExtent)
        .toDouble();
    final current = scrollPosition.pixels;
    final scrollDelta = clampedTarget - current;
    if (animate && synchronize && scrollDelta.abs() > .5) {
      // 显式定位和恢复跟随使用真实滚动，懒加载列表会沿途构建每一行。
      // 不叠加 FLIP 位移，否则动画中途新建的行会从目标位置突然出现。
      final generation = ++_scrollAnimationGeneration;
      _lineScrollDelta = 0;
      _synchronizeLineMotion = true;
      _lineMotion.forward(from: 0);
      setState(() {});
      unawaited(_animateSynchronizedList(scrollDelta, generation));
      return;
    }

    _scrollAnimationGeneration++;
    _lineScrollDelta = animate ? scrollDelta : 0;
    _synchronizeLineMotion = animate && synchronize;
    _synchronizeNextLineMotion = false;
    _scrollController.jumpTo(clampedTarget);
    if (animate) {
      _lineMotion.forward(from: 0);
    } else {
      _interludeMotionAnchor = -2;
      _interludeMotionOffset = 0;
      _lineMotion.value = 1;
    }
    setState(() {});
  }

  Future<void> _animateSynchronizedList(
    double scrollDelta,
    int generation,
  ) async {
    final position = _scrollController.position;
    final target = (position.pixels + scrollDelta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    await _scrollController.animateTo(
      target,
      duration: _synchronizedLyricScrollDuration,
      curve: Curves.easeInOutCubic,
    );
    if (!mounted || generation != _scrollAnimationGeneration) return;
    setState(() => _synchronizeLineMotion = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasLyrics =
        _document.lines.isNotEmpty ||
        _document.plainLines.any((line) => line.trim().isNotEmpty);
    final details = [
      '语法格式：${_document.syntaxLabel}',
      '时间戳：${_document.timingLabel}',
      if (widget.track.lyricsSources.isNotEmpty)
        '来源：${widget.track.lyricsSources.map((source) => source.label).join('、')}',
      '歌词行数：${_document.lines.isNotEmpty ? _document.lines.length : _document.plainLines.length}',
    ].join('\n');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 18, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Tooltip(
                message: details,
                waitDuration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.info_outline_rounded,
                  key: const ValueKey('lyrics-info'),
                  size: 18,
                  color: Colors.white.withAlpha(145),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _lyricsWidth = constraints.maxWidth;
                _lyricsHeight = constraints.maxHeight;
                final lyricsSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final resized =
                    _previousLyricsSize != null &&
                    _previousLyricsSize != lyricsSize;
                _previousLyricsSize = lyricsSize;
                final viewportSize = MediaQuery.sizeOf(context);
                _lyricFontSize = viewportSize.width <= 768
                    ? math.max(12, viewportSize.width * .08)
                    : math.max(
                        12,
                        math.max(
                          viewportSize.height * .05,
                          viewportSize.width * .025,
                        ),
                      );
                if (_document.lines.isNotEmpty) {
                  final compact = MediaQuery.sizeOf(context).width <= 768;
                  final direction = Directionality.of(context);
                  final textScaler = MediaQuery.textScalerOf(context);
                  final firstExtent = _measureLyricRowExtent(
                    _document.lines.first,
                    constraints.maxWidth,
                    direction,
                    context: context,
                    compact: compact,
                    defaultTextStyle: DefaultTextStyle.of(context).style,
                    textHeightBehavior: _effectiveTextHeightBehavior(context),
                    textScaler: textScaler,
                    lyricFontSize: _lyricFontSize,
                  );
                  final lastExtent = _measureLyricRowExtent(
                    _document.lines.last,
                    constraints.maxWidth,
                    direction,
                    context: context,
                    compact: compact,
                    defaultTextStyle: DefaultTextStyle.of(context).style,
                    textHeightBehavior: _effectiveTextHeightBehavior(context),
                    textScaler: textScaler,
                    lyricFontSize: _lyricFontSize,
                  );
                  _listTopPadding = math.max(
                    0,
                    constraints.maxHeight * _lyricFocusPosition -
                        firstExtent / 2,
                  );
                  _listBottomPadding = math.max(
                    0,
                    constraints.maxHeight * (1 - _lyricFocusPosition) -
                        lastExtent / 2,
                  );
                }
                if (resized &&
                    _scrollFocusIndex >= 0 &&
                    !_userScrollSuppressed &&
                    !_userDragActive) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _scrollController.hasClients) {
                      _scrollToLine(
                        _scrollFocusIndex,
                        _scrollController.position.maxScrollExtent,
                        animate: false,
                      );
                    }
                  });
                }
                return !hasLyrics
                    ? _EmptyLyrics(track: widget.track)
                    : MouseRegion(
                        onEnter: (_) {
                          if (!_isLyricsHovered) {
                            setState(() => _isLyricsHovered = true);
                          }
                        },
                        onExit: (_) {
                          if (_isLyricsHovered) {
                            setState(() => _isLyricsHovered = false);
                          }
                        },
                        child: ValueListenableBuilder<Duration>(
                          valueListenable: _playhead,
                          builder: (context, position, _) {
                            final lyrics = _document.hasTimestamps
                                ? _TimedLyricsList(
                                    document: _document,
                                    position: position,
                                    controller: _scrollController,
                                    activeIndex: _activeIndex,
                                    lineStaggerIndex: _lineStaggerIndex,
                                    speakerOrder: _speakerOrder,
                                    isPlaying: widget.state.isPlaying,
                                    isHovered: _isLyricsHovered,
                                    fontSize: _lyricFontSize,
                                    viewportWidth: _lyricsWidth,
                                    lineMotion: _lineMotion,
                                    lineScrollDelta: _lineScrollDelta,
                                    interludeMotionAnchor:
                                        _interludeMotionAnchor,
                                    interludeMotionOffset:
                                        _interludeMotionOffset,
                                    synchronizeLineMotion:
                                        _synchronizeLineMotion,
                                    interludeResetPosition:
                                        _interludeResetPosition,
                                    topPadding: _listTopPadding,
                                    bottomPadding: _listBottomPadding,
                                    onSeek: _seekToLyric,
                                  )
                                : _UntimedLyricsList(document: _document);
                            return NotificationListener<ScrollNotification>(
                              onNotification: _handleLyricsScrollNotification,
                              child: lyrics,
                            );
                          },
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimedLyricsList extends StatelessWidget {
  const _TimedLyricsList({
    required this.document,
    required this.position,
    required this.controller,
    required this.activeIndex,
    required this.lineStaggerIndex,
    required this.speakerOrder,
    required this.isPlaying,
    required this.isHovered,
    required this.fontSize,
    required this.viewportWidth,
    required this.lineMotion,
    required this.lineScrollDelta,
    required this.interludeMotionAnchor,
    required this.interludeMotionOffset,
    required this.synchronizeLineMotion,
    required this.interludeResetPosition,
    required this.topPadding,
    required this.bottomPadding,
    required this.onSeek,
  });

  final LyricsDocument document;
  final Duration position;
  final ScrollController controller;
  final int activeIndex;
  final int lineStaggerIndex;
  final Map<String, int> speakerOrder;
  final bool isPlaying;
  final bool isHovered;
  final double fontSize;
  final double viewportWidth;
  final Animation<double> lineMotion;
  final double lineScrollDelta;
  final int interludeMotionAnchor;
  final double interludeMotionOffset;
  final bool synchronizeLineMotion;
  final Duration? interludeResetPosition;
  final double topPadding;
  final double bottomPadding;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final lines = document.lines;
    final adjustedPosition = position - document.offset;
    final compact = MediaQuery.sizeOf(context).width <= 768;
    final activeInterlude = _activeLyricInterlude(lines, adjustedPosition);
    final resetCandidate = interludeResetPosition;
    final resetPosition =
        activeInterlude != null &&
            resetCandidate != null &&
            resetCandidate >= activeInterlude.start &&
            resetCandidate < activeInterlude.end
        ? resetCandidate
        : null;
    final animationStart = resetPosition ?? activeInterlude?.start;
    final animationDuration = activeInterlude == null || animationStart == null
        ? Duration.zero
        : activeInterlude.end - animationStart;
    final canShowInterlude =
        activeInterlude != null &&
        _interludeCanDisplay(
          animationDuration,
          intro: activeInterlude.anchor < 0,
          forceReset: resetPosition != null,
        );
    final interlude = canShowInterlude ? activeInterlude : null;
    final interludeSpacer = interlude != null
        ? _interludeSpacerExtent(fontSize, MediaQuery.sizeOf(context).height)
        : 0.0;
    final lineDelays = synchronizeLineMotion && interludeMotionOffset == 0
        ? List<Duration>.filled(lines.length, Duration.zero)
        : _calculateLyricLineDelays(lines, activeIndex: lineStaggerIndex);
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, .12, .88, 1],
        ).createShader(bounds),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ListView.builder(
              key: const ValueKey('timed-lyrics-list'),
              controller: controller,
              itemExtentBuilder: (index, _) => index >= lines.length
                  ? null
                  : _measureLyricRowExtent(
                          lines[index],
                          viewportWidth,
                          Directionality.of(context),
                          context: context,
                          compact: compact,
                          defaultTextStyle: DefaultTextStyle.of(context).style,
                          textHeightBehavior: _effectiveTextHeightBehavior(
                            context,
                          ),
                          textScaler: MediaQuery.textScalerOf(context),
                          lyricFontSize: fontSize,
                        ) +
                        (interlude != null && interlude.anchor == index
                            ? interludeSpacer
                            : 0),
              padding: EdgeInsets.only(
                top:
                    topPadding +
                    (interlude != null && interlude.anchor == -1
                        ? interludeSpacer
                        : 0),
                bottom: bottomPadding,
              ),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final distance = (index - activeIndex).abs();
                final blurDistance = index < activeIndex
                    ? activeIndex - index + 1
                    : index - activeIndex;
                final lineExtent = _measureLyricRowExtent(
                  line,
                  viewportWidth,
                  Directionality.of(context),
                  context: context,
                  compact: compact,
                  defaultTextStyle: DefaultTextStyle.of(context).style,
                  textHeightBehavior: _effectiveTextHeightBehavior(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  lyricFontSize: fontSize,
                );
                final extraExtent =
                    interlude != null && interlude.anchor == index
                    ? interludeSpacer
                    : 0.0;
                final row = _AnimatedLyricRow(
                  key: ValueKey(
                    'lyric-row-${line.start.inMicroseconds}-$index',
                  ),
                  line: line,
                  position: adjustedPosition,
                  distance: distance,
                  blurDistance: blurDistance,
                  active: distance == 0,
                  isNonDynamic: !document.hasWordTimestamps,
                  isPlaying: isPlaying,
                  isHovered: isHovered,
                  fontSize: fontSize,
                  lineMotion: lineMotion,
                  lineDelay: lineDelays[index],
                  lineScrollDelta: lineScrollDelta,
                  lineLayoutDelta: index > interludeMotionAnchor
                      ? interludeMotionOffset
                      : 0,
                  lineSpring: _lyricPositionSpring(lines, lineStaggerIndex),
                  compact: compact,
                  speakerOrder: speakerOrder,
                  onTap: () => onSeek(line.start + document.offset),
                );
                return SizedBox(
                  height: lineExtent + extraExtent,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: lineExtent,
                      width: double.infinity,
                      child: row,
                    ),
                  ),
                );
              },
            ),
            if (interlude != null)
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final top = _interludeTop(
                    interlude,
                    lines,
                    controller.hasClients ? controller.offset : 0,
                    topPadding,
                    viewportWidth,
                    fontSize,
                    compact,
                    MediaQuery.textScalerOf(context),
                    Directionality.of(context),
                    DefaultTextStyle.of(context).style,
                    _effectiveTextHeightBehavior(context),
                    context,
                  );
                  return Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: interludeSpacer,
                      child: _InterludeDots(
                        key: const ValueKey('interlude-dots'),
                        elapsed: adjustedPosition - animationStart!,
                        duration: animationDuration,
                        immediate:
                            interlude.anchor < 0 && resetPosition == null,
                        fontSize: fontSize,
                        screenHeight: MediaQuery.sizeOf(context).height,
                        alignRight: _isRightAligned(
                          interlude.anchor + 1 < lines.length
                              ? _lineSpeaker(lines[interlude.anchor + 1])
                              : null,
                          speakerOrder,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InterludeDots extends StatelessWidget {
  const _InterludeDots({
    required this.elapsed,
    required this.duration,
    required this.immediate,
    required this.fontSize,
    required this.screenHeight,
    required this.alignRight,
    super.key,
  });

  final Duration elapsed;
  final Duration duration;
  final bool immediate;
  final double fontSize;
  final double screenHeight;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    const enterHoldMs = 500;
    const enterFadeMs = 180;
    const dotFadeMs = 750;
    const dotStaggerMs = 80;
    const exitPhaseOneMs = 750;
    const exitPhaseTwoMs = 250;
    const exitFadeMs = 250;
    const trailingMs = 750;
    const inactiveOpacity = .2;
    const activeOpacity = .9;

    final elapsedMs = elapsed.inMilliseconds;
    final durationMs = duration.inMilliseconds;
    final holdMs = immediate ? 0 : enterHoldMs;
    final bodyMs = durationMs - holdMs - exitPhaseOneMs - exitPhaseTwoMs;
    final internalMs = elapsedMs - holdMs;
    final bodyEndMs = holdMs + bodyMs;
    if (elapsedMs < 0 || elapsedMs >= durationMs || bodyMs < 910) {
      return const SizedBox.shrink();
    }

    final fallback = bodyMs < 3000;
    final segmentMs = fallback ? bodyMs : ((bodyMs + trailingMs) / 3).round();
    final dotThreeDurationMs = fallback ? bodyMs : bodyMs - segmentMs * 2;
    final dotThreeTarget = fallback ? 1.0 : dotThreeDurationMs / segmentMs;
    final dotProgress = fallback
        ? <double>[1, 1, 1]
        : <double>[
            _interludeDotFraction(internalMs, 0, segmentMs),
            _interludeDotFraction(internalMs, segmentMs, segmentMs),
            _interludeDotFraction(
              internalMs,
              segmentMs * 2,
              dotThreeDurationMs,
              target: dotThreeTarget,
            ),
          ];

    var scale = 1.0;
    var opacity = internalMs < 0
        ? 0.0
        : _interludeBezier(.59, .02, .07, 1, internalMs / enterFadeMs);
    final exiting = elapsedMs >= bodyEndMs;
    if (exiting) {
      final exitMs = elapsedMs - bodyEndMs;
      if (exitMs < exitPhaseOneMs) {
        scale =
            1 +
            _interludeBezier(.14, .06, .25, 1, exitMs / exitPhaseOneMs) * .25;
      } else {
        scale =
            1.25 -
            _interludeBezier(
                  .29,
                  .03,
                  1,
                  .38,
                  (exitMs - exitPhaseOneMs) / exitPhaseTwoMs,
                ) *
                .85;
      }
      final fadeStart = exitPhaseOneMs + exitPhaseTwoMs - exitFadeMs;
      if (exitMs > fadeStart) {
        opacity *=
            1 -
            _interludeBezier(
              .43,
              .08,
              .83,
              .31,
              (exitMs - fadeStart) / exitFadeMs,
            );
      }
      dotProgress[0] = 1;
      dotProgress[1] = 1;
      dotProgress[2] =
          dotThreeTarget +
          (1 - dotThreeTarget) * (exitMs / trailingMs).clamp(0.0, 1.0);
    } else if (!fallback) {
      final cycles = math.max(1, bodyMs ~/ 4000);
      final period = bodyMs / cycles;
      final phase = (internalMs % period) / period;
      final breathe =
          phase -
          .084 * math.sin(4 * math.pi * phase) +
          .008 * (1 - math.cos(4 * math.pi * phase)) +
          .0046 *
              math.sin(4 * math.pi * phase) *
              (math.cos(4 * math.pi * phase) - math.sin(4 * math.pi * phase));
      scale = breathe <= .5 ? 1 + breathe * .5 : 1.25 - (breathe - .5) * .5;
    }

    final dotHeight = math.max(
      fontSize * .5,
      math.min(screenHeight * .01, fontSize * 3),
    );
    final dotSize = fontSize * .3;
    final dotGap = fontSize * .18;
    final horizontalPadding = _lyricHorizontalPadding(fontSize);
    final verticalPadding = fontSize * _lyricVerticalPaddingEm;
    return SizedBox(
      // 与歌词行使用相同的完整宽度，避免三点的内容宽度成为定位基准。
      width: double.infinity,
      height: dotHeight + verticalPadding * 2,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          verticalPadding,
          horizontalPadding,
          verticalPadding,
        ),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              alignment: alignRight
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              scale: scale,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (slot) {
                  if (slot.isOdd) return SizedBox(width: dotGap);
                  final index = slot ~/ 2;
                  final entering = math
                      .pow(
                        ((internalMs - index * dotStaggerMs) / dotFadeMs).clamp(
                          0.0,
                          1.0,
                        ),
                        2,
                      )
                      .toDouble();
                  final lit = _interludeBezier(
                    .56,
                    .01,
                    .45,
                    1,
                    dotProgress[index],
                  );
                  final dotOpacity =
                      inactiveOpacity + (activeOpacity - inactiveOpacity) * lit;
                  return Opacity(
                    opacity: exiting ? dotOpacity : dotOpacity * entering,
                    child: SizedBox.square(
                      key: index == 0
                          ? const ValueKey('interlude-dot-first')
                          : null,
                      dimension: dotSize,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _interludeDotFraction(
  int elapsedMs,
  int startMs,
  int durationMs, {
  double target = 1,
}) {
  if (elapsedMs <= startMs) return 0;
  return _interludeBezier(
        .56,
        .01,
        .45,
        1,
        ((elapsedMs - startMs) / math.max(1, durationMs)).clamp(0.0, 1.0),
      ) *
      target;
}

double _interludeBezier(double x1, double y1, double x2, double y2, double t) =>
    Cubic(x1, y1, x2, y2).transform(t.clamp(0.0, 1.0));

double _interludeSpacerExtent(double fontSize, double screenHeight) {
  final dotHeight = math.max(
    fontSize * .5,
    math.min(screenHeight * .01, fontSize * 3),
  );
  return dotHeight + fontSize * .8;
}

bool _interludeCanDisplay(
  Duration duration, {
  required bool intro,
  required bool forceReset,
}) {
  const enterHold = Duration(milliseconds: 500);
  const exitDuration = Duration(milliseconds: 1000);
  const staggeredEntry = Duration(milliseconds: 910);
  final hold = forceReset || !intro ? enterHold : Duration.zero;
  return duration - hold - exitDuration >= staggeredEntry;
}

class _UntimedLyricsList extends StatelessWidget {
  const _UntimedLyricsList({required this.document});

  final LyricsDocument document;

  @override
  Widget build(BuildContext context) {
    final lines = document.plainLines.isNotEmpty
        ? document.plainLines
        : document.lines.map((line) => line.text).toList();
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, .12, .88, 1],
        ).createShader(bounds),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: lines.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => Text(
            lines[index],
            textAlign: TextAlign.start,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 22,
              fontWeight: _lyricMainFontWeight,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

List<Duration> _calculateLyricLineDelays(
  List<LyricLine> lines, {
  required int activeIndex,
}) {
  if (lines.isEmpty) return const [];

  // AMLL 只给当前渲染窗口内的行分配错峰延迟。Flutter 的 ListView 会复用
  // 子树，因此用焦点前后固定的 overscan 行数近似其布局窗口，并保持延迟
  // 只由行索引决定，避免滚动动画本身改变延迟而产生抖动。
  final delays = List<Duration>.filled(lines.length, Duration.zero);
  final focus = activeIndex.clamp(0, lines.length - 1);
  final first = math.max(0, focus - 6);
  final last = math.min(lines.length, focus + 9);
  var delay = Duration.zero;
  var baseDelay = _lyricLineStaggerBaseDelay;
  for (var index = first; index < last; index++) {
    delays[index] = delay;
    delay += baseDelay;
    if (index >= focus) {
      baseDelay = Duration(
        microseconds: (baseDelay.inMicroseconds / _lyricLineStaggerCompression)
            .round(),
      );
    }
  }

  // AMLL 的延迟是从当前可视窗口顶部累计出来的。Flutter 这里使用 FLIP
  // 位移，若仍以窗口顶部为零点，活动行会在高亮切换后才开始移动。因此把
  // 活动行归零，并让上方行带少量负延迟，使它们从第一帧就处于预滚动状态。
  final focusDelay = delays[focus];
  for (var index = first; index < last; index++) {
    delays[index] = delays[index] - focusDelay;
    if (index < focus) delays[index] -= _lyricLineUpperLead;
  }
  return delays;
}

SpringDescription _lyricPositionSpring(List<LyricLine> lines, int activeIndex) {
  const defaultStiffness = 90.0;
  if (activeIndex <= 0 || activeIndex >= lines.length) {
    return SpringDescription(
      mass: _lyricSpringMass,
      stiffness: defaultStiffness,
      damping: _lyricSpringDamping(
        defaultStiffness,
        _lyricSpringMass,
        _lyricSpringDampingRatio,
      ),
    );
  }

  final interval = lines[activeIndex].start - lines[activeIndex - 1].start;
  final intervalMs = interval.inMilliseconds.clamp(100, 800).toDouble();
  var ratio = 1 - (intervalMs - 100) / 700;
  ratio = math.pow(ratio, .2).toDouble();
  final stiffness = 170 + ratio * 50;
  return SpringDescription(
    mass: _lyricSpringMass,
    stiffness: stiffness,
    damping: _lyricSpringDamping(
      stiffness,
      _lyricSpringMass,
      _lyricSpringDampingRatio,
    ),
  );
}

double _lyricSpringDamping(double stiffness, double mass, double ratio) =>
    2 * ratio * math.sqrt(stiffness * mass);

class _AnimatedLyricRow extends StatelessWidget {
  const _AnimatedLyricRow({
    super.key,
    required this.line,
    required this.position,
    required this.distance,
    required this.blurDistance,
    required this.active,
    required this.isNonDynamic,
    required this.isPlaying,
    required this.isHovered,
    required this.fontSize,
    required this.lineMotion,
    required this.lineDelay,
    required this.lineScrollDelta,
    required this.lineLayoutDelta,
    required this.lineSpring,
    required this.compact,
    required this.speakerOrder,
    required this.onTap,
  });

  final LyricLine line;
  final Duration position;
  final int distance;
  final int blurDistance;
  final bool active;
  final bool isNonDynamic;
  final bool isPlaying;
  final bool isHovered;
  final double fontSize;
  final Animation<double> lineMotion;
  final Duration lineDelay;
  final double lineScrollDelta;
  final double lineLayoutDelta;
  final SpringDescription lineSpring;
  final bool compact;
  final Map<String, int> speakerOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final blur = distance == 0 || isHovered
        ? 0.0
        : math.min(5.0, (1 + blurDistance) * (compact ? .8 : 1.0));
    final isDuet = _isRightAligned(_lineSpeaker(line), speakerOrder);
    final lineOpacity = active ? .85 : (isNonDynamic ? .2 : 1.0);
    final horizontalPadding = _lyricHorizontalPadding(fontSize);
    final verticalPadding = fontSize * _lyricVerticalPaddingEm;
    final subLineGap = fontSize * .3;
    final content = AnimatedOpacity(
      opacity: lineOpacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: blur),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: value, sigmaY: value),
          child: child,
        ),
        child: AnimatedScale(
          scale: active || !isPlaying ? 1 : .97,
          alignment: isDuet ? Alignment.centerRight : Alignment.centerLeft,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          // 先把整行栅格化，再由 AnimatedScale 只对合成层做缩放。
          // 否则普通 Text 子树会在缩放过程中重新参与字形像素量化。
          child: RepaintBoundary(
            key: ValueKey('lyric-scale-layer-${line.start.inMicroseconds}'),
            child: _LyricHoverBackground(
              key: ValueKey('lyric-hover-${line.start.inMicroseconds}'),
              borderRadius: fontSize * .25,
              child: InkWell(
                onTap: onTap,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(fontSize * .25),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    verticalPadding,
                  ),
                  child: Align(
                    alignment: isDuet
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: isDuet
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: active ? 1 : 0),
                          duration: Duration(milliseconds: active ? 300 : 450),
                          curve: Curves.easeOut,
                          builder: (context, maskProgress, _) => _LyricText(
                            text: line.text,
                            words: line.words,
                            position: position,
                            color: Colors.white,
                            baseAlpha: .2 + .2 * maskProgress,
                            highlightAlpha: .2 + .8 * maskProgress,
                            fontSize: fontSize,
                            weight: _lyricMainFontWeight,
                            textAlign: isDuet ? TextAlign.end : TextAlign.start,
                            animateWords: active && line.words.isNotEmpty,
                            enableCharacterEmphasis:
                                active && line.words.isNotEmpty,
                            active: active,
                          ),
                        ),
                        if (line.translation != null &&
                            line.translation!.trim().isNotEmpty) ...[
                          SizedBox(height: subLineGap),
                          _LyricText(
                            text: line.translation!,
                            words: const [],
                            position: position,
                            color: Colors.white.withAlpha(77),
                            fontSize: _translationFontSize(fontSize),
                            weight: _lyricTranslationFontWeight,
                            textAlign: isDuet ? TextAlign.end : TextAlign.start,
                            lineHeight: 1.5,
                            animateWords: false,
                          ),
                        ],
                        for (final variant in line.variants) ...[
                          SizedBox(height: subLineGap),
                          _AnimatedBackgroundLyric(
                            variant: variant,
                            line: line,
                            position: position,
                            active: _variantIsActive(variant, line, position),
                            isPlaying: isPlaying,
                            speakerOrder: speakerOrder,
                            fontSize: fontSize,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: lineMotion,
      child: RepaintBoundary(
        key: ValueKey('lyric-scroll-layer-${line.start.inMicroseconds}'),
        child: content,
      ),
      builder: (context, child) {
        // AMLL 为每个可见行累加约 45ms 的延迟，并在焦点行之后逐步缩短延迟。
        // 这里使用同一时钟计算每行自己的时间段，避免整列表同帧跳动。
        final animationDurationSeconds =
            _lyricLineMotionDuration.inMicroseconds / 1000000;
        final lineDelaySeconds = lineDelay.inMicroseconds / 1000000;
        final elapsed =
            lineMotion.value * animationDurationSeconds - lineDelaySeconds;
        final progress = elapsed <= 0
            ? 0.0
            : SpringSimulation(lineSpring, 0, 1, 0).x(elapsed);
        // 列表先跳到新的焦点位置，再用 FLIP 偏移从旧画面归位。
        // 每一行拥有独立延迟，因此不会出现所有行同帧同步抖动。
        final offset = (1 - progress) * (lineScrollDelta - lineLayoutDelta);
        final row = Transform.translate(
          key: ValueKey('lyric-row-motion-${line.start.inMicroseconds}'),
          offset: Offset(0, offset),
          child: child,
        );
        return row;
      },
    );
  }
}

/// 对齐 AMLL 的歌词行悬停反馈，仅改变外层背景，不改变文字排版尺寸。
class _LyricHoverBackground extends StatefulWidget {
  const _LyricHoverBackground({
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final double borderRadius;
  final Widget child;

  @override
  State<_LyricHoverBackground> createState() => _LyricHoverBackgroundState();
}

class _LyricHoverBackgroundState extends State<_LyricHoverBackground> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
        decoration: BoxDecoration(
          color: _hovered ? Colors.white.withAlpha(17) : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.child,
      ),
    );
  }
}

class _AnimatedBackgroundLyric extends StatelessWidget {
  const _AnimatedBackgroundLyric({
    required this.variant,
    required this.line,
    required this.position,
    required this.active,
    required this.isPlaying,
    required this.speakerOrder,
    required this.fontSize,
  });

  final LyricVariant variant;
  final LyricLine line;
  final Duration position;
  final bool active;
  final bool isPlaying;
  final Map<String, int> speakerOrder;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isTranslation = variant.role == LyricRole.translation;
    if (isTranslation) {
      return _LyricText(
        text: variant.text,
        words: const [],
        position: position,
        color: Colors.white.withAlpha(77),
        fontSize: _translationFontSize(fontSize),
        weight: _lyricTranslationFontWeight,
        textAlign: _variantAlignment(variant, line, speakerOrder),
        lineHeight: 1.5,
        animateWords: false,
      );
    }

    final visible = active || !isPlaying;
    final alignment = _variantAlignment(variant, line, speakerOrder);
    final backgroundRightAligned = alignment == TextAlign.end;
    final targetProgress = visible ? 1.0 : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: targetProgress),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, progress, child) {
        final slide = backgroundRightAligned ? -1 : 1;
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * slide * fontSize * .8),
            child: Transform.scale(
              scale: .8 + progress * .2,
              alignment: backgroundRightAligned
                  ? Alignment.topRight
                  : Alignment.topLeft,
              child: child,
            ),
          ),
        );
      },
      child: Opacity(
        opacity: .4,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: active ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, maskProgress, _) => _LyricText(
            text: variant.text,
            words: variant.words,
            position: position,
            color: Colors.white.withValues(alpha: .2 + .2 * maskProgress),
            baseAlpha: .2 + .2 * maskProgress,
            highlightAlpha: .2 + .8 * maskProgress,
            fontSize: _backgroundFontSize(fontSize),
            weight: _lyricBackgroundFontWeight,
            textAlign: backgroundRightAligned ? TextAlign.end : TextAlign.start,
            animateWords: active && variant.words.isNotEmpty,
            enableCharacterEmphasis: active && variant.words.isNotEmpty,
            active: active,
            isBackground: true,
          ),
        ),
      ),
    );
  }
}

class _LyricText extends StatelessWidget {
  const _LyricText({
    required this.text,
    required this.words,
    required this.position,
    required this.color,
    required this.fontSize,
    required this.weight,
    required this.textAlign,
    this.baseAlpha,
    this.highlightAlpha = 1,
    this.lineHeight = 1.2,
    this.animateWords = true,
    this.enableCharacterEmphasis = false,
    this.active = true,
    this.isBackground = false,
  });

  final String text;
  final List<LyricWord> words;
  final Duration position;
  final Color color;
  final double fontSize;
  final FontWeight weight;
  final TextAlign textAlign;
  final double? baseAlpha;
  final double highlightAlpha;
  final double lineHeight;
  final bool animateWords;
  final bool enableCharacterEmphasis;
  final bool active;
  final bool isBackground;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = DefaultTextStyle.of(context);
    final style = _resolveLyricTextStyle(
      context,
      defaultTextStyle.style,
      TextStyle(
        color: baseAlpha == null
            ? color
            : color.withValues(alpha: baseAlpha!.clamp(0.0, 1.0)),
        fontSize: fontSize,
        fontWeight: weight,
        height: lineHeight,
        letterSpacing: _lyricLetterSpacing,
      ),
    );
    final textHeightBehavior = _effectiveTextHeightBehavior(context);
    final locale = Localizations.maybeLocaleOf(context);
    if (words.isEmpty) {
      return Text(
        text,
        textAlign: textAlign,
        style: style,
        locale: locale,
        textHeightBehavior: textHeightBehavior,
        textWidthBasis: defaultTextStyle.textWidthBasis,
        maxLines: null,
        softWrap: true,
        overflow: TextOverflow.clip,
      );
    }
    return _KaraokeLyricView(
      text: text,
      words: words,
      position: position,
      style: style,
      textDirection: Directionality.of(context),
      locale: locale,
      textAlign: textAlign,
      textScaler: MediaQuery.textScalerOf(context),
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: defaultTextStyle.textWidthBasis,
      active: active,
      baseAlpha: baseAlpha ?? color.a,
      highlightAlpha: highlightAlpha,
      animateWords: animateWords,
      enableCharacterEmphasis: enableCharacterEmphasis,
      isBackground: isBackground,
    );
  }
}

class _KaraokeLyricView extends StatefulWidget {
  const _KaraokeLyricView({
    required this.text,
    required this.words,
    required this.position,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.textAlign,
    required this.textScaler,
    required this.devicePixelRatio,
    required this.textHeightBehavior,
    required this.textWidthBasis,
    required this.active,
    required this.baseAlpha,
    required this.highlightAlpha,
    required this.animateWords,
    required this.enableCharacterEmphasis,
    required this.isBackground,
  });

  final String text;
  final List<LyricWord> words;
  final Duration position;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final TextAlign textAlign;
  final TextScaler textScaler;
  final double devicePixelRatio;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final bool active;
  final double baseAlpha;
  final double highlightAlpha;
  final bool animateWords;
  final bool enableCharacterEmphasis;
  final bool isBackground;

  @override
  State<_KaraokeLyricView> createState() => _KaraokeLyricViewState();
}

class _KaraokeLyricViewState extends State<_KaraokeLyricView> {
  _KaraokeTextLayout? _layout;

  _KaraokeTextLayout _layoutFor(double width) {
    final style = widget.style.copyWith(color: Colors.white);
    final cached = _layout;
    if (cached != null &&
        cached.matches(
          text: widget.text,
          words: widget.words,
          style: style,
          textDirection: widget.textDirection,
          locale: widget.locale,
          textAlign: widget.textAlign,
          textScaler: widget.textScaler,
          devicePixelRatio: widget.devicePixelRatio,
          textHeightBehavior: widget.textHeightBehavior,
          textWidthBasis: widget.textWidthBasis,
          width: width,
        )) {
      if (widget.active && widget.animateWords) {
        cached.rasterizeGlyphs(widget.devicePixelRatio);
      }
      return cached;
    }

    // 播放时只改变遮罩与绘制变换；固定字形布局和选择框，避免每帧重新整形文字。
    final replacement = _KaraokeTextLayout(
      text: widget.text,
      words: widget.words,
      style: style,
      textDirection: widget.textDirection,
      locale: widget.locale,
      textAlign: widget.textAlign,
      textScaler: widget.textScaler,
      devicePixelRatio: widget.devicePixelRatio,
      textHeightBehavior: widget.textHeightBehavior,
      textWidthBasis: widget.textWidthBasis,
      width: width,
    );
    if (widget.active && widget.animateWords) {
      replacement.rasterizeGlyphs(widget.devicePixelRatio);
    }
    cached?.dispose();
    return _layout = replacement;
  }

  @override
  void dispose() {
    _layout?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layout = _layoutFor(width);
        final textSize = Size(width, layout.painter.height);
        return RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('karaoke-glow-paint'),
            size: textSize,
            painter: _KaraokeLyricPainter(
              layout: layout,
              position: widget.position,
              fontSize: widget.style.fontSize!,
              contentSize: textSize,
              active: widget.active,
              baseAlpha: widget.baseAlpha,
              highlightAlpha: widget.highlightAlpha,
              animateWords: widget.animateWords,
              enableCharacterEmphasis: widget.enableCharacterEmphasis,
              isBackground: widget.isBackground,
            ),
            child: SizedBox.fromSize(
              size: textSize,
              child: Text(
                widget.text,
                textAlign: widget.textAlign,
                style: widget.style.copyWith(color: Colors.transparent),
                locale: widget.locale,
                textHeightBehavior: widget.textHeightBehavior,
                textWidthBasis: widget.textWidthBasis,
                maxLines: null,
                softWrap: true,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KaraokeTextLayout {
  _KaraokeTextLayout({
    required this.text,
    required this.words,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.textAlign,
    required this.textScaler,
    required this.devicePixelRatio,
    required this.textHeightBehavior,
    required this.textWidthBasis,
    required this.width,
  }) {
    painter = _createLyricPainter(
      text: text,
      style: style,
      textDirection: textDirection,
      locale: locale,
      textAlign: textAlign,
      textScaler: textScaler,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      width: width,
    );
    wordLayouts = _buildKaraokeWordLayouts(text, words, painter);
    emphasisGroups = _buildKaraokeEmphasisGroups(words, painter, wordLayouts);
  }

  final String text;
  final List<LyricWord> words;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final TextAlign textAlign;
  final TextScaler textScaler;
  final double devicePixelRatio;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final double width;
  late final TextPainter painter;
  late final List<_KaraokeWordLayout> wordLayouts;
  late final List<_KaraokeEmphasisGroup> emphasisGroups;
  ui.Image? rasterizedImage;
  double rasterizedPixelRatio = 0;

  bool matches({
    required String text,
    required List<LyricWord> words,
    required TextStyle style,
    required TextDirection textDirection,
    required Locale? locale,
    required TextAlign textAlign,
    required TextScaler textScaler,
    required double devicePixelRatio,
    required TextHeightBehavior? textHeightBehavior,
    required TextWidthBasis textWidthBasis,
    required double width,
  }) =>
      this.text == text &&
      _sameLyricWords(this.words, words) &&
      this.style == style &&
      this.textDirection == textDirection &&
      this.locale == locale &&
      this.textAlign == textAlign &&
      this.textScaler == textScaler &&
      this.devicePixelRatio == devicePixelRatio &&
      this.textHeightBehavior == textHeightBehavior &&
      this.textWidthBasis == textWidthBasis &&
      this.width == width;

  /// 将整行文字预先栅格化，动画帧只采样图像，不再重复触发字形 hinting。
  void rasterizeGlyphs(double devicePixelRatio) {
    final screenRatio = devicePixelRatio.isFinite && devicePixelRatio > 0
        ? devicePixelRatio
        : 1.0;
    final ratio = math.min(3.0, screenRatio * 1.5);
    if (rasterizedImage != null && rasterizedPixelRatio == ratio) return;

    rasterizedImage?.dispose();
    rasterizedImage = null;
    rasterizedPixelRatio = 0;

    final pixelWidth = math.max(1, (width * ratio).ceil());
    final pixelHeight = math.max(1, (painter.height * ratio).ceil());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(ratio, ratio);
    painter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    try {
      rasterizedImage = picture.toImageSync(pixelWidth, pixelHeight);
      rasterizedPixelRatio = ratio;
    } catch (_) {
      // 软件渲染或测试环境无法同步转图时，绘制层会回退到 TextPainter。
      rasterizedImage = null;
      rasterizedPixelRatio = 0;
    } finally {
      picture.dispose();
    }
  }

  void dispose() {
    rasterizedImage?.dispose();
    painter.dispose();
  }
}

class _KaraokeWordLayout {
  const _KaraokeWordLayout({required this.atom, required this.boxes});

  final AmlLyricWordAtom atom;
  final List<TextBox> boxes;
}

class _KaraokeEmphasisGroup {
  const _KaraokeEmphasisGroup({
    required this.start,
    required this.end,
    required this.isLastWord,
    required this.characters,
  });

  final Duration start;
  final Duration end;
  final bool isLastWord;
  final List<_KaraokeEmphasisCharacter> characters;
}

class _KaraokeEmphasisCharacter {
  const _KaraokeEmphasisCharacter({
    required this.box,
    required this.sourceAtomIndex,
    required this.atomBox,
  });

  final TextBox box;
  final int sourceAtomIndex;
  final TextBox atomBox;
}

class _KaraokeEmphasisFrame {
  const _KaraokeEmphasisFrame({
    required this.charRect,
    required this.wordRect,
    required this.transformedRect,
    required this.painterOffset,
    required this.translation,
    required this.scale,
    required this.wordProgress,
    required this.glow,
    required this.sigma,
    required this.isRtl,
  });

  final Rect charRect;
  final Rect wordRect;
  final Rect transformedRect;
  final Offset painterOffset;
  final Offset translation;
  final double scale;
  final double wordProgress;
  final double glow;
  final double sigma;
  final bool isRtl;
}

List<_KaraokeWordLayout> _buildKaraokeWordLayouts(
  String text,
  List<LyricWord> words,
  TextPainter painter,
) {
  final atoms = buildAmlLyricWordAtoms(text, words);
  return List.generate(atoms.length, (index) {
    final atom = atoms[index];
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: atom.textStart, extentOffset: atom.textEnd),
    );
    return _KaraokeWordLayout(atom: atom, boxes: List.unmodifiable(boxes));
  }, growable: false);
}

List<_KaraokeEmphasisGroup> _buildKaraokeEmphasisGroups(
  List<LyricWord> words,
  TextPainter painter,
  List<_KaraokeWordLayout> wordLayouts,
) {
  final atoms = wordLayouts
      .map((layout) => layout.atom)
      .toList(growable: false);
  return buildAmlLyricEmphasisGroupsFromAtoms(words, atoms)
      .map((group) {
        final characters = <_KaraokeEmphasisCharacter>[];
        for (final character in group.characters) {
          if (character.sourceAtomIndex >= wordLayouts.length) continue;
          final atomLayout = wordLayouts[character.sourceAtomIndex];
          final charBoxes = painter.getBoxesForSelection(
            TextSelection(
              baseOffset: character.start,
              extentOffset: character.end,
            ),
          );
          for (final charBox in charBoxes) {
            final atomBox = _containingTextBox(charBox, atomLayout.boxes);
            if (atomBox == null) continue;
            characters.add(
              _KaraokeEmphasisCharacter(
                box: charBox,
                sourceAtomIndex: character.sourceAtomIndex,
                atomBox: atomBox,
              ),
            );
          }
        }
        return _KaraokeEmphasisGroup(
          start: group.start,
          end: group.end,
          isLastWord: group.isLastWord,
          characters: List.unmodifiable(characters),
        );
      })
      .toList(growable: false);
}

TextBox? _containingTextBox(TextBox character, List<TextBox> candidates) {
  TextBox? best;
  var bestOverlap = -1.0;
  for (final candidate in candidates) {
    final overlap = math.max(
      0.0,
      math.min(character.bottom, candidate.bottom) -
          math.max(character.top, candidate.top),
    );
    if (overlap > bestOverlap) {
      best = candidate;
      bestOverlap = overlap;
    }
  }
  return best;
}

bool _sameLyricWords(List<LyricWord> left, List<LyricWord> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final first = left[index];
    final second = right[index];
    if (first.start != second.start ||
        first.end != second.end ||
        first.text != second.text ||
        first.speaker != second.speaker) {
      return false;
    }
  }
  return true;
}

class _KaraokeLyricPainter extends CustomPainter {
  const _KaraokeLyricPainter({
    required this.layout,
    required this.position,
    required this.fontSize,
    required this.contentSize,
    required this.active,
    required this.baseAlpha,
    required this.highlightAlpha,
    required this.animateWords,
    required this.enableCharacterEmphasis,
    required this.isBackground,
  });

  final _KaraokeTextLayout layout;
  final Duration position;
  final double fontSize;
  final Size contentSize;
  final bool active;
  final double baseAlpha;
  final double highlightAlpha;
  final bool animateWords;
  final bool enableCharacterEmphasis;
  final bool isBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = layout.painter;
    if (!active || !animateWords || layout.wordLayouts.isEmpty) {
      _paintTextWithAlpha(
        canvas,
        painter,
        Offset.zero,
        Offset.zero & contentSize,
        baseAlpha,
      );
      return;
    }

    // 先绘制整句底图，再在同一隔离层中清除词的原位置并绘制浮动词。
    // 这是旧版稳定的绘制顺序，可避免原字形与浮动字形同时残留。
    // 为最大三倍标准差模糊及字符变换留足隔离层边界，避免辉光贴边裁切。
    final glowBleed = fontSize * 1.05;
    final rasterizedImage = layout.rasterizedImage;
    canvas.saveLayer(
      Rect.fromLTWH(
        0,
        -glowBleed,
        contentSize.width,
        contentSize.height + glowBleed * 2,
      ),
      Paint(),
    );
    _paintTextWithAlpha(
      canvas,
      painter,
      Offset.zero,
      Offset.zero & contentSize,
      baseAlpha,
    );
    for (var index = 0; index < layout.wordLayouts.length; index++) {
      final wordLayout = layout.wordLayouts[index];
      final atom = wordLayout.atom;
      final boxes = wordLayout.boxes;
      if (boxes.isEmpty || atom.isWhitespace) continue;

      final elapsed = position - atom.start;
      final total = atom.end - atom.start;
      final progress = total <= Duration.zero
          ? (elapsed >= Duration.zero ? 1.0 : 0.0)
          : (elapsed.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);
      final duration = math.max(
        const Duration(milliseconds: 1000).inMicroseconds,
        total.inMicroseconds,
      );
      final baseFloatProgress = (elapsed.inMicroseconds / duration).clamp(
        0.0,
        1.0,
      );
      final floatOffset =
          fontSize *
          .08 *
          Curves.easeOut.transform(baseFloatProgress) *
          (isBackground ? 2 : 1);
      if (elapsed < Duration.zero && floatOffset <= 0) continue;

      final painterOffset = Offset(0, -floatOffset);
      for (final box in boxes) {
        final rect = box.toRect();
        if (rect.width <= 0) continue;
        final floatingRect = rect.shift(painterOffset);
        canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
        canvas.save();
        canvas.clipRect(floatingRect);
        if (rasterizedImage == null) {
          _paintTextWithAlpha(
            canvas,
            painter,
            painterOffset,
            floatingRect,
            baseAlpha,
          );
        } else {
          _paintRasterizedTextWithAlpha(
            canvas,
            layout,
            rasterizedImage,
            painterOffset,
            floatingRect,
            baseAlpha,
          );
        }
        _paintWordHighlight(
          canvas,
          painter,
          floatingRect,
          progress,
          box.direction == TextDirection.rtl,
          painterOffset,
          highlightAlpha,
          layout: rasterizedImage == null ? null : layout,
          rasterizedImage: rasterizedImage,
        );
        canvas.restore();
      }
    }
    if (enableCharacterEmphasis) {
      _paintWordEmphasis(
        canvas,
        layout: layout,
        position: position,
        fontSize: fontSize,
        baseAlpha: baseAlpha,
        highlightAlpha: highlightAlpha,
        isBackground: isBackground,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KaraokeLyricPainter oldDelegate) =>
      (oldDelegate.position != position &&
          (active && animateWords ||
              oldDelegate.active && oldDelegate.animateWords)) ||
      oldDelegate.layout != layout ||
      oldDelegate.baseAlpha != baseAlpha ||
      oldDelegate.active != active ||
      oldDelegate.highlightAlpha != highlightAlpha ||
      oldDelegate.animateWords != animateWords ||
      oldDelegate.enableCharacterEmphasis != enableCharacterEmphasis ||
      oldDelegate.isBackground != isBackground;
}

TextPainter _createLyricPainter({
  required String text,
  required TextStyle style,
  required TextDirection textDirection,
  required Locale? locale,
  required TextAlign textAlign,
  required TextScaler textScaler,
  required TextHeightBehavior? textHeightBehavior,
  required TextWidthBasis textWidthBasis,
  required double width,
}) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: textDirection,
  locale: locale,
  textAlign: textAlign,
  textScaler: textScaler,
  textHeightBehavior: textHeightBehavior,
  textWidthBasis: textWidthBasis,
)..layout(minWidth: width, maxWidth: width);

void _paintWordHighlight(
  Canvas canvas,
  TextPainter painter,
  Rect wordRect,
  double progress,
  bool isRtl,
  Offset painterOffset,
  double alpha, {
  _KaraokeTextLayout? layout,
  ui.Image? rasterizedImage,
}) {
  if (progress <= 0) return;
  if (progress >= 1) {
    canvas.save();
    canvas.clipRect(wordRect);
    if (layout == null || rasterizedImage == null) {
      _paintTextWithAlpha(canvas, painter, painterOffset, wordRect, alpha);
    } else {
      _paintRasterizedTextWithAlpha(
        canvas,
        layout,
        rasterizedImage,
        painterOffset,
        wordRect,
        alpha,
      );
    }
    canvas.restore();
    return;
  }

  final featherRatio = math.min(.5, wordRect.height * .5 / wordRect.width);
  final boundary = isRtl ? 1 - progress : progress;
  final leadingStop = (boundary - featherRatio / 2).clamp(0.0, 1.0);
  final trailingStop = (boundary + featherRatio / 2).clamp(0.0, 1.0);
  final colors = isRtl
      ? <Color>[
          Colors.transparent,
          Colors.transparent,
          Colors.white,
          Colors.white,
        ]
      : <Color>[
          Colors.white,
          Colors.white,
          Colors.transparent,
          Colors.transparent,
        ];
  final shader = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: colors,
    stops: [0, leadingStop, trailingStop, 1],
  ).createShader(wordRect);
  canvas.saveLayer(
    wordRect,
    Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
  );
  canvas.clipRect(wordRect);
  if (layout == null || rasterizedImage == null) {
    painter.paint(canvas, painterOffset);
  } else {
    _drawRasterizedText(canvas, layout, rasterizedImage, painterOffset);
  }
  canvas.drawRect(
    wordRect,
    Paint()
      ..shader = shader
      ..blendMode = BlendMode.dstIn,
  );
  canvas.restore();
}

void _paintRasterizedTextWithAlpha(
  Canvas canvas,
  _KaraokeTextLayout layout,
  ui.Image image,
  Offset offset,
  Rect bounds,
  double alpha,
) {
  final boundedAlpha = alpha.clamp(0.0, 1.0);
  if (boundedAlpha <= 0) return;
  if (boundedAlpha < 1) {
    canvas.saveLayer(
      bounds,
      Paint()..color = Colors.white.withValues(alpha: boundedAlpha),
    );
  }
  _drawRasterizedText(canvas, layout, image, offset);
  if (boundedAlpha < 1) canvas.restore();
}

void _drawRasterizedText(
  Canvas canvas,
  _KaraokeTextLayout layout,
  ui.Image image,
  Offset offset,
) {
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(offset.dx, offset.dy, layout.width, layout.painter.height),
    Paint()..filterQuality = FilterQuality.high,
  );
}

void _paintTextWithAlpha(
  Canvas canvas,
  TextPainter painter,
  Offset offset,
  Rect bounds,
  double alpha,
) {
  final boundedAlpha = alpha.clamp(0.0, 1.0);
  if (boundedAlpha <= 0) return;
  if (boundedAlpha >= 1) {
    painter.paint(canvas, offset);
    return;
  }
  canvas.saveLayer(
    bounds,
    Paint()..color = Colors.white.withValues(alpha: boundedAlpha),
  );
  painter.paint(canvas, offset);
  canvas.restore();
}

void _paintWordEmphasis(
  Canvas canvas, {
  required _KaraokeTextLayout layout,
  required Duration position,
  required double fontSize,
  required double baseAlpha,
  required double highlightAlpha,
  required bool isBackground,
}) {
  final elapsedAt = position.inMicroseconds;
  final rasterizedImage = layout.rasterizedImage;
  for (final group in layout.emphasisGroups) {
    if (group.characters.isEmpty) continue;
    final baseDuration = math.max(
      const Duration(milliseconds: 1000).inMicroseconds,
      (group.end - group.start).inMicroseconds,
    );
    final duration = baseDuration * (group.isLastWord ? 1.2 : 1);
    var amount =
        baseDuration / const Duration(milliseconds: 2000).inMicroseconds;
    amount = amount > 1 ? math.sqrt(amount) : math.pow(amount, 3).toDouble();
    var blur = baseDuration / const Duration(milliseconds: 3000).inMicroseconds;
    blur = blur > 1 ? math.sqrt(blur) : math.pow(blur, 3).toDouble();
    amount *= .6 * (group.isLastWord ? 1.6 : 1);
    blur *= .5 * (group.isLastWord ? 1.5 : 1);
    amount = math.min(1.2, amount);
    blur = math.min(.8, blur);

    final frames = <_KaraokeEmphasisFrame>[];
    for (var index = 0; index < group.characters.length; index++) {
      final character = group.characters[index];
      final delay = duration / 2.5 / group.characters.length * index;
      final elapsed = elapsedAt - group.start.inMicroseconds - delay;
      if (elapsed <= 0) continue;
      final progress = (elapsed / duration).clamp(0.0, 1.0);
      final eased = sampleAmlEmphasisCurve(progress);
      final scale = 1 + eased * .1 * amount;
      final offsetX =
          -eased *
          .03 *
          amount *
          (group.characters.length / 2 - index) *
          fontSize;
      final emphasisFloatProgress =
          ((elapsed + const Duration(milliseconds: 400).inMicroseconds) /
                  (duration * 1.4))
              .clamp(0.0, 1.0);
      final floatOffset =
          -sampleAmlEmphasisFloat(emphasisFloatProgress) *
          .08 *
          fontSize *
          (isBackground ? 2 : 1);

      if (character.sourceAtomIndex >= layout.wordLayouts.length) continue;
      final sourceLayout = layout.wordLayouts[character.sourceAtomIndex];
      final sourceAtom = sourceLayout.atom;
      final sourceDuration = sourceAtom.end - sourceAtom.start;
      final wordProgress = sourceDuration <= Duration.zero
          ? (position >= sourceAtom.start ? 1.0 : 0.0)
          : ((position - sourceAtom.start).inMicroseconds /
                    sourceDuration.inMicroseconds)
                .clamp(0.0, 1.0);
      final sourceElapsed = position - sourceAtom.start;
      final sourceFloatProgress =
          (sourceElapsed.inMicroseconds /
                  math.max(
                    const Duration(milliseconds: 1000).inMicroseconds,
                    sourceDuration.inMicroseconds,
                  ))
              .clamp(0.0, 1.0);
      final baseFloat =
          fontSize *
          .05 *
          Curves.easeOut.transform(sourceFloatProgress) *
          (isBackground ? 2 : 1);
      final painterOffset = Offset(0, -baseFloat);
      final sourceBox = character.atomBox;
      final wordRect = sourceBox.toRect().shift(painterOffset);
      final charRect = character.box.toRect().shift(painterOffset);
      final offsetY = -eased * .025 * amount * fontSize;
      final translation = Offset(offsetX, offsetY + floatOffset);
      final transformedRect = charRect
          .shift(translation)
          .inflate(fontSize * .12);
      final glow = eased * amlEmphasisGlowOpacity(blur);
      frames.add(
        _KaraokeEmphasisFrame(
          charRect: charRect,
          wordRect: wordRect,
          transformedRect: transformedRect,
          painterOffset: painterOffset,
          translation: translation,
          scale: scale,
          wordProgress: wordProgress,
          glow: glow,
          sigma: amlEmphasisGlowSigmaEm(blur) * fontSize,
          isRtl: sourceBox.direction == TextDirection.rtl,
        ),
      );
    }

    // 先清理整组字符的原位置，避免后绘字符擦除前一个字符扩散过来的辉光。
    for (final frame in frames) {
      canvas.drawRect(frame.charRect, Paint()..blendMode = BlendMode.clear);
    }

    // 辉光裁剪边界按模糊半径扩张；缩放后的局部边界仍覆盖完整的扩张区域。
    for (final frame in frames) {
      if (frame.glow <= .01) continue;
      final glowPaint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: frame.glow.clamp(0.0, 1.0)),
          BlendMode.srcIn,
        )
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: frame.sigma,
          sigmaY: frame.sigma,
        );
      final glowBleed = frame.sigma * 3;
      canvas.saveLayer(frame.transformedRect.inflate(glowBleed), glowPaint);
      _paintEmphasisGlyph(
        canvas,
        painter: layout.painter,
        layout: layout,
        rasterizedImage: rasterizedImage,
        charRect: frame.charRect,
        clipRect: frame.charRect.inflate(glowBleed / frame.scale),
        wordRect: frame.wordRect,
        painterOffset: frame.painterOffset,
        translation: frame.translation,
        scale: frame.scale,
        wordProgress: frame.wordProgress,
        isRtl: frame.isRtl,
        // 辉光使用完整字形遮罩，避免再乘一次正文的低透明度。
        baseAlpha: 1,
        highlightAlpha: highlightAlpha,
        includeHighlight: false,
      );
      canvas.restore();
    }

    // 所有辉光完成后再覆盖清晰字形，避免相邻字符的辉光被后续绘制顺序擦除。
    for (final frame in frames) {
      _paintEmphasisGlyph(
        canvas,
        painter: layout.painter,
        layout: layout,
        rasterizedImage: rasterizedImage,
        charRect: frame.charRect,
        clipRect: frame.charRect,
        wordRect: frame.wordRect,
        painterOffset: frame.painterOffset,
        translation: frame.translation,
        scale: frame.scale,
        wordProgress: frame.wordProgress,
        isRtl: frame.isRtl,
        baseAlpha: baseAlpha,
        highlightAlpha: highlightAlpha,
        includeHighlight: true,
      );
    }
  }
}

void _paintEmphasisGlyph(
  Canvas canvas, {
  required TextPainter painter,
  required _KaraokeTextLayout layout,
  required ui.Image? rasterizedImage,
  required Rect charRect,
  required Rect clipRect,
  required Rect wordRect,
  required Offset painterOffset,
  required Offset translation,
  required double scale,
  required double wordProgress,
  required bool isRtl,
  required double baseAlpha,
  required double highlightAlpha,
  required bool includeHighlight,
}) {
  final center = charRect.center;
  canvas.save();
  canvas.translate(translation.dx, translation.dy);
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);
  canvas.translate(-center.dx, -center.dy);
  canvas.save();
  canvas.clipRect(clipRect);
  if (rasterizedImage == null) {
    _paintTextWithAlpha(canvas, painter, painterOffset, charRect, baseAlpha);
  } else {
    _paintRasterizedTextWithAlpha(
      canvas,
      layout,
      rasterizedImage,
      painterOffset,
      charRect,
      baseAlpha,
    );
  }
  if (includeHighlight) {
    _paintWordHighlight(
      canvas,
      painter,
      wordRect,
      wordProgress,
      isRtl,
      painterOffset,
      highlightAlpha,
      layout: rasterizedImage == null ? null : layout,
      rasterizedImage: rasterizedImage,
    );
  }
  canvas.restore();
  canvas.restore();
}

class _EmptyLyrics extends StatelessWidget {
  const _EmptyLyrics({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final lyrics = track.lyricsDocument;
    final hasUntimed = lyrics.plainLines.any((line) => line.trim().isNotEmpty);
    return Center(
      child: Text(
        hasUntimed ? '歌词没有时间信息' : '暂无歌词',
        style: TextStyle(color: Colors.white.withAlpha(155), fontSize: 18),
      ),
    );
  }
}

class _QueueOverlay extends StatelessWidget {
  const _QueueOverlay({
    required this.state,
    required this.onClose,
    required this.onSelectTrack,
  });

  final PlayerState state;
  final VoidCallback onClose;
  final ValueChanged<Track> onSelectTrack;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withAlpha(75)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: FractionallySizedBox(
                widthFactor: .92,
                heightFactor: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: ColoredBox(
                      color: const Color(0xE6151719),
                      child: SafeArea(
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text(
                                '接下来播放',
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: IconButton(
                                onPressed: onClose,
                                tooltip: '关闭播放队列',
                                icon: const Icon(Icons.close),
                                color: Colors.white,
                              ),
                            ),
                            const Divider(height: 1, color: Color(0x33FFFFFF)),
                            Expanded(
                              child: ListView.builder(
                                itemCount: state.queue.length,
                                itemBuilder: (context, index) {
                                  final track = state.queue[index];
                                  final selected = index == state.currentIndex;
                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      onTap: () => onSelectTrack(track),
                                      leading: _QueueCover(track: track),
                                      title: Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: selected
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                              : Colors.white,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${track.artist} · ${_formatDuration(track.duration)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(135),
                                        ),
                                      ),
                                      trailing: selected
                                          ? const Icon(
                                              Icons.graphic_eq,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueCover extends StatelessWidget {
  const _QueueCover({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox.square(
        dimension: 42,
        child: track.coverBytes == null
            ? ColoredBox(color: Color(track.coverColor))
            : Image.memory(track.coverBytes!, fit: BoxFit.cover),
      ),
    );
  }
}

int _activeLineIndex(List<LyricLine> lines, Duration position) {
  if (lines.isEmpty) return -1;
  var activeIndex = -1;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    var groupStart = line.start;
    for (final variant in line.variants) {
      if (variant.role != LyricRole.alternate) continue;
      final start = variant.start ?? variant.words.firstOrNull?.start;
      if (start != null && start < groupStart) groupStart = start;
    }
    if (groupStart <= position) activeIndex = index;
  }
  return activeIndex < 0 ? 0 : activeIndex;
}

({Duration start, Duration end, int anchor})? _activeLyricInterlude(
  List<LyricLine> lines,
  Duration position,
) {
  if (lines.isEmpty) return null;
  var latestEnd = Duration.zero;
  for (var index = -1; index < lines.length - 1; index++) {
    if (index >= 0) {
      final line = lines[index];
      final nextStart = lines[index + 1].start;
      final inferredEnd = _effectiveLyricEnd(line, nextStart);
      if (inferredEnd > latestEnd) latestEnd = inferredEnd;
    }
    final nextStart = lines[index + 1].start;
    final gapEnd = latestEnd > nextStart ? latestEnd : nextStart;
    if (gapEnd - latestEnd < _minimumInterludeGap) continue;
    if (position >= latestEnd && position < gapEnd) {
      return (start: latestEnd, end: gapEnd, anchor: index);
    }
  }
  return null;
}

double _interludeTop(
  ({Duration start, Duration end, int anchor}) interlude,
  List<LyricLine> lines,
  double scrollOffset,
  double topPadding,
  double viewportWidth,
  double fontSize,
  bool compact,
  TextScaler textScaler,
  TextDirection direction,
  TextStyle defaultTextStyle,
  TextHeightBehavior? textHeightBehavior,
  BuildContext context,
) {
  if (interlude.anchor < 0) return topPadding - scrollOffset;
  var top = topPadding - scrollOffset;
  for (var index = 0; index <= interlude.anchor; index++) {
    top += _measureLyricRowExtent(
      lines[index],
      viewportWidth,
      direction,
      context: context,
      compact: compact,
      defaultTextStyle: defaultTextStyle,
      textHeightBehavior: textHeightBehavior,
      textScaler: textScaler,
      lyricFontSize: fontSize,
    );
  }
  return top;
}

Duration _effectiveLyricEnd(LyricLine line, Duration nextStart) {
  // 没有显式行结束时间时，优先使用逐字/附加声部的真实结束时间。
  // 如果先用下一行开始时间初始化，再拿已知结束时间做 max，短句后的
  // 长间奏会被错误吞掉，导致 AMLL 的间奏占位永远不会出现。
  final knownEnd = _latestKnownLyricEnd(line);
  var latestEnd = line.end ?? knownEnd ?? nextStart;
  if (knownEnd != null && knownEnd > latestEnd) latestEnd = knownEnd;
  return latestEnd;
}

Duration? _latestKnownLyricEnd(LyricLine line) {
  Duration? latest;

  void add(Duration? value) {
    if (value != null && (latest == null || value > latest!)) latest = value;
  }

  add(line.end);
  add(line.words.lastOrNull?.end);
  add(line.translationWords.lastOrNull?.end);
  for (final variant in line.variants) {
    add(variant.end);
    add(variant.words.lastOrNull?.end);
  }
  return latest;
}

double _translationFontSize(double fontSize) => fontSize * .8;

double _lyricHorizontalPadding(double fontSize) =>
    fontSize * _lyricVerticalPaddingEm;

double _backgroundFontSize(double fontSize) => math.max(fontSize * .7, 10);

bool _variantIsActive(LyricVariant variant, LyricLine line, Duration position) {
  final start = variant.start ?? variant.words.firstOrNull?.start;
  if (start == null) return position >= line.start;
  final end = variant.end ?? variant.words.lastOrNull?.end ?? line.end;
  return position >= start && (end == null || position <= end);
}

double _measureLyricRowExtent(
  LyricLine line,
  double viewportWidth,
  TextDirection textDirection, {
  required BuildContext context,
  required bool compact,
  required TextStyle defaultTextStyle,
  required TextHeightBehavior? textHeightBehavior,
  required TextScaler textScaler,
  required double lyricFontSize,
}) {
  final horizontalPadding = _lyricHorizontalPadding(lyricFontSize);
  final lineWidth = math.max(1.0, viewportWidth - horizontalPadding * 2);
  var contentHeight = _measureLyricTextHeight(
    line.text,
    context: context,
    fontSize: lyricFontSize,
    weight: _lyricMainFontWeight,
    lineHeight: 1.2,
    defaultTextStyle: defaultTextStyle,
    textHeightBehavior: textHeightBehavior,
    maxWidth: lineWidth,
    textDirection: textDirection,
    textScaler: textScaler,
  );
  var subLineCount = 0;

  if (line.translation != null && line.translation!.trim().isNotEmpty) {
    contentHeight += _measureLyricTextHeight(
      line.translation!,
      context: context,
      fontSize: _translationFontSize(lyricFontSize),
      weight: _lyricTranslationFontWeight,
      lineHeight: 1.5,
      defaultTextStyle: defaultTextStyle,
      textHeightBehavior: textHeightBehavior,
      maxWidth: lineWidth,
      textDirection: textDirection,
      textScaler: textScaler,
    );
    subLineCount++;
  }

  for (final variant in line.variants) {
    final isTranslation = variant.role == LyricRole.translation;
    contentHeight += _measureLyricTextHeight(
      variant.text,
      context: context,
      fontSize: isTranslation
          ? _translationFontSize(lyricFontSize)
          : _backgroundFontSize(lyricFontSize),
      weight: isTranslation
          ? _lyricTranslationFontWeight
          : _lyricBackgroundFontWeight,
      lineHeight: isTranslation ? 1.5 : 1.2,
      defaultTextStyle: defaultTextStyle,
      textHeightBehavior: textHeightBehavior,
      maxWidth: lineWidth,
      textDirection: textDirection,
      textScaler: textScaler,
    );
    subLineCount++;
  }

  return contentHeight +
      lyricFontSize * _lyricVerticalPaddingEm * 2 +
      4 +
      math.max(0, subLineCount) * lyricFontSize * .3 +
      2;
}

double _measureLyricTextHeight(
  String text, {
  required BuildContext context,
  required double fontSize,
  required FontWeight weight,
  required double lineHeight,
  required TextStyle defaultTextStyle,
  required TextHeightBehavior? textHeightBehavior,
  required double maxWidth,
  required TextDirection textDirection,
  required TextScaler textScaler,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: _resolveLyricTextStyle(
        context,
        defaultTextStyle,
        TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          height: lineHeight,
          letterSpacing: _lyricLetterSpacing,
        ),
      ),
    ),
    textDirection: textDirection,
    locale: Localizations.maybeLocaleOf(context),
    textScaler: textScaler,
    textHeightBehavior: textHeightBehavior,
    textWidthBasis: DefaultTextStyle.of(context).textWidthBasis,
    maxLines: null,
    ellipsis: null,
  )..layout(maxWidth: maxWidth);
  return painter.height;
}

TextStyle _resolveLyricTextStyle(
  BuildContext context,
  TextStyle defaultStyle,
  TextStyle lyricStyle,
) {
  var style = defaultStyle.merge(lyricStyle);
  if (MediaQuery.boldTextOf(context)) {
    style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
  }
  return style.merge(
    TextStyle(
      fontFamily: linglunFontFamily,
      height: MediaQuery.maybeLineHeightScaleFactorOverrideOf(context),
      letterSpacing: MediaQuery.maybeLetterSpacingOverrideOf(context),
      wordSpacing: MediaQuery.maybeWordSpacingOverrideOf(context),
    ),
  );
}

TextHeightBehavior? _effectiveTextHeightBehavior(BuildContext context) {
  return DefaultTextStyle.of(context).textHeightBehavior ??
      DefaultTextHeightBehavior.maybeOf(context);
}

Map<String, int> _buildSpeakerOrder(LyricsDocument document) {
  final order = <String, int>{};
  void add(String? speaker) {
    final normalized = speaker?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        order.containsKey(normalized)) {
      return;
    }
    order[normalized] = order.length;
  }

  for (final line in document.lines) {
    add(line.speaker);
    for (final word in line.words) {
      add(word.speaker);
    }
    for (final variant in line.variants) {
      add(variant.speaker);
      for (final word in variant.words) {
        add(word.speaker);
      }
    }
  }
  return order;
}

bool _isRightAligned(String? speaker, Map<String, int> speakerOrder) {
  final normalized = speaker?.trim();
  if (normalized == null || normalized.isEmpty) return false;
  return (speakerOrder[normalized] ?? 0).isOdd;
}

String? _lineSpeaker(LyricLine line) {
  if (line.speaker?.trim().isNotEmpty ?? false) return line.speaker;
  for (final word in line.words) {
    if (word.speaker?.trim().isNotEmpty ?? false) return word.speaker;
  }
  return null;
}

TextAlign _variantAlignment(
  LyricVariant variant,
  LyricLine line,
  Map<String, int> speakerOrder,
) {
  if (variant.role == LyricRole.translation) {
    return _isRightAligned(_lineSpeaker(line), speakerOrder)
        ? TextAlign.end
        : TextAlign.start;
  }
  return _isRightAligned(variant.speaker ?? _lineSpeaker(line), speakerOrder)
      ? TextAlign.end
      : TextAlign.start;
}

String _artistAlbumLabel(String artist, String album) {
  final normalizedArtist = artist.trim();
  final normalizedAlbum = album.trim();
  if (normalizedArtist.isEmpty) return normalizedAlbum;
  if (normalizedAlbum.isEmpty) return normalizedArtist;
  return '$normalizedArtist · $normalizedAlbum';
}

double _wideCoverDetailsGap(double height) {
  // 只在较大的窗口中逐步增加间距，避免窗口变高时封面与控制区被拉得过开。
  final progress = ((height - 560) / 360).clamp(0.0, 1.0);
  return 16 + progress * 12;
}

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  final sign = seconds < 0 ? '-' : '';
  final absolute = seconds.abs();
  final minutes = absolute ~/ 60;
  final remainder = absolute % 60;
  return '$sign$minutes:${remainder.toString().padLeft(2, '0')}';
}
