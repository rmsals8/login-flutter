// lib/presentation/widgets/common/divider_with_text.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class DividerWithText extends StatelessWidget {
  final String text;
  final Color? dividerColor;
  final Color? textColor;
  final double? fontSize;

  const DividerWithText({
    super.key,
    required this.text,
    this.dividerColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: dividerColor ?? AppColors.lightGrey,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? AppColors.grey,
              fontSize: fontSize ?? AppDimensions.fontSizeMedium,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: dividerColor ?? AppColors.lightGrey,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}