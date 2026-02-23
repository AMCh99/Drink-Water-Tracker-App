import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism container — frosted glass effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  /// Gdy false — pomija kosztowny BackdropFilter (blur), zachowując efekt
  /// szkła przez kolor i border. Używaj false w listach dla wydajności.
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 20,
    this.opacity = 0.12,
    this.borderColor,
    this.borderWidth = 1.0,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = Theme.of(context).scaffoldBackgroundColor == Colors.black;

    // Lekko wyższy opacity gdy brak blur — kompensuje brak efektu frosted
    final bgColor = isOled
        ? Colors.white.withValues(alpha: enableBlur ? 0.22 : 0.14)
        : isDark
        ? Colors.white.withValues(alpha: enableBlur ? 0.28 : 0.18)
        : Colors.white.withValues(alpha: enableBlur ? 0.55 : 0.45);

    final border =
        borderColor ??
        (isOled
            ? Colors.white.withValues(alpha: 0.25)
            : isDark
            ? Colors.white.withValues(alpha: 0.30)
            : Colors.white.withValues(alpha: 0.60));

    final highlightColor = isOled
        ? Colors.white.withValues(alpha: enableBlur ? 0.18 : 0.10)
        : isDark
        ? Colors.white.withValues(alpha: enableBlur ? 0.22 : 0.12)
        : Colors.white.withValues(alpha: enableBlur ? 0.35 : 0.20);

    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: borderWidth),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlightColor, Colors.transparent],
        ),
      ),
      child: child,
    );

    if (!enableBlur) {
      return Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: decorated,
        ),
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: decorated,
        ),
      ),
    );
  }
}

/// Gradient background for liquid glass style
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;

  const LiquidGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOled = Theme.of(context).scaffoldBackgroundColor == Colors.black;

    if (isOled) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF040810)],
          ),
        ),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0E1F3D),
                  const Color(0xFF163560),
                  const Color(0xFF1A3A68),
                  const Color(0xFF0E1F3D),
                ]
              : [
                  const Color(0xFFDCEEFB),
                  const Color(0xFFC4E2F8),
                  const Color(0xFFADD6F3),
                  const Color(0xFFC8E5F9),
                ],
        ),
      ),
      child: child,
    );
  }
}
