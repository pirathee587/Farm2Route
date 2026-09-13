import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AgrizelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool hasBorder;

  const AgrizelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius = 20.0,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardDecoration = BoxDecoration(
      color: color ?? AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder ? Border.all(color: AppColors.border, width: 1) : null,
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: cardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: cardDecoration,
      child: child,
    );
  }
}
