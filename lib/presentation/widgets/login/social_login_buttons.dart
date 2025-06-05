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
        // 카카오 로그인 버튼 (이미지 사용하되 비율 조정)
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
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    // 카카오 이미지 (비율 조정해서 잘리지 않게)
                    Center(
                      child: Image.asset(
                        'assets/images/kakao_login_large_wide.png',
                        width: double.infinity,
                        height: 40, // 높이를 좀 더 키움 (35 → 40)
                        fit: BoxFit.contain, // contain으로 변경해서 비율 유지
                      ),
                    ),
                    // 로딩 표시
                    if (isLoading)
                      const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // 네이버 로그인 버튼 (Vue.js 스타일로 N을 왼쪽에 크게)
        GestureDetector(
          onTap: isLoading ? null : onNaverLogin,
          child: Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF03C75A), // 네이버 초록색
              borderRadius: BorderRadius.circular(6),
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
                : Row(
                    children: [
                      const SizedBox(width: 12), // 왼쪽 여백을 더 줄임 (20 → 12)
                      // 네이버 N 로고 (크고 볼드하게)
                      Container(
                        width: 24, // 로고 크기 줄임 (28 → 24)
                        height: 24, // 로고 크기 줄임 (28 → 24)
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            'N',
                            style: TextStyle(
                              fontSize: 16, // 글자도 조금 줄임 (18 → 16)
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF03C75A),
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            '네이버 로그인',
                            style: TextStyle(
                              fontSize: 14, // 글자 크기 줄임 (16 → 14)
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // 오른쪽 여백 조정 (48 → 40)
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}