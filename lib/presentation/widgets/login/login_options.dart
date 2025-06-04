// lib/presentation/widgets/login/login_options.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';

class LoginOptions extends StatelessWidget {
  final bool rememberMe;
  final bool ipSecurity;
  final Function(bool) onRememberMeChanged;
  final Function(bool) onIpSecurityChanged;

  const LoginOptions({
    super.key,
    required this.rememberMe,
    required this.ipSecurity,
    required this.onRememberMeChanged,
    required this.onIpSecurityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 로그인 상태 유지
        Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: rememberMe,
                onChanged: (value) => onRememberMeChanged(value ?? false),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onRememberMeChanged(!rememberMe),
              child: const Text(
                AppStrings.rememberLogin,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        // IP 보안
        Row(
          children: [
            const Text(
              AppStrings.ipSecurity,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () => onIpSecurityChanged(!ipSecurity),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: ipSecurity ? AppColors.primary : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ipSecurity ? 'ON' : 'OFF',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}