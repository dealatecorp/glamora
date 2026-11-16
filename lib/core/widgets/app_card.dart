import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_radius.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.glassSurface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.large),
        border: Border.all(color: borderColor ?? AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}
