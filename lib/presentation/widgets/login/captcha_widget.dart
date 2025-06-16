// lib/presentation/widgets/login/captcha_widget.dart
import 'dart:convert';

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
          // 🔥 캡차 이미지 영역 (개선된 버전)
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
                
                // 🔥 새로고침 버튼 (개선된 버전)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLoading ? AppColors.disabled : AppColors.background,
                    border: Border.all(
                      color: isLoading ? AppColors.disabled : AppColors.inputBorder
                    ),
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
          
          // 🔥 캡차 안내 텍스트 (상태에 따라 다르게 표시)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusBackgroundColor(),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.borderRadius),
                bottomRight: Radius.circular(AppDimensions.borderRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(),
                  size: 14,
                  color: _getStatusTextColor(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getStatusText(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _getStatusTextColor(),
                      fontSize: AppDimensions.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 캡차 이미지를 보여주는 위젯 (개선된 버전)
  Widget _buildCaptchaImage() {
    // 로딩 중일 때
    if (isLoading) {
      return _buildLoadingBox();
    }
    
    // 에러가 있을 때
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return _buildErrorBox();
    }
    
    // 이미지 URL이 있을 때
    if (captchaImageUrl != null && captchaImageUrl!.isNotEmpty) {
      return _buildImageBox();
    }
    
    // 기본 상태 (이미지가 없을 때)
    return _buildEmptyBox();
  }

  // 🔥 로딩 상태 박스
  Widget _buildLoadingBox() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 8),
            Text(
              '캡차 이미지 로딩 중...',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: AppDimensions.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 에러 상태 박스
  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '이미지 로드 실패',
              style: TextStyle(
                color: AppColors.error,
                fontSize: AppDimensions.fontSizeSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '새로고침 버튼을 눌러주세요',
              style: TextStyle(
                color: AppColors.error,
                fontSize: AppDimensions.fontSizeSmall - 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 실제 이미지 박스 (base64 데이터 처리용)
  Widget _buildImageBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: _buildCaptchaImageFromBase64(),
    );
  }

  // 🔥 base64 데이터에서 이미지를 만드는 메서드
  Widget _buildCaptchaImageFromBase64() {
    try {
      // base64 데이터 URI에서 실제 base64 부분만 추출한다
      final imageUrl = captchaImageUrl!;
      
      if (imageUrl.startsWith('data:image/')) {
        // 'data:image/jpeg;base64,' 부분을 제거하고 순수 base64 데이터만 남긴다
        final base64Data = imageUrl.split(',')[1];
        
        // base64를 bytes로 변환한다
        final bytes = base64Decode(base64Data);
        
        // Image.memory를 사용해서 bytes로 이미지를 만든다
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 80,
          fit: BoxFit.contain,
          
          // 🔥 이미지 로드에 실패했을 때 보여줄 위젯
          errorBuilder: (context, error, stackTrace) {
            print('❌ 캡차 이미지 메모리 로드 실패: $error');
            return _buildImageErrorWidget();
          },
        );
      } else {
        // base64 형식이 아니면 일반 네트워크 이미지로 처리
        return Image.network(
          imageUrl,
          width: double.infinity,
          height: 80,
          fit: BoxFit.contain,
          
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildImageLoadingWidget(loadingProgress);
          },
          
          errorBuilder: (context, error, stackTrace) {
            print('❌ 캡차 네트워크 이미지 로드 실패: $error');
            return _buildImageErrorWidget();
          },
        );
      }
    } catch (e) {
      print('❌ 캡차 이미지 처리 실패: $e');
      return _buildImageErrorWidget();
    }
  }

  // 🔥 이미지 로딩 중 위젯
  Widget _buildImageLoadingWidget(ImageChunkEvent loadingProgress) {
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
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '이미지 다운로드 중...',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: AppDimensions.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 이미지 에러 위젯
  Widget _buildImageErrorWidget() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '이미지를 불러올 수 없습니다',
              style: TextStyle(
                color: AppColors.error,
                fontSize: AppDimensions.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 빈 상태 박스
  Widget _buildEmptyBox() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: AppColors.grey,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              '캡차 이미지가 없습니다',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: AppDimensions.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 상태에 따른 배경색 결정
  Color _getStatusBackgroundColor() {
    if (isLoading) {
      return AppColors.primary.withOpacity(0.1);
    } else if (errorMessage != null && errorMessage!.isNotEmpty) {
      return AppColors.error.withOpacity(0.1);
    } else if (captchaImageUrl != null && captchaImageUrl!.isNotEmpty) {
      return AppColors.success.withOpacity(0.1);
    } else {
      return AppColors.background;
    }
  }

  // 🔥 상태에 따른 텍스트 색상 결정
  Color _getStatusTextColor() {
    if (isLoading) {
      return AppColors.primary;
    } else if (errorMessage != null && errorMessage!.isNotEmpty) {
      return AppColors.error;
    } else if (captchaImageUrl != null && captchaImageUrl!.isNotEmpty) {
      return AppColors.success;
    } else {
      return AppColors.grey;
    }
  }

  // 🔥 상태에 따른 아이콘 결정
  IconData _getStatusIcon() {
    if (isLoading) {
      return Icons.hourglass_empty;
    } else if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Icons.error_outline;
    } else if (captchaImageUrl != null && captchaImageUrl!.isNotEmpty) {
      return Icons.check_circle_outline;
    } else {
      return Icons.info_outline;
    }
  }

  // 🔥 상태에 따른 메시지 텍스트 결정
  String _getStatusText() {
    if (isLoading) {
      return '캡차 이미지를 불러오고 있습니다...';
    } else if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    } else if (captchaImageUrl != null && captchaImageUrl!.isNotEmpty) {
      return AppStrings.captchaInstruction;
    } else {
      return '새로고침 버튼을 눌러 캡차 이미지를 불러오세요';
    }
  }
}