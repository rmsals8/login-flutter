// lib/presentation/widgets/login/captcha_widget.dart
import 'package:flutter/material.dart';
import 'dart:convert';
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
            child: _buildCaptchaImage(),
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

  Widget _buildCaptchaImage() {
    print('🖼️ 캡차 이미지 빌드 시작');
    print('📦 captchaImageUrl: $captchaImageUrl');
    print('⏳ isLoading: $isLoading');
    print('❌ errorMessage: $errorMessage');

    if (isLoading) {
      print('⏳ 로딩 상태 표시');
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
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      print('❌ 에러 메시지 표시: $errorMessage');
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 24),
              const SizedBox(height: 4),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: AppDimensions.fontSizeSmall,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (captchaImageUrl == null || captchaImageUrl!.isEmpty) {
      print('📭 캡차 이미지 URL이 없음');
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        child: const Center(
          child: Text(
            '캡차 이미지를 불러오는 중...',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: AppDimensions.fontSizeMedium,
            ),
          ),
        ),
      );
    }

    print('🖼️ 이미지 표시 시도');
    print('📄 URL 타입 확인: ${captchaImageUrl!.startsWith('data:image/')}');

    // 🔥 Base64 이미지 표시
    if (captchaImageUrl!.startsWith('data:image/')) {
      try {
        final base64String = captchaImageUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        print('✅ Base64 디코딩 성공: ${bytes.length} bytes');
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          child: Image.memory(
            bytes,
            width: double.infinity,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print('💥 Image.memory 에러: $error');
              return _buildErrorContainer('이미지 표시 실패');
            },
          ),
        );
      } catch (e) {
        print('💥 Base64 디코딩 실패: $e');
        return _buildErrorContainer('이미지 디코딩 실패');
      }
    }

    // 🔥 일반 URL 이미지 표시
    print('🌐 네트워크 이미지로 표시 시도');
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: Image.network(
        captchaImageUrl!,
        width: double.infinity,
        height: 80,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('✅ 네트워크 이미지 로드 완료');
            return child;
          }
          print('⏳ 네트워크 이미지 로딩 중...');
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
        errorBuilder: (context, error, stackTrace) {
          print('💥 네트워크 이미지 에러: $error');
          return _buildErrorContainer('네트워크 이미지 로드 실패');
        },
      ),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: AppColors.error, size: 24),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: AppDimensions.fontSizeSmall,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}