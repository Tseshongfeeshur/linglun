import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 圆角矩形"孔"裁剪器：inverted 为 false 时只保留孔内，为 true 时只保留孔外
/// （用整个矩形减去孔，Path.combine 的差集）。
class _RRectHoleClipper extends CustomClipper<Path> {
  final RRect hole;

  final bool inverted; // true: 保留孔外

  const new({required this.hole, required this.inverted});

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
  bool shouldReclip(_RRectHoleClipper old) =>
      old.hole != hole || old.inverted != inverted;
}

/// "揭开"式的图标切换动画：轮廓图标 ↔ 填充图标。
/// 原理：两个图标叠放，共用同一个圆角方形的"孔"——上层（填充）挖掉孔，
/// 下层（轮廓）只保留孔；孔从中心向外扩大，轮廓图标就逐渐取代填充图标。
/// 动画值 value：0 = 填充态（孔为 0，只看到填充），1 = 轮廓态（孔≥图标，只看到轮廓）。
class RevealIcon extends StatelessWidget {
  final bool isFilled;
  final IconData outlineIcon;
  final IconData filledIcon;
  final Color? outlineIconColor;
  final Color? filledIconColor;
  final Duration? duration;
  final Curve? curve;
  final double? size;

  const new({
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
    final applyTextScaling = IconTheme.of(context).applyTextScaling ?? false;

    final tentativeIconSize =
        size ?? IconTheme.of(context).size ?? kDefaultFontSize;

    final iconSize = applyTextScaling
        ? MediaQuery.textScalerOf(context).scale(tentativeIconSize)
        : tentativeIconSize;

    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isFilled
        ? (filledIconColor ?? colorScheme.primary)
        : (outlineIconColor ?? colorScheme.onSurfaceVariant);

    // 注意方向：isFilled 时目标是 0，否则是 1。onInit 直接把动画放到目标位置，
    // 避免控件第一次出现时就播放一遍动画。
    return Animate(
      onInit: (controller) => controller.value = isFilled ? 0 : 1,
      target: isFilled ? 0 : 1,
    ).custom(
      duration: duration ?? 200.ms,
      curve: curve ?? Curves.easeInOutCubic,
      builder: (context, value, child) {
        // 圆角半径
        // value ≤ 0.95 时孔是（近似）圆形；最后 5% 圆角线性收缩到 0，
        // 让孔最终正好变成与图标等大的方形，露出完整的轮廓图标。
        final rawRadius = value <= 0.95
            ? (iconSize * 0.95 / 2)
            : (iconSize * 0.95 / 2 * ((1 - value) / 0.05));

        // 当前方块边长，半径不能超过边长的一半
        final side = iconSize * value;
        final radius = rawRadius.clamp(0.0, side / 2);

        // 上下两层共用的形状
        final hole = RRect.fromRectAndRadius(
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
                clipper: _RRectHoleClipper(hole: hole, inverted: true),
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
                clipper: _RRectHoleClipper(hole: hole, inverted: false),
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
