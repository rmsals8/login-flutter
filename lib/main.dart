// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🔥 .env 파일 읽기용
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 🔥 카카오 SDK
import 'dart:io';
import 'core/utils/storage_helper.dart';
import 'data/services/api_service.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/login_provider.dart';
import 'providers/signup_provider.dart'; // 🔥 SignupProvider 추가
import 'providers/captcha_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/signup_screen.dart'; // 🔥 SignupScreen 추가
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/social_login_callback_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 .env 파일 로드
  await dotenv.load(fileName: ".env");
  print('✅ .env 파일 로드 완료');

  // 🔥 .env에서 카카오 키 읽기
  final kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  final kakaoJavaScriptAppKey = dotenv.env['KAKAO_JAVASCRIPT_APP_KEY'] ?? '';
  final baseUrl = dotenv.env['BASE_URL'] ?? '';

  // 🔥 환경변수 검증
  if (kakaoNativeAppKey.isEmpty) {
    throw Exception('KAKAO_NATIVE_APP_KEY가 .env 파일에 설정되지 않았습니다!');
  }
  if (kakaoJavaScriptAppKey.isEmpty) {
    throw Exception('KAKAO_JAVASCRIPT_APP_KEY가 .env 파일에 설정되지 않았습니다!');
  }
  if (baseUrl.isEmpty) {
    throw Exception('BASE_URL이 .env 파일에 설정되지 않았습니다!');
  }

  print('🔑 .env에서 로드된 값들:');
  print('  - BASE_URL: $baseUrl');
  print('  - KAKAO_NATIVE_APP_KEY: ${kakaoNativeAppKey.substring(0, 10)}...');
  print('  - KAKAO_JAVASCRIPT_APP_KEY: ${kakaoJavaScriptAppKey.substring(0, 10)}...');

  // 🔥 카카오 SDK 초기화 (.env 값 사용)
  KakaoSdk.init(
    nativeAppKey: kakaoNativeAppKey,
    javaScriptAppKey: kakaoJavaScriptAppKey,
  );
  print('✅ 카카오 SDK 초기화 완료 (.env 파일 사용)');

  // 🔥 네이버 SDK는 자동 초기화됨 (strings.xml과 AndroidManifest.xml 설정으로)
  print('✅ 네이버 SDK는 네이티브 설정으로 자동 초기화됨');

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
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}

// 필수 서비스 초기화
Future<void> _initializeServices() async {
  try {
    print('🔄 필수 서비스 초기화 시작');

    // 1. .env에서 BASE_URL 확인
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    print('🔍 .env에서 읽은 BASE_URL: "$baseUrl"');

    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL이 .env 파일에 설정되지 않았습니다!');
    }
    print('✅ API URL 검증 완료: $baseUrl');

    // 2. StorageHelper 초기화
    print('🔄 StorageHelper 초기화 시작');
    await StorageHelper.init();
    print('✅ StorageHelper 초기화 완료');

    // 3. API 서비스 초기화 (더 안전하게)
    print('🔄 ApiService 초기화 시작');
    try {
      final apiService = ApiService();
      print('✅ ApiService 싱글톤 인스턴스 획득');

      apiService.init();
      print('✅ ApiService.init() 호출 완료');

      // 4. 초기화 확인 테스트
      print('🧪 ApiService 초기화 확인 테스트');
      final testDio = apiService.dio; // getter 호출로 초기화 확인
      print('✅ ApiService Dio 인스턴스 확인 완료');

    } catch (e) {
      print('❌ ApiService 초기화 실패: $e');
      print('📋 에러 타입: ${e.runtimeType}');
      rethrow;
    }

    print('✅ 모든 필수 서비스 초기화 완료');

  } catch (e) {
    print('❌ 서비스 초기화 실패: $e');
    print('📋 실패 지점에서의 스택 트레이스:');
    print(e.toString());
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLinks? _appLinks;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  // 🔥 Deep Link 초기화
  void _initDeepLinks() {
    if (kIsWeb) {
      print('🌐 웹 환경: Deep Link 초기화 스킵');
      return;
    }

    print('📱 모바일 환경: Deep Link 초기화 시작');
    _appLinks = AppLinks();

    // 초기 Deep Link 처리
    _appLinks!.getInitialAppLink().then((Uri? uri) {
      if (uri != null) {
        print('🔗 초기 Deep Link: $uri');
        _handleDeepLink(uri);
      }
    }).catchError((error) {
      print('❌ 초기 Deep Link 오류: $error');
    });

    // 실시간 Deep Link 처리
    _appLinks!.allUriLinkStream.listen((Uri uri) {
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
        ChangeNotifierProvider(create: (_) => SignupProvider()), // 🔥 SignupProvider 추가
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

  // 🔥 라우터 생성
  GoRouter _createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: true,
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

        // 🔥 회원가입 화면 추가
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) {
            print('🔄 Signup 화면 라우트 호출');
            return const SignupScreen();
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

            // 웹과 모바일 파라미터 처리
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
            print('✅ 스플래시/콜백 화면: 접근 허용');
            return null;
          }

          // 🔥 회원가입 화면은 로그인하지 않은 상태에서만 접근 가능
          if (location == '/signup') {
            if (isLoggedIn) {
              print('🔄 이미 로그인됨: 대시보드로 리다이렉트');
              return '/dashboard';
            } else {
              print('✅ 회원가입 화면: 접근 허용');
              return null;
            }
          }

          // 로그인이 필요한 화면들
          if (location == '/dashboard') {
            if (!isLoggedIn) {
              print('🔄 인증 필요: 로그인으로 리다이렉트');
              return '/login';
            } else {
              print('✅ 대시보드: 접근 허용');
              return null;
            }
          }

          // 로그인 화면
          if (location == '/login') {
            if (isLoggedIn) {
              print('🔄 이미 로그인됨: 대시보드로 리다이렉트');
              return '/dashboard';
            } else {
              print('✅ 로그인 화면: 접근 허용');
              return null;
            }
          }

          print('✅ 기본: 접근 허용');
          return null;

        } catch (e) {
          print('❌ 라우터 리다이렉트 오류: $e');
          return '/login'; // 오류 발생 시 로그인으로
        }
      },
      errorBuilder: (context, state) {
        print('❌ 라우터 오류: ${state.error}');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: AppColors.error),
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
                  state.error.toString(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('로그인으로 돌아가기'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}