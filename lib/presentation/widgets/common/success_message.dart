// lib/presentation/widgets/common/success_message.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class SuccessMessage extends StatelessWidget {
  final String message;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? textColor;

  const SuccessMessage({
    super.key,
    required this.message,
    this.padding,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: textColor ?? AppColors.success,
          fontSize: AppDimensions.fontSizeMedium,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}