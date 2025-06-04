// lib/presentation/widgets/common/custom_button.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isActive;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isActive = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    if (backgroundColor != null) {
      bgColor = backgroundColor!;
    } else if (isActive && !isLoading) {
      bgColor = AppColors.primary;
    } else {
      bgColor = const Color(0xFFB5B5B7);
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppDimensions.buttonHeight,
      child: ElevatedButton(
        onPressed: (isActive && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor ?? AppColors.white,
          disabledBackgroundColor: const Color(0xFFB5B5B7),
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppDimensions.borderRadius,
            ),
          ),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeRegular,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
