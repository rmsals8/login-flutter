// lib/presentation/widgets/login/social_login_buttons.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
 

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onKakaoLogin;
  final VoidCallback onNaverLogin;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    required this.onKakaoLogin,
    required this.onNaverLogin,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 카카오 로그인 버튼
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: isLoading ? null : onKakaoLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFE812),
              foregroundColor: const Color(0xFF3C1E1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                image: const DecorationImage(
                  image: AssetImage('assets/images/kakao_login_large_wide.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 네이버 로그인 버튼
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: isLoading ? null : onNaverLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03C75A),
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                image: const DecorationImage(
                  image: AssetImage('assets/images/naver_login_large_wide.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}