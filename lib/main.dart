// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'core/utils/storage_helper.dart';
import 'data/services/api_service.dart';
import 'core/constants/app_colors.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/login_provider.dart';
import 'presentation/providers/captcha_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/social_login_callback_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 강력한 SSL 검증 완전 무시
  HttpOverrides.global = DevHttpOverrides();
  
  // 필수 서비스 초기화
  await _initializeServices();
  
  runApp(const MyApp());
}

// 🔥 개발용 HTTP 오버라이드 (모든 SSL 무시)
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // 🔥 모든 SSL 인증서 무시
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      print('🔓 SSL 인증서 무시: $host:$port');
      return true; // 모든 인증서 허용
    };
    
    // 🔥 타임아웃 설정
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 30);
    
    return client;
  }
}

Future<void> _initializeServices() async {
  try {
    // SharedPreferences 초기화
    await StorageHelper.init();
    print('✅ StorageHelper 초기화 완료');
    
    // API 서비스 초기화
    ApiService().init();
    print('✅ ApiService 초기화 완료');
    
    // 환경 변수 로깅
    print('🌍 현재 환경: development');
    print('🔗 API URL: https://3.37.89.76');
    
  } catch (e) {
    print('❌ 서비스 초기화 실패: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => CaptchaProvider()),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'Flutter Login App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              centerTitle: true,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.inputFocused),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
          routerConfig: _createRouter(context),
        ),
      ),
    );
  }

  // 🔥 라우터 생성 (context 전달로 Provider 접근 가능하게)
  GoRouter _createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: true, // 디버그 로그 활성화
      routes: [
        // 스플래시 화면
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) {
            print('🔄 Splash 화면 라우트 호출');
            return const SplashScreen();
          },
        ),
        
        // 로그인 화면
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) {
            print('🔄 Login 화면 라우트 호출');
            return const LoginScreen();
          },
        ),
        
        // 대시보드 화면
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) {
            print('🔄 Dashboard 화면 라우트 호출');
            return const DashboardScreen();
          },
        ),
        
        // 🔥 소셜 로그인 콜백 처리
        GoRoute(
          path: '/auth/callback',
          name: 'auth-callback',
          builder: (context, state) {
            print('🔄 소셜 로그인 콜백 라우트 호출');
            print('📦 쿼리 파라미터: ${state.uri.queryParameters}');
            return SocialLoginCallbackScreen(queryParams: state.uri.queryParameters);
          },
        ),
      ],
      redirect: (context, state) {
        final location = state.matchedLocation;
        print('🚦 라우터 리다이렉트 체크: $location');
        
        try {
          // Provider 안전하게 접근
          final authProvider = context.read<AuthProvider>();
          final isLoggedIn = authProvider.isAuthenticated;
          
          print('🔐 인증 상태: $isLoggedIn');
          
          // 스플래시나 콜백 화면은 항상 허용
          if (location == '/splash' || location.startsWith('/auth/callback')) {
            print('✅ 특별 경로 허용: $location');
            return null;
          }
          
          // 로그인되지 않은 상태에서 대시보드 접근 시
          if (!isLoggedIn && location == '/dashboard') {
            print('🚫 비인증 상태에서 대시보드 접근 → 로그인으로 리다이렉트');
            return '/login';
          }
          
          // 로그인된 상태에서 로그인 페이지 접근 시
          if (isLoggedIn && location == '/login') {
            print('🚫 인증된 상태에서 로그인 페이지 접근 → 대시보드로 리다이렉트');
            return '/dashboard';
          }
          
          print('✅ 리다이렉트 없음: $location');
          return null;
        } catch (e) {
          print('❌ 라우터 리다이렉트 오류: $e');
          return null;
        }
      },
      errorBuilder: (context, state) {
        print('❌ 라우터 에러: ${state.error}');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  '페이지를 찾을 수 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.error}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    print('🔄 에러 화면에서 로그인으로 이동');
                    context.go('/login');
                  },
                  child: const Text('로그인으로 이동'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}