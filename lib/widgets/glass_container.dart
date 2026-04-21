import 'package:flutter/material.dart';

/// Material 3 styled container — replaces old glassmorphism
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur; // kept for API compat, ignored
  final double opacity; // kept for API compat, ignored
  final Color? borderColor;
  final double borderWidth;
  final bool enableBlur; // kept for API compat, ignored
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 0,
    this.opacity = 0,
    this.borderColor,
    this.borderWidth = 0,
    this.enableBlur = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: margin ?? EdgeInsets.zero,
      elevation: 0,
      color: color ?? colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: borderWidth)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}

/// Background wrapper — teraz po prostu zwraca dziecko,
/// bo tło jest obsługiwane przez scaffoldBackgroundColor w ThemeData
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;

  const LiquidGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
