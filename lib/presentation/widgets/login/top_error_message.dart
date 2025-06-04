// lib/presentation/widgets/login/top_error_message.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';

class TopErrorMessage extends StatelessWidget {
  final String message;
  final bool show;

  const TopErrorMessage({
    super.key,
    required this.message,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F9),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF1F1F1F),
          fontSize: AppDimensions.fontSizeMedium,
          height: 1.5,
        ),
      ),
    );
  }
}