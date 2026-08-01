import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<Color>? gradientColors;
  final bool glow;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.gradientColors,
    this.glow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          if (glow)
            BoxShadow(
              color: (glowColor ?? AppColors.electricBlue).withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: -5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? [
                  const Color(0x18FFFFFF),
                  const Color(0x08FFFFFF),
                ],
                stops: const [0.0, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: const Color(0x28FFFFFF),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Premium Gradient Card (for metrics)
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}
