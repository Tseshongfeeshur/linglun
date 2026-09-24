import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_typography.dart';
import '../application/player_controller.dart';
import '../domain/lyrics.dart';
import '../domain/track.dart';

const _pageAnimationCurve = Curves.easeOutCubic;
const _lyricDefaultFontSize = 38.0;
const _lyricLetterSpacing = .1;
const _lyricVerticalPaddingEm = .4;
const _lyricFocusPosition = 1 / 3;
const _lyricLineMotionDuration = Duration(milliseconds: 1500);
const _minimumInterludeGap = Duration(seconds: 7);

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
  bool _showLyrics = true;
  bool _showQueue = false;
  bool _showRemainingTime = false;

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
                            showLyrics: _showLyrics,
                            showRemainingTime: _showRemainingTime,
                            onRemainingTimeChanged: (value) =>
                                setState(() => _showRemainingTime = value),
                            onPrevious: widget.onPrevious,
                            onTogglePlay: widget.onTogglePlay,
                            onNext: widget.onNext,
                            onSeek: widget.onSeek,
                            onToggleShuffle: widget.onToggleShuffle,
                            onCycleRepeat: widget.onCycleRepeat,
                          )
                        : _NarrowPlaybackLayout(
                            track: widget.track,
                            state: widget.state,
                            showLyrics: _showLyrics,
                            showRemainingTime: _showRemainingTime,
                            onRemainingTimeChanged: (value) =>
                                setState(() => _showRemainingTime = value),
                            onPrevious: widget.onPrevious,
                            onTogglePlay: widget.onTogglePlay,
                            onNext: widget.onNext,
                            onSeek: widget.onSeek,
                            onToggleShuffle: widget.onToggleShuffle,
                            onCycleRepeat: widget.onCycleRepeat,
                          );
                  },
                ),
              ),
              _PageFooter(
                showLyrics: _showLyrics,
                showQueue: _showQueue,
                onToggleLyrics: () =>
                    setState(() => _showLyrics = !_showLyrics),
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
          const SizedBox(width: 26),
          Icon(Icons.graphic_eq, color: Colors.white.withAlpha(150), size: 18),
          const SizedBox(width: 10),
          Text(
            '正在播放',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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
    required this.showLyrics,
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
  final bool showLyrics;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 26, 0),
      child: Row(
        children: [
          Expanded(
            flex: 44,
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
              immersive: !showLyrics,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 56,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 480),
              reverseDuration: const Duration(milliseconds: 320),
              switchInCurve: _pageAnimationCurve,
              switchOutCurve: Curves.easeInCubic,
              child: showLyrics
                  ? _LyricsViewport(
                      key: const ValueKey('wide-lyrics'),
                      track: track,
                      state: state,
                      onSeek: onSeek,
                    )
                  : const SizedBox.expand(key: ValueKey('lyrics-hidden')),
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
    this.immersive = false,
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
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverSize = math.min(
          constraints.maxWidth * (immersive ? .94 : .84),
          constraints.maxHeight * (immersive ? .67 : .53),
        );
        return Column(
          children: [
            Expanded(
              child: Center(
                child: _AlbumCover(track: track, size: coverSize),
              ),
            ),
            _TrackMetadata(track: track, compact: false),
            const SizedBox(height: 18),
            _SeekControl(
              track: track,
              position: state.position,
              showRemainingTime: showRemainingTime,
              onRemainingTimeChanged: onRemainingTimeChanged,
              onSeek: onSeek,
            ),
            const SizedBox(height: 10),
            _PlaybackControls(
              state: state,
              onPrevious: onPrevious,
              onTogglePlay: onTogglePlay,
              onNext: onNext,
              onToggleShuffle: onToggleShuffle,
              onCycleRepeat: onCycleRepeat,
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _NarrowPlaybackLayout extends StatelessWidget {
  const _NarrowPlaybackLayout({
    required this.track,
    required this.state,
    required this.showLyrics,
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
  final bool showLyrics;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: showLyrics
                ? _LyricsViewport(track: track, state: state, onSeek: onSeek)
                : _ImmersiveCover(track: track),
          ),
          _TrackMetadata(track: track, compact: true),
          const SizedBox(height: 12),
          _SeekControl(
            track: track,
            position: state.position,
            showRemainingTime: showRemainingTime,
            onRemainingTimeChanged: onRemainingTimeChanged,
            onSeek: onSeek,
          ),
          _PlaybackControls(
            state: state,
            onPrevious: onPrevious,
            onTogglePlay: onTogglePlay,
            onNext: onNext,
            onToggleShuffle: onToggleShuffle,
            onCycleRepeat: onCycleRepeat,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _ImmersiveCover extends StatelessWidget {
  const _ImmersiveCover({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          constraints.maxWidth * .76,
          constraints.maxHeight * .9,
        );
        return Center(
          child: _AlbumCover(track: track, size: size),
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
      key: const ValueKey('amll-album-cover'),
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(math.max(10, size * .025)),
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
          borderRadius: BorderRadius.circular(math.max(10, size * .025)),
          child: track.coverBytes == null
              ? ColoredBox(
                  color: Color(track.coverColor),
                  child: const Center(
                    child: Icon(
                      Icons.album_rounded,
                      color: Colors.white70,
                      size: 78,
                    ),
                  ),
                )
              : Image.memory(
                  track.coverBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
        ),
      ),
    );
  }
}

class _TrackMetadata extends StatelessWidget {
  const _TrackMetadata({required this.track, required this.compact});

  final Track track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 21 : 24,
      fontWeight: FontWeight.w600,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: compact ? TextAlign.start : TextAlign.center,
          style: titleStyle,
        ),
        const SizedBox(height: 4),
        Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: compact ? TextAlign.start : TextAlign.center,
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
            textAlign: compact ? TextAlign.start : TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(135), fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _SeekControl extends StatefulWidget {
  const _SeekControl({
    required this.track,
    required this.position,
    required this.showRemainingTime,
    required this.onRemainingTimeChanged,
    required this.onSeek,
  });

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

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withAlpha(65),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withAlpha(35),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(_formatDuration(shownPosition), style: _timeTextStyle),
              const Spacer(),
              _AudioQualityBadge(track: widget.track),
              const Spacer(),
              InkWell(
                onTap: () =>
                    widget.onRemainingTimeChanged(!widget.showRemainingTime),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    widget.showRemainingTime
                        ? '-${_formatDuration(rightTime)}'
                        : _formatDuration(rightTime),
                    style: _timeTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _timeTextStyle = TextStyle(
  color: Color(0xBFFFFFFF),
  fontSize: 11,
  fontFeatures: [ui.FontFeature.tabularFigures()],
);

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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
  const _PageFooter({
    required this.showLyrics,
    required this.showQueue,
    required this.onToggleLyrics,
    required this.onToggleQueue,
  });

  final bool showLyrics;
  final bool showQueue;
  final VoidCallback onToggleLyrics;
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
          IconButton(
            onPressed: onToggleLyrics,
            tooltip: showLyrics ? '隐藏歌词' : '显示歌词',
            color: showLyrics
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withAlpha(185),
            icon: const Icon(Icons.lyrics_rounded),
            iconSize: 20,
          ),
          const Spacer(),
          Text(
            '伶伦 · 本地播放',
            style: TextStyle(color: Colors.white.withAlpha(95), fontSize: 11),
          ),
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
    super.key,
  });

  final Track track;
  final PlayerState state;
  final ValueChanged<Duration> onSeek;

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
  int? _pendingActiveIndex;
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
  bool _hasSyncedInitialFocus = false;
  Size? _previousLyricsSize;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _document = widget.track.lyricsDocument;
    _speakerOrder = _buildSpeakerOrder(_document);
    final initialPosition = widget.state.position;
    _anchorPosition = initialPosition;
    _playhead = ValueNotifier(initialPosition);
    _lineMotion = AnimationController(
      vsync: this,
      duration: _lyricLineMotionDuration,
      value: 1,
    );
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
    final trackChanged = oldWidget.track.id != widget.track.id;
    final playbackChanged = oldWidget.state.isPlaying != widget.state.isPlaying;
    if (trackChanged) {
      _document = widget.track.lyricsDocument;
      _speakerOrder = _buildSpeakerOrder(_document);
      _interludeResetPosition = null;
      _activeIndex = -1;
      _pendingActiveIndex = null;
      _activeSyncGeneration++;
      _hasSyncedInitialFocus = false;
      _lineMotion.value = 1;
      _lineScrollDelta = 0;
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
      if (!widget.state.isPlaying ||
          correction.abs() >= const Duration(milliseconds: 450)) {
        // 大幅偏差通常表示用户跳转；常规播放器进度上报只做小幅校正。
        _anchorPosition = reported;
        _interludeResetPosition = reported - _document.offset;
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
    final nextIndex =
        _activeLyricInterlude(_document.lines, adjustedPosition) != null
        ? -1
        : _activeLineIndex(_document.lines, adjustedPosition);
    final visibleIndex = _pendingActiveIndex ?? _activeIndex;
    if (nextIndex == visibleIndex && _hasSyncedInitialFocus) return;
    final animateLayout = _hasSyncedInitialFocus;
    final generation = ++_activeSyncGeneration;
    _pendingActiveIndex = nextIndex;
    _hasSyncedInitialFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _activeSyncGeneration) return;
      _activeIndex = nextIndex;
      _pendingActiveIndex = null;
      if (_scrollController.hasClients && _lyricsWidth > 0) {
        // 在同一个帧回调中完成“跳到目标位置、记录 FLIP 位移、启动动画、
        // 重建活动行”。这样高亮渐变和列表滚动不会相差一帧以上。
        final maxOffset = _scrollController.position.maxScrollExtent;
        if (nextIndex < 0) {
          _scrollToInterlude(maxOffset, animate: animateLayout);
        } else {
          _scrollToLine(nextIndex, maxOffset, animate: animateLayout);
        }
        return;
      }

      // 首次布局尚未建立滚动客户区时，先提交活动行，下一帧再进行初始定位。
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            generation != _activeSyncGeneration ||
            !_scrollController.hasClients) {
          return;
        }
        final maxOffset = _scrollController.position.maxScrollExtent;
        if (nextIndex < 0) {
          _scrollToInterlude(maxOffset, animate: false);
        } else {
          _scrollToLine(nextIndex, maxOffset, animate: false);
        }
      });
    });
  }

  void _scrollToInterlude(double maxOffset, {bool animate = true}) {
    final interlude = _activeLyricInterlude(
      _document.lines,
      _playhead.value - _document.offset,
    );
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
    _moveListTo(target, animate: animate);
  }

  void _scrollToLine(int index, double maxOffset, {bool animate = true}) {
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
    _moveListTo(target, animate: animate);
  }

  void _moveListTo(double target, {required bool animate}) {
    if (!_scrollController.hasClients) return;
    final scrollPosition = _scrollController.position;
    final clampedTarget = target
        .clamp(scrollPosition.minScrollExtent, scrollPosition.maxScrollExtent)
        .toDouble();
    final current = scrollPosition.pixels;
    _lineScrollDelta = animate ? clampedTarget - current : 0;
    _scrollController.jumpTo(clampedTarget);
    if (animate) {
      _lineMotion.forward(from: 0);
    } else {
      _lineMotion.value = 1;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasLyrics =
        _document.lines.isNotEmpty ||
        _document.plainLines.any((line) => line.trim().isNotEmpty);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 18, 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '歌词',
                style: TextStyle(
                  color: Colors.white.withAlpha(175),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (hasLyrics)
                Text(
                  '${_document.syntaxLabel} · ${_document.timingLabel}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(115),
                    fontSize: 11,
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
                if (resized && _activeIndex >= 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _scrollController.hasClients) {
                      _scrollToLine(
                        _activeIndex,
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
                                    speakerOrder: _speakerOrder,
                                    isPlaying: widget.state.isPlaying,
                                    isHovered: _isLyricsHovered,
                                    fontSize: _lyricFontSize,
                                    viewportWidth: _lyricsWidth,
                                    lineMotion: _lineMotion,
                                    lineScrollDelta: _lineScrollDelta,
                                    interludeResetPosition:
                                        _interludeResetPosition,
                                    topPadding: _listTopPadding,
                                    bottomPadding: _listBottomPadding,
                                    onSeek: _seekToLyric,
                                  )
                                : _UntimedLyricsList(document: _document);
                            return lyrics;
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
    required this.speakerOrder,
    required this.isPlaying,
    required this.isHovered,
    required this.fontSize,
    required this.viewportWidth,
    required this.lineMotion,
    required this.lineScrollDelta,
    required this.interludeResetPosition,
    required this.topPadding,
    required this.bottomPadding,
    required this.onSeek,
  });

  final LyricsDocument document;
  final Duration position;
  final ScrollController controller;
  final int activeIndex;
  final Map<String, int> speakerOrder;
  final bool isPlaying;
  final bool isHovered;
  final double fontSize;
  final double viewportWidth;
  final Animation<double> lineMotion;
  final double lineScrollDelta;
  final Duration? interludeResetPosition;
  final double topPadding;
  final double bottomPadding;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final lines = document.lines;
    final adjustedPosition = position - document.offset;
    final compact = MediaQuery.sizeOf(context).width <= 768;
    final interlude = _activeLyricInterlude(lines, adjustedPosition);
    final resetCandidate = interludeResetPosition;
    final resetPosition =
        interlude != null &&
            resetCandidate != null &&
            resetCandidate >= interlude.start &&
            resetCandidate < interlude.end
        ? resetCandidate
        : null;
    final animationStart = resetPosition ?? interlude?.start;
    final animationDuration = interlude == null || animationStart == null
        ? Duration.zero
        : interlude.end - animationStart;
    final canShowInterlude =
        interlude != null &&
        _interludeCanDisplay(
          animationDuration,
          intro: interlude.anchor < 0,
          forceReset: resetPosition != null,
        );
    final interludeSpacer = canShowInterlude
        ? _interludeSpacerExtent(fontSize, MediaQuery.sizeOf(context).height)
        : 0.0;
    final lineDelays = _calculateLyricLineDelays(
      lines,
      activeIndex: activeIndex,
    );
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
                        (canShowInterlude && interlude.anchor == index
                            ? interludeSpacer
                            : 0),
              padding: EdgeInsets.only(
                top:
                    topPadding +
                    (canShowInterlude && interlude.anchor == -1
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
                    canShowInterlude && interlude.anchor == index
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
                  lineSpring: _lyricPositionSpring(lines, activeIndex),
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
            if (canShowInterlude)
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
                      child: Align(
                        alignment:
                            _isRightAligned(
                              interlude.anchor + 1 < lines.length
                                  ? _lineSpeaker(lines[interlude.anchor + 1])
                                  : null,
                              speakerOrder,
                            )
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: _InterludeDots(
                          key: const ValueKey('interlude-dots'),
                          elapsed: adjustedPosition - animationStart!,
                          duration: animationDuration,
                          immediate:
                              interlude.anchor < 0 && resetPosition == null,
                          fontSize: fontSize,
                          screenHeight: MediaQuery.sizeOf(context).height,
                          compact: MediaQuery.sizeOf(context).width <= 500,
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
    required this.compact,
    super.key,
  });

  final Duration elapsed;
  final Duration duration;
  final bool immediate;
  final double fontSize;
  final double screenHeight;
  final bool compact;

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
    return SizedBox(
      height: dotHeight + fontSize * .8,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : fontSize,
          vertical: fontSize * .4,
        ),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
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
              fontWeight: FontWeight.w600,
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
  var baseDelay = const Duration(milliseconds: 50);
  for (var index = first; index < last; index++) {
    delays[index] = delay;
    delay += baseDelay;
    if (index >= focus) {
      baseDelay = Duration(
        microseconds: (baseDelay.inMicroseconds / 1.05).round(),
      );
    }
  }

  // AMLL 的延迟是从当前可视窗口顶部累计出来的。Flutter 这里使用 FLIP
  // 位移，若仍以窗口顶部为零点，活动行会在高亮切换后才开始移动。因此把
  // 活动行归零，并让上方行带少量负延迟，使它们从第一帧就处于预滚动状态。
  final focusDelay = delays[focus];
  const upperLead = Duration(milliseconds: 36);
  for (var index = first; index < last; index++) {
    delays[index] = delays[index] - focusDelay;
    if (index < focus) delays[index] -= upperLead;
  }
  return delays;
}

SpringDescription _lyricPositionSpring(List<LyricLine> lines, int activeIndex) {
  if (activeIndex <= 0 || activeIndex >= lines.length) {
    return const SpringDescription(mass: .9, stiffness: 90, damping: 15);
  }

  final interval = lines[activeIndex].start - lines[activeIndex - 1].start;
  final intervalMs = interval.inMilliseconds.clamp(100, 800).toDouble();
  var ratio = 1 - (intervalMs - 100) / 700;
  ratio = math.pow(ratio, .2).toDouble();
  final stiffness = 170 + ratio * 50;
  return SpringDescription(
    mass: .9,
    stiffness: stiffness,
    damping: math.sqrt(stiffness) * 2.2,
  );
}

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
                padding: EdgeInsets.all(verticalPadding),
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
                          weight: FontWeight(450),
                          textAlign: isDuet ? TextAlign.end : TextAlign.start,
                          animateWords: active && line.words.isNotEmpty,
                          emphasizeLongWords: active && line.words.isNotEmpty,
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
                          weight: FontWeight.w500,
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
    );
    return AnimatedBuilder(
      animation: lineMotion,
      child: RepaintBoundary(child: content),
      builder: (context, child) {
        // AMLL 为每个可见行累加约 50ms 的延迟，并在焦点行之后逐步缩短延迟。
        // 这里使用同一时钟计算每行自己的时间段，避免整列表同帧跳动。
        final elapsed =
            lineMotion.value *
                _lyricLineMotionDuration.inMicroseconds /
                1000000 -
            lineDelay.inMicroseconds / 1000000;
        final eased = elapsed <= 0
            ? 0.0
            : SpringSimulation(lineSpring, 0, 1, 0).x(elapsed).clamp(0.0, 1.05);
        // 列表先跳到新的焦点位置，再用 FLIP 偏移从旧画面归位。
        // 每一行拥有独立延迟，因此不会出现所有行同帧同步抖动。
        final offset = (1 - eased) * lineScrollDelta;
        final row = Transform.translate(
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
        weight: FontWeight.w500,
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
            weight: FontWeight.w600,
            textAlign: backgroundRightAligned ? TextAlign.end : TextAlign.start,
            animateWords: active && variant.words.isNotEmpty,
            emphasizeLongWords: active && variant.words.isNotEmpty,
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
    this.emphasizeLongWords = false,
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
  final bool emphasizeLongWords;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: CustomPaint(
            painter: _KaraokeLyricPainter(
              text: text,
              words: words,
              position: position,
              style: style,
              textDirection: Directionality.of(context),
              locale: locale,
              textAlign: textAlign,
              textScaler: MediaQuery.textScalerOf(context),
              textHeightBehavior: textHeightBehavior,
              textWidthBasis: defaultTextStyle.textWidthBasis,
              active: active,
              highlightAlpha: highlightAlpha,
              animateWords: animateWords,
              emphasizeLongWords: emphasizeLongWords,
              isBackground: isBackground,
            ),
            child: Text(
              text,
              textAlign: textAlign,
              style: style.copyWith(color: Colors.transparent),
              locale: locale,
              textHeightBehavior: textHeightBehavior,
              textWidthBasis: defaultTextStyle.textWidthBasis,
              maxLines: null,
              softWrap: true,
              overflow: TextOverflow.clip,
            ),
          ),
        );
      },
    );
  }
}

class _KaraokeLyricPainter extends CustomPainter {
  const _KaraokeLyricPainter({
    required this.text,
    required this.words,
    required this.position,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.textAlign,
    required this.textScaler,
    required this.textHeightBehavior,
    required this.textWidthBasis,
    required this.active,
    required this.highlightAlpha,
    required this.animateWords,
    required this.emphasizeLongWords,
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
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final bool active;
  final double highlightAlpha;
  final bool animateWords;
  final bool emphasizeLongWords;
  final bool isBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = _createLyricPainter(
      text: text,
      style: style,
      textDirection: textDirection,
      locale: locale,
      textAlign: textAlign,
      textScaler: textScaler,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      width: size.width,
    );
    final brightPainter = _createLyricPainter(
      text: text,
      style: style.copyWith(
        color: Colors.white.withValues(alpha: highlightAlpha.clamp(0.0, 1.0)),
      ),
      textDirection: textDirection,
      locale: locale,
      textAlign: textAlign,
      textScaler: textScaler,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      width: size.width,
    );
    if (!active || !animateWords || words.isEmpty) {
      painter.paint(canvas, Offset.zero);
      return;
    }

    // 光晕需要在整句隔离层中合成，避免单个字符的清除和变换影响相邻字符。
    final glowBleed = style.fontSize! * 1.5;
    canvas.saveLayer(
      Rect.fromLTRB(
        -glowBleed,
        -glowBleed,
        size.width + glowBleed,
        size.height + glowBleed,
      ),
      Paint(),
    );
    painter.paint(canvas, Offset.zero);
    final ranges = _wordRanges(text, words);
    final elapsedAt = position.inMicroseconds;
    for (var index = 0; index < words.length; index++) {
      final word = words[index];
      final range = ranges[index];
      if (range.$2 <= range.$1) continue;
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: range.$1, extentOffset: range.$2),
      );
      if (boxes.isEmpty) continue;

      final end =
          word.end ??
          (index + 1 < words.length
              ? words[index + 1].start
              : word.start + const Duration(milliseconds: 350));
      final elapsed = position - word.start;
      final total = end - word.start;
      final progress = total <= Duration.zero
          ? (elapsed >= Duration.zero ? 1.0 : 0.0)
          : (elapsed.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);
      final duration = math.max(
        const Duration(milliseconds: 1000).inMicroseconds,
        total.inMicroseconds,
      );
      final isLastWord = index == words.length - 1;
      final baseFloatProgress = (elapsed.inMicroseconds / duration).clamp(
        0.0,
        1.0,
      );
      final floatOffset =
          style.fontSize! * .06 * Curves.easeOut.transform(baseFloatProgress);
      if (elapsed < Duration.zero && floatOffset <= 0) continue;

      for (final box in boxes) {
        final rect = box.toRect();
        if (rect.width <= 0) continue;
        final isRtl = box.direction == TextDirection.rtl;
        final painterOffset = Offset(0, -floatOffset);
        final floatingRect = rect.shift(painterOffset);
        // 仅在隔离层中清除原字形，再按同一组字形度量绘制浮动词，避免重影。
        canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
        canvas.save();
        canvas.clipRect(floatingRect);
        painter.paint(canvas, painterOffset);
        _paintWordHighlight(
          canvas,
          brightPainter,
          floatingRect,
          progress,
          isRtl,
          painterOffset,
        );
        canvas.restore();
      }

      if (emphasizeLongWords &&
          _shouldEmphasizeWord(word.text, total) &&
          progress > 0) {
        final wordRect = boxes
            .map((box) => box.toRect())
            .reduce((left, right) => left.expandToInclude(right));
        _paintWordEmphasis(
          canvas,
          text: text,
          range: range,
          painter: painter,
          brightPainter: brightPainter,
          style: style,
          word: word,
          end: end,
          elapsedMicroseconds: elapsedAt - word.start.inMicroseconds,
          isLastWord: isLastWord,
          isBackground: isBackground,
          painterOffset: Offset(0, -floatOffset),
          highlightProgress: progress,
          isRtl: boxes.first.direction == TextDirection.rtl,
          wordRect: wordRect.shift(Offset(0, -floatOffset)),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KaraokeLyricPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.active != active ||
      oldDelegate.text != text ||
      oldDelegate.words != words ||
      oldDelegate.style != style ||
      oldDelegate.highlightAlpha != highlightAlpha ||
      oldDelegate.animateWords != animateWords ||
      oldDelegate.emphasizeLongWords != emphasizeLongWords ||
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
) {
  if (progress <= 0) return;
  final mask = _createWordHighlightMask(wordRect, progress, isRtl);
  canvas.saveLayer(mask.rect, Paint());
  canvas.clipRect(wordRect);
  painter.paint(canvas, painterOffset);
  canvas.drawRect(
    mask.rect,
    Paint()
      ..shader = mask.shader
      ..blendMode = BlendMode.dstIn,
  );
  canvas.restore();
}

({Rect rect, Shader shader, double fadeWidth}) _createWordHighlightMask(
  Rect wordRect,
  double progress,
  bool isRtl,
) {
  // 羽化宽度按实际字框高度计算，并通过移动遮罩保持连续渐变。
  final fadeWidth = math.max(1.0, wordRect.height * .5);
  final boundedProgress = progress.clamp(0.0, 1.0);
  final maskRect = Rect.fromLTRB(
    wordRect.left - fadeWidth,
    wordRect.top,
    wordRect.right + fadeWidth,
    wordRect.bottom,
  );
  // 完成阶段仍要让渐变继续移动一个羽化宽度，使羽化边缘自然越过
  // 字符边界，而不是在 progress == 1 时突然切换为纯色。
  final travelWidth = wordRect.width + fadeWidth;
  final edge = isRtl
      ? wordRect.right - boundedProgress * travelWidth
      : wordRect.left + boundedProgress * travelWidth;
  final transitionStart = isRtl ? edge : edge - fadeWidth;
  final transitionEnd = isRtl ? edge + fadeWidth : edge;
  final totalWidth = math.max(1.0, maskRect.width);
  final transitionStartStop = ((transitionStart - maskRect.left) / totalWidth)
      .clamp(0.0, 1.0);
  final transitionEndStop = ((transitionEnd - maskRect.left) / totalWidth)
      .clamp(0.0, 1.0);
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
    stops: [0, transitionStartStop, transitionEndStop, 1],
  ).createShader(maskRect);
  return (rect: maskRect, shader: shader, fadeWidth: fadeWidth);
}

void _paintWordEmphasis(
  Canvas canvas, {
  required String text,
  required (int, int) range,
  required TextPainter painter,
  required TextPainter brightPainter,
  required TextStyle style,
  required LyricWord word,
  required Duration end,
  required int elapsedMicroseconds,
  required bool isLastWord,
  required bool isBackground,
  required Offset painterOffset,
  required double highlightProgress,
  required bool isRtl,
  required Rect wordRect,
}) {
  final duration = math.max(
    const Duration(milliseconds: 1000).inMicroseconds,
    (end - word.start).inMicroseconds,
  );
  var amount = duration / const Duration(milliseconds: 2000).inMicroseconds;
  amount = amount > 1 ? math.sqrt(amount) : math.pow(amount, 3).toDouble();
  var blur = duration / const Duration(milliseconds: 3000).inMicroseconds;
  blur = blur > 1 ? math.sqrt(blur) : math.pow(blur, 3).toDouble();
  amount *= .6;
  blur *= .5;
  var animationDuration = duration.toDouble();
  if (isLastWord) {
    amount *= 1.6;
    blur *= 1.5;
    animationDuration *= 1.2;
  }
  amount = math.min(1.2, amount);
  blur = math.min(.8, blur);
  final graphemes = word.text.trim().characters.toList();
  if (graphemes.isEmpty) return;

  var charOffset = range.$1;
  for (var index = 0; index < graphemes.length; index++) {
    final grapheme = graphemes[index];
    final start = text.indexOf(grapheme, charOffset);
    if (start < 0 || start >= range.$2) continue;
    final finish = math.min(range.$2, start + grapheme.length);
    charOffset = finish;
    final delay = duration / 2.5 / graphemes.length * index;
    final progress = ((elapsedMicroseconds - delay) / animationDuration).clamp(
      0.0,
      1.0,
    );
    if (progress <= 0) continue;

    final charBoxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: finish),
    );
    if (charBoxes.isEmpty) continue;
    final emphasized = _amllEmphasisEase(progress);
    final glow = emphasized * blur;
    final floatProgress =
        ((elapsedMicroseconds - delay + 400000) / (animationDuration * 1.4))
            .clamp(0.0, 1.0);
    final floatOffset =
        -math.sin(math.pi * floatProgress) * (isBackground ? 0.12 : 0.06);
    final scale = 1 + emphasized * .1 * amount;
    final horizontalOffset =
        -emphasized * .03 * amount * (graphemes.length / 2 - index);
    final verticalOffset = -emphasized * .03 * amount + floatOffset;

    final blurSigma = math.max(.8, glow * style.fontSize! * .3);
    final glowAlpha = (glow * 510).round().clamp(0, 255);
    final glowPaint = Paint()
      ..colorFilter = ColorFilter.mode(
        Colors.white.withAlpha(glowAlpha),
        BlendMode.srcIn,
      )
      ..imageFilter = ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
    for (final charBox in charBoxes) {
      final charRect = charBox.toRect().shift(painterOffset);
      final center = charRect.center;
      final characterOffset = Offset(
        horizontalOffset * style.fontSize!,
        verticalOffset * style.fontSize!,
      );
      final transformedRect = charRect.shift(characterOffset);
      final highlightMask = _createWordHighlightMask(
        wordRect,
        highlightProgress,
        isRtl,
      );

      // AMLL 的字符动画使用 composite: replace。先清除原字符，再绘制
      // 变换后的暗色底字和亮色辉光，避免原位置残留第二个影子。
      canvas.drawRect(
        charRect.inflate(1),
        Paint()..blendMode = BlendMode.clear,
      );
      canvas.save();
      canvas.translate(characterOffset.dx, characterOffset.dy);
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale, scale);
      canvas.translate(-center.dx, -center.dy);
      canvas.clipRect(charRect.inflate(blurSigma));
      painter.paint(canvas, painterOffset);
      canvas.restore();

      canvas.saveLayer(transformedRect.inflate(blurSigma * 3), Paint());
      canvas.saveLayer(transformedRect.inflate(blurSigma * 3), glowPaint);
      canvas.save();
      canvas.translate(characterOffset.dx, characterOffset.dy);
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale, scale);
      canvas.translate(-center.dx, -center.dy);
      canvas.clipRect(charRect.inflate(blurSigma));
      brightPainter.paint(canvas, painterOffset);
      canvas.restore();
      canvas.restore();

      // text-shadow 只负责光晕，清晰的高亮字符需要在模糊层之后再次绘制。
      canvas.save();
      canvas.translate(characterOffset.dx, characterOffset.dy);
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale, scale);
      canvas.translate(-center.dx, -center.dy);
      canvas.clipRect(charRect.inflate(blurSigma));
      brightPainter.paint(canvas, painterOffset);
      canvas.restore();
      canvas.drawRect(
        highlightMask.rect,
        Paint()
          ..shader = highlightMask.shader
          ..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    }
  }
}

double _amllEmphasisEase(double value) {
  final progress = value.clamp(0.0, 1.0);
  if (progress < .5) {
    return const Cubic(.2, .4, .58, 1).transform(progress * 2);
  }
  return 1 - const Cubic(.3, 0, .58, 1).transform((progress - .5) * 2);
}

bool _shouldEmphasizeWord(String text, Duration duration) {
  if (duration < const Duration(seconds: 1)) return false;
  final graphemeCount = text.trim().characters.length;
  final containsCjk = RegExp(r'[\u2E80-\u9FFF\uF900-\uFAFF]').hasMatch(text);
  return containsCjk || (graphemeCount > 1 && graphemeCount <= 7);
}

List<(int, int)> _wordRanges(String text, List<LyricWord> words) {
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
  final declaredEnd = line.end ?? nextStart;
  var latestEnd = declaredEnd;
  final wordEnd = line.words.lastOrNull?.end;
  if (wordEnd != null && wordEnd > latestEnd) latestEnd = wordEnd;
  for (final variant in line.variants) {
    final variantEnd = variant.end ?? variant.words.lastOrNull?.end;
    if (variantEnd != null && variantEnd > latestEnd) latestEnd = variantEnd;
  }
  return latestEnd;
}

double _translationFontSize(double fontSize) => fontSize * .8;

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
  final horizontalPadding = lyricFontSize * _lyricVerticalPaddingEm;
  final lineWidth = math.max(1.0, viewportWidth - horizontalPadding * 2);
  var contentHeight = _measureLyricTextHeight(
    line.text,
    context: context,
    fontSize: lyricFontSize,
    weight: FontWeight.w600,
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
      weight: FontWeight.w500,
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
      weight: isTranslation ? FontWeight.w500 : FontWeight.w600,
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

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  final sign = seconds < 0 ? '-' : '';
  final absolute = seconds.abs();
  final minutes = absolute ~/ 60;
  final remainder = absolute % 60;
  return '$sign$minutes:${remainder.toString().padLeft(2, '0')}';
}
