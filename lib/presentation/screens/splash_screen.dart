// lib/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // AuthProvider 초기화
      final authProvider = context.read<AuthProvider>();
      await authProvider.init();
      
      // 2초 대기 (스플래시 효과)
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // 인증 상태에 따라 페이지 이동
        if (authProvider.isAuthenticated) {
          context.go('/dashboard');
        } else {
          context.go('/login');
        }
      }
    } catch (e) {
      print('앱 초기화 중 오류: $e');
      if (mounted) {
        context.go('/login');
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
            // 앱 로고 또는 아이콘
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flutter_dash,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // 앱 이름
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // 로딩 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}