// lib/presentation/widgets/login/captcha_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';

class CaptchaWidget extends StatelessWidget {
  final String? captchaImageUrl;
  final TextEditingController captchaController;
  final VoidCallback onRefresh;
  final Function(String)? onChanged;
  final bool isLoading;
  final String? errorMessage;

  const CaptchaWidget({
    super.key,
    this.captchaImageUrl,
    required this.captchaController,
    required this.onRefresh,
    this.onChanged,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        color: AppColors.white,
      ),
      child: Column(
        children: [
          // 캡차 이미지 영역
          Container(
            padding: const EdgeInsets.all(15),
            child: captchaImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    child: Image.network(
                      captchaImageUrl!,
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          ),
                          child: const Center(
                            child: Text(
                              '캡차 이미지를 불러올 수 없습니다',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: AppDimensions.fontSizeMedium,
                              ),
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                    child: const Center(
                      child: Text(
                        '캡차 이미지 로딩 중...',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: AppDimensions.fontSizeMedium,
                        ),
                      ),
                    ),
                  ),
          ),
          // 캡차 입력 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: captchaController,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: AppStrings.captchaPlaceholder,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                        borderSide: const BorderSide(color: AppColors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                        borderSide: const BorderSide(color: AppColors.inputFocused),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeRegular,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 새로고침 버튼
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.inputBorder),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: IconButton(
                    onPressed: isLoading ? null : onRefresh,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: AppColors.darkGrey,
                            size: 18,
                          ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // 캡차 안내 텍스트
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.borderRadius),
                bottomRight: Radius.circular(AppDimensions.borderRadius),
              ),
            ),
            child: Text(
              AppStrings.captchaInstruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppDimensions.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}