import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RRectHoleClipper extends CustomClipper<Path> {
  final RRect hole;

  final bool inverted; // true: 保留孔外

  const RRectHoleClipper({required this.hole, required this.inverted});

  @override
  Path getClip(Size size) {
    final holePath = Path()..addRRect(hole);
    if (!inverted) return holePath;

    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      holePath,
    );
  }

  @override
  bool shouldReclip(RRectHoleClipper old) =>
      old.hole != hole || old.inverted != inverted;
}

class RevealIcon extends StatelessWidget {
  final bool isFilled;
  final IconData outlineIcon;
  final IconData filledIcon;
  final Color? outlineIconColor;
  final Color? filledIconColor;
  final Duration? duration;
  final Curve? curve;
  final double? size;

  const RevealIcon({
    super.key,
    required this.isFilled,
    required this.outlineIcon,
    required this.filledIcon,
    this.outlineIconColor,
    this.filledIconColor,
    this.duration,
    this.curve,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final bool applyTextScaling =
        IconTheme.of(context).applyTextScaling ?? false;

    final double tentativeIconSize =
        size ?? IconTheme.of(context).size ?? kDefaultFontSize;

    final double iconSize = applyTextScaling
        ? MediaQuery.textScalerOf(context).scale(tentativeIconSize)
        : tentativeIconSize;

    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isFilled
        ? (filledIconColor ?? colorScheme.primary)
        : (outlineIconColor ?? colorScheme.onSurfaceVariant);

    return Animate(target: isFilled ? 0 : 1).custom(
      duration: duration ?? 200.ms,
      curve: curve ?? Curves.easeInOutCubic,
      builder: (context, value, child) {
        // 圆角半径
        final double rawRadius = value <= 0.95
            ? (iconSize * 0.95 / 2)
            : (iconSize * 0.95 / 2 * ((1 - value) / 0.05));

        // 当前方块边长，半径不能超过边长的一半
        final double side = iconSize * value;
        final double radius = rawRadius.clamp(0.0, side / 2);

        // 上下两层共用的形状
        final RRect hole = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(iconSize / 2, iconSize / 2),
            width: side,
            height: side,
          ),
          Radius.circular(radius),
        );

        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 上层 挖掉孔
              ClipPath(
                clipper: RRectHoleClipper(hole: hole, inverted: true),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Center(
                    child: Icon(filledIcon, color: iconColor, size: size),
                  ),
                ),
              ),
              // 下层 保留孔
              ClipPath(
                clipper: RRectHoleClipper(hole: hole, inverted: false),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Center(
                    child: Icon(outlineIcon, color: iconColor, size: size),
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
