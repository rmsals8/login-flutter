// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 🔥 카카오 SDK 추가
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

  // 🔥 카카오 SDK 초기화 추가
  KakaoSdk.init(
    nativeAppKey: '3c705327e15f9a41d47f7cb7f7d47e22',
    javaScriptAppKey: 'f58d90da996dde429e2b1bec01bd520b', // 웹에서도 같은 키 사용
  );
  print('✅ 카카오 SDK 초기화 완료');

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  // 🔥 Deep Link 초기화 (수정된 버전)
  void _initDeepLinks() {
    if (kIsWeb) {
      print('🌐 웹 환경: Deep Link 초기화 스킵');
      return;
    }

    print('📱 모바일 환경: Deep Link 초기화 시작');
    _appLinks = AppLinks();

    // 🔥 수정: getInitialAppLink() 사용
    _appLinks.getInitialAppLink().then((Uri? uri) {
      if (uri != null) {
        print('🔗 초기 Deep Link: $uri');
        _handleDeepLink(uri);
      }
    }).catchError((error) {
      print('❌ 초기 Deep Link 오류: $error');
    });

    // 🔥 수정: allUriLinkStream 사용
    _appLinks.allUriLinkStream.listen((Uri uri) {
      print('🔗 실시간 Deep Link: $uri');
      _handleDeepLink(uri);
    }, onError: (error) {
      print('❌ Deep Link 스트림 오류: $error');
    });
  }

  // 🔥 Deep Link 처리
  void _handleDeepLink(Uri uri) {
    print('🔄 Deep Link 처리 시작: $uri');
    print('  - scheme: ${uri.scheme}');
    print('  - path: ${uri.path}');
    print('  - queryParameters: ${uri.queryParameters}');

    // com.example.login://auth/callback?token=...&userId=... 형태
    if (uri.scheme == 'com.example.login' && uri.path == '/auth/callback') {
      final queryParams = uri.queryParameters;
      print('📦 Deep Link 파라미터: $queryParams');

      if (_router != null) {
        // 소셜 로그인 콜백 화면으로 이동
        print('🚀 콜백 화면으로 이동 시작');
        _router!.go('/auth/callback', extra: queryParams);
      } else {
        print('⚠️ Router가 아직 초기화되지 않음');
        // 잠시 후 다시 시도
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_router != null) {
            print('🔄 Router 초기화 후 재시도');
            _router!.go('/auth/callback', extra: queryParams);
          } else {
            print('❌ Router가 여전히 null');
          }
        });
      }
    } else {
      print('❌ 예상하지 못한 Deep Link 형태: ${uri.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => CaptchaProvider()),
      ],
      child: Builder(
        builder: (context) {
          _router = _createRouter(context);
          return MaterialApp.router(
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
            routerConfig: _router,
          );
        },
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

        // 🔥 소셜 로그인 콜백 처리 (웹과 모바일 모두)
        GoRoute(
          path: '/auth/callback',
          name: 'auth-callback',
          builder: (context, state) {
            print('🔄 소셜 로그인 콜백 라우트 호출');

            // 🔥 웹에서는 URL 파라미터, 모바일에서는 extra 파라미터 사용
            Map<String, String> queryParams;

            if (kIsWeb) {
              // 웹: URL 쿼리 파라미터 사용
              queryParams = state.uri.queryParameters;
              print('🌐 웹 쿼리 파라미터: $queryParams');
            } else {
              // 모바일: Deep Link extra 파라미터 사용
              final extraParams = state.extra;
              if (extraParams is Map<String, String>) {
                queryParams = extraParams;
                print('📱 모바일 Deep Link 파라미터: $queryParams');
              } else {
                // fallback: URL 파라미터도 확인
                queryParams = state.uri.queryParameters;
                print('📱 모바일 fallback 파라미터: $queryParams');
              }
            }

            return SocialLoginCallbackScreen(queryParams: queryParams);
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