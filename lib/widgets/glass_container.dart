import 'package:flutter/material.dart';

/// Material 3 styled container — replaces old glassmorphism
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.borderColor,
    this.borderWidth = 0,
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
