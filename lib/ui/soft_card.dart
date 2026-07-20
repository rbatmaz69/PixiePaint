import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'pixie_palette.dart';

/// Rounded card with a pastel gradient (or flat color) and a soft colored
/// shadow — the basic surface of the playful design language.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.gradient,
    this.color,
    this.radius = PixieTokens.rCard,
    this.shadowColor,
    this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final double radius;
  final Color? shadowColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Color shadow = shadowColor ??
        (gradient is LinearGradient
            ? (gradient as LinearGradient).colors.last
            : (color ?? PixiePalette.ink));
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: PixieTokens.softShadow(shadow),
      ),
      child: child,
    );
  }
}
