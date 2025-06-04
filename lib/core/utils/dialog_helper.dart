// lib/core/utils/dialog_helper.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DialogHelper {
  static Future<void> showErrorDialog(
    BuildContext context,
    String message, {
    String title = '오류',
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showSuccessDialog(
    BuildContext context,
    String message, {
    String title = '성공',
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context,
    String message, {
    String title = '확인',
    String confirmText = '확인',
    String cancelText = '취소',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: const TextStyle(color: AppColors.darkGrey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}