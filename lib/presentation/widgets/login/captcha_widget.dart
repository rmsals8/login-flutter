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
            child: captchaImageUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              child: _buildCaptchaImage(captchaImageUrl!),
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

  // 🔥 새로 추가된 메소드: Base64 이미지를 올바르게 표시
  Widget _buildCaptchaImage(String captchaImageUrl) {
    try {
      print('🎨 캡차 이미지 빌드 시작: ${captchaImageUrl.substring(0, 50)}...');

      // Base64 데이터인지 확인
      if (captchaImageUrl.startsWith('data:image/')) {
        print('📸 Base64 이미지 데이터 감지');

        // Base64 데이터에서 실제 데이터 부분만 추출
        final parts = captchaImageUrl.split(',');
        if (parts.length == 2) {
          final base64Data = parts[1];
          print('🔄 Base64 데이터 디코딩 시작 (길이: ${base64Data.length})');

          final bytes = base64Decode(base64Data);
          print('✅ Base64 디코딩 성공 (바이트 길이: ${bytes.length})');

          // Image.memory로 Base64 데이터 표시
          return Image.memory(
            bytes,
            width: double.infinity,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Image.memory 에러: $error');
              return _buildErrorContainer('캡차 이미지 표시 실패');
            },
          );
        } else {
          print('❌ Base64 데이터 형식 오류: parts.length = ${parts.length}');
          return _buildErrorContainer('잘못된 이미지 형식');
        }
      } else {
        print('🌐 URL 이미지 데이터 감지');
        // URL인 경우 기존 방식 사용
        return Image.network(
          captchaImageUrl,
          width: double.infinity,
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Image.network 에러: $error');
            return _buildErrorContainer('캡차 이미지를 불러올 수 없습니다');
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
        );
      }
    } catch (e) {
      print('💥 캡차 이미지 변환 실패: $e');
      return _buildErrorContainer('이미지 처리 중 오류 발생');
    }
  }

  // 🔥 에러 컨테이너 생성 헬퍼 메소드
  Widget _buildErrorContainer(String message) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.error,
            fontSize: AppDimensions.fontSizeMedium,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}