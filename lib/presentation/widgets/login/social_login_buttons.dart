import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onKakaoLogin;
  final VoidCallback onNaverLogin;
  // 🔥 각각의 로딩 상태를 받는 변수들
  final bool isKakaoLoading;
  final bool isNaverLoading;
  // 🔥 일반 로그인 로딩 상태도 받기
  final bool isGeneralLoading;

  const SocialLoginButtons({
    super.key,
    required this.onKakaoLogin,
    required this.onNaverLogin,
    // 🔥 각각의 로딩 상태를 받도록 수정
    this.isKakaoLoading = false,
    this.isNaverLoading = false,
    this.isGeneralLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 다른 로그인이 진행 중인지 확인하는 변수들
    final isKakaoDisabled = isKakaoLoading || isNaverLoading || isGeneralLoading;
    final isNaverDisabled = isNaverLoading || isKakaoLoading || isGeneralLoading;
    
    return Column(
      children: [
        // 카카오 로그인 버튼
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            // 🔥 카카오가 비활성화되어야 할 때 null 전달
            onPressed: isKakaoDisabled ? null : onKakaoLogin,
            style: ElevatedButton.styleFrom(
              // 🔥 비활성화될 때 색상 변경
              backgroundColor: isKakaoDisabled 
                  ? const Color(0xFFE0E0E0) 
                  : const Color(0xFFFFE812),
              foregroundColor: isKakaoDisabled 
                  ? const Color(0xFF9E9E9E) 
                  : const Color(0xFF3C1E1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.zero,
              // 🔥 비활성화 상태 스타일
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              disabledForegroundColor: const Color(0xFF9E9E9E),
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
                    // 카카오 이미지
                    Center(
                      child: Opacity(
                        // 🔥 비활성화될 때 투명도 조절
                        opacity: isKakaoDisabled ? 0.5 : 1.0,
                        child: Image.asset(
                          'assets/images/kakao_login_large_wide.png',
                          width: double.infinity,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // 🔥 카카오 로딩 표시 (카카오 로딩일 때만)
                    if (isKakaoLoading)
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
                    // 🔥 다른 로그인 진행 중일 때 표시
                    if (isNaverLoading || isGeneralLoading)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '대기 중',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
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
        
        // 네이버 로그인 버튼
        GestureDetector(
          // 🔥 네이버가 비활성화되어야 할 때 null 전달
          onTap: isNaverDisabled ? null : onNaverLogin,
          child: Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(
              // 🔥 비활성화될 때 색상 변경
              color: isNaverDisabled 
                  ? const Color(0xFFE0E0E0) 
                  : const Color(0xFF03C75A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                // 🔥 네이버 로딩일 때만 로딩 표시
                if (isNaverLoading)
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    ),
                  )
                // 🔥 다른 로그인 진행 중일 때 표시
                else if (isKakaoLoading || isGeneralLoading)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '대기 중',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                // 🔥 일반 상태일 때 네이버 버튼 내용
                else
                  Opacity(
                    // 🔥 비활성화될 때 투명도 조절
                    opacity: isNaverDisabled ? 0.5 : 1.0,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        // 네이버 N 로고
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              'N',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isNaverDisabled 
                                    ? const Color(0xFF9E9E9E)
                                    : const Color(0xFF03C75A),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '네이버 로그인',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isNaverDisabled 
                                    ? const Color(0xFF9E9E9E)
                                    : AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}