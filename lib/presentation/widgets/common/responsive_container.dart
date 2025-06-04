// lib/presentation/widgets/common/responsive_container.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppDimensions.maxFormWidth,
        ),
        padding: padding ?? const EdgeInsets.all(AppDimensions.padding),
        margin: margin,
        child: child,
      ),
    );
  }
}