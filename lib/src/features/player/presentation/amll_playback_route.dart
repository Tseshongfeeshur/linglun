import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';
import 'amll_playback_page.dart';
import 'playback_progress_circle.dart';

/// 播放页的自定义路由，负责圆形揭示、焦点和全屏命中隔离。
class AmllPlaybackPageRoute extends PageRoute<void> {
  AmllPlaybackPageRoute({required this.sourceCenter, super.settings})
    : super(
        barrierDismissible: false,
        fullscreenDialog: false,
        requestFocus: true,
      );

  final Offset sourceCenter;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  bool get allowSnapshotting => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 420);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return const _PlaybackRouteContent();
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _AmllPlaybackRouteTransition(
      animation: animation,
      sourceCenter: sourceCenter,
      child: child,
    );
  }
}

class _PlaybackRouteContent extends ConsumerWidget {
  const _PlaybackRouteContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    return Material(
      type: MaterialType.transparency,
      child: AmllPlaybackPage(
        track: state.currentTrack,
        state: state,
        onClose: () => Navigator.of(context).pop(),
        onPrevious: controller.previous,
        onTogglePlay: controller.togglePlay,
        onNext: controller.skipNext,
        onSeek: controller.seek,
        onToggleShuffle: controller.toggleShuffle,
        onCycleRepeat: controller.cycleRepeatMode,
        onPlayTrack: (track) => unawaited(controller.playTrack(track)),
      ),
    );
  }
}

class _AmllPlaybackRouteTransition extends ConsumerWidget {
  const _AmllPlaybackRouteTransition({
    required this.animation,
    required this.sourceCenter,
    required this.child,
  });

  final Animation<double> animation;
  final Offset sourceCenter;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final value = curved.value;
        final viewport = MediaQuery.sizeOf(context);
        final targetRadius = [
          sourceCenter.distance,
          (sourceCenter - Offset(viewport.width, 0)).distance,
          (sourceCenter - Offset(0, viewport.height)).distance,
          (sourceCenter - Offset(viewport.width, viewport.height)).distance,
        ].reduce(math.max);
        final maxRadius =
            ui.lerpDouble(playbackRingSize / 2, targetRadius + 20, value) ?? 0;
        return Listener(
          // 路由在整个窗口参与命中测试，即使揭示动画尚未覆盖整个窗口，
          // 事件也不会落到底下的主页。
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: _PlaybackRevealClipper(
                  center: sourceCenter,
                  radius: maxRadius,
                ),
                child: FadeTransition(opacity: curved, child: child),
              ),
              if (value < 1)
                Positioned(
                  left: sourceCenter.dx - playbackRingSize / 2,
                  top: sourceCenter.dy - playbackRingSize / 2,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: (1 - value).clamp(0, 1),
                      child: PlaybackProgressCircle(
                        track: state.currentTrack,
                        progress: _routeProgress(state),
                        bufferProgress: state.beatAnalysisProgress,
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

class _PlaybackRevealClipper extends CustomClipper<Path> {
  const _PlaybackRevealClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_PlaybackRevealClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}

double _routeProgress(PlayerState state) {
  final duration = state.currentTrack.duration.inMilliseconds;
  if (duration <= 0) return 0;
  return (state.position.inMilliseconds / duration).clamp(0, 1).toDouble();
}
