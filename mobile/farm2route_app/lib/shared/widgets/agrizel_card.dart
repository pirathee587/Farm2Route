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
        border:
            hasBorder ? Border.all(color: AppColors.border, width: 1) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardWidget,
        ),
      );
    }

    // ListTile and other Material children need a Material ancestor for
    // their ink splashes and tile backgrounds to render correctly.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: cardWidget,
    );
  }
}
