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
    final cardWidget = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
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
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
