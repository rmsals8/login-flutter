// lib/presentation/screens/social_login_callback_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;
import '../../core/constants/app_colors.dart';
import '../../core/utils/storage_helper.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class SocialLoginCallbackScreen extends StatefulWidget {
  final Map<String, String> queryParams;

  const SocialLoginCallbackScreen({
    super.key,
    required this.queryParams,
  });

  @override
  State<SocialLoginCallbackScreen> createState() => _SocialLoginCallbackScreenState();
}

class _SocialLoginCallbackScreenState extends State<SocialLoginCallbackScreen> {
  @override
  void initState() {
    super.initState();
    print('🔄 소셜 로그인 콜백 화면 초기화');
    _processSocialLoginCallback();
  }

  Future<void> _processSocialLoginCallback() async {
    print('🔄 소셜 로그인 콜백 처리 시작');
    print('📦 쿼리 파라미터: ${widget.queryParams}');

    try {
      final token = widget.queryParams['token'];
      final userId = widget.queryParams['userId'];
      final username = widget.queryParams['username'];
      final loginType = widget.queryParams['loginType'];
      final error = widget.queryParams['error'];

      // 에러 체크
      if (error != null) {
        print('❌ 소셜 로그인 에러: $error');
        _handleError(error);
        return;
      }

      // 성공 데이터 체크
      if (token != null && userId != null && username != null) {
        print('✅ 소셜 로그인 성공 데이터 확인');
        print('  - token: ${token.substring(0, 20)}...');
        print('  - userId: $userId');
        print('  - username: $username');
        print('  - loginType: $loginType');

        // 🔥 토큰 저장
        await StorageHelper.setToken(token);
        print('💾 토큰 저장 완료');

        // 🔥 사용자 정보 저장
        final userModel = UserModel(
          userId: userId,
          username: Uri.decodeComponent(username), // URL 디코딩
          loginType: loginType ?? 'social',
        );
        
        await StorageHelper.setUserData(userModel.toJson());
        print('👤 사용자 정보 저장 완료: ${userModel.username}');

        // 로그인 실패 횟수 초기화
        await StorageHelper.removeLoginFailCount();
        print('📊 로그인 실패 횟수 초기화');

        // 🔥 AuthProvider 업데이트
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          authProvider.setUser(userModel);
          await authProvider.init();
          print('🔐 AuthProvider 업데이트 완료');
          print('👤 현재 사용자: ${authProvider.currentUser?.username}');
          print('🔐 인증 상태: ${authProvider.isAuthenticated}');

          // 잠시 대기 후 대시보드로 이동
          await Future.delayed(const Duration(milliseconds: 1000));

          // 🚀 여러 방법으로 대시보드 이동 시도
          if (mounted) {
            print('🚀 대시보드로 이동 시작');
            
            try {
              // 방법 1: context.go
              context.go('/dashboard');
              print('✅ context.go 실행');
              
              // 2초 후 확인
              await Future.delayed(const Duration(milliseconds: 2000));
              
              final currentLocation = GoRouterState.of(context).matchedLocation;
              print('📍 현재 위치: $currentLocation');
              
              if (currentLocation != '/dashboard') {
                print('⚠️ context.go 실패, 강제 이동 시도');
                
                // 방법 2: 강제 새로고침
                html.window.location.href = '/dashboard';
                print('🔄 강제 새로고침 실행');
              }
              
            } catch (e) {
              print('❌ 네비게이션 오류: $e');
              html.window.location.href = '/dashboard';
            }
          }
        }
      } else {
        print('❌ 필수 파라미터 누락');
        print('  - token: ${token != null ? "있음" : "없음"}');
        print('  - userId: ${userId != null ? "있음" : "없음"}');
        print('  - username: ${username != null ? "있음" : "없음"}');
        _handleError('소셜 로그인 정보가 불완전합니다.');
      }
    } catch (e) {
      print('💥 소셜 로그인 콜백 처리 예외: $e');
      _handleError('소셜 로그인 처리 중 오류가 발생했습니다.');
    }
  }

  void _handleError(String error) {
    print('❌ 소셜 로그인 에러 처리: $error');
    
    // 에러가 발생하면 로그인 페이지로 이동하면서 에러 메시지 전달
    if (mounted) {
      try {
        context.go('/login?error=${Uri.encodeComponent(error)}');
      } catch (e) {
        print('❌ 에러 페이지 이동 실패: $e');
        html.window.location.href = '/login?error=${Uri.encodeComponent(error)}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로딩 애니메이션
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 로딩 텍스트
            Text(
              '소셜 로그인 처리 중...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              '잠시만 기다려주세요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white.withOpacity(0.8),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 디버그 정보 (개발 중에만)
            if (widget.queryParams.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '디버그 정보:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.queryParams.entries.map((entry) => 
                      Text(
                        '${entry.key}: ${entry.value.length > 20 ? entry.value.substring(0, 20) + '...' : entry.value}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}