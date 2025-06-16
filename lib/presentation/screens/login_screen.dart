// lib/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_helper.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/login_provider.dart';
import '../../providers/captcha_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/error_message.dart';
import '../widgets/common/success_message.dart';
import '../widgets/common/responsive_container.dart';
import '../widgets/common/divider_with_text.dart';
import '../widgets/login/floating_label_input.dart';
import '../widgets/login/login_options.dart';
import '../widgets/login/social_login_buttons.dart';
import '../widgets/login/captcha_widget.dart';
import '../widgets/login/top_error_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    
    // Provider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginProvider = context.read<LoginProvider>();
      final captchaProvider = context.read<CaptchaProvider>();
      
      // 🔥 LoginProvider에 context 전달
      loginProvider.setContext(context);
      
      loginProvider.init();
      
      // 🔥 URL 파라미터에서 소셜 로그인 에러 확인
      _checkUrlParams(loginProvider);
      
      // 캡차가 필요한 경우 로드
      if (loginProvider.showCaptcha) {
        captchaProvider.refreshCaptcha();
      }
    });
  }

  void _checkUrlParams(LoginProvider loginProvider) {
    // URL에서 에러 파라미터 확인
    final uri = Uri.parse(html.window.location.href);
    final error = uri.queryParameters['error'];
    
    if (error != null) {
      print('🔍 URL 에러 파라미터 발견: $error');
      
      // 에러 메시지 설정
      String errorMessage;
      switch (error) {
        case 'kakao_login_failed':
          errorMessage = '카카오 로그인 처리 중 오류가 발생했습니다. 다시 시도해주세요.';
          break;
        case 'naver_login_failed':
          errorMessage = '네이버 로그인 처리 중 오류가 발생했습니다. 다시 시도해주세요.';
          break;
        case 'invalid_state':
          errorMessage = '보안 오류가 발생했습니다. 다시 시도해주세요.';
          break;
        default:
          errorMessage = Uri.decodeComponent(error);
      }
      
      loginProvider.setErrorMessage(errorMessage);
      
      // URL에서 에러 파라미터 제거
      final cleanUrl = html.window.location.pathname;
      html.window.history.replaceState({}, '', cleanUrl);
    }
  }

  Future<void> _handleLogin() async {
    print('🔥🔥🔥 _handleLogin 함수 호출됨!');
    
    final loginProvider = context.read<LoginProvider>();
    final authProvider = context.read<AuthProvider>();
    
    print('📝 입력값 확인:');
    print('  - Username: ${loginProvider.usernameController.text}');
    print('  - Password: ${loginProvider.passwordController.text.isNotEmpty ? "입력됨" : "비어있음"}');
    print('  - FormValid: ${loginProvider.isFormValid}');
    print('  - IsLoading: ${loginProvider.isLoading}');
    
    // 🔥 로그인 시도
    final success = await loginProvider.login();
    print('✅ 로그인 결과: $success');
    
    if (success) {
      print('🎉 로그인 성공! 대시보드로 이동 준비');
      
      // 🔥 입력 필드 초기화 (로그인 성공 시)
      loginProvider.clearInputFields();
      print('🧹 입력 필드 초기화 완료');
      
      // 🔥 AuthProvider 강제 업데이트
      print('🔄 AuthProvider 강제 업데이트 시작');
      await authProvider.init();
      
      // 🔥 사용자 정보 확인
      final currentUser = authProvider.currentUser;
      final isAuthenticated = authProvider.isAuthenticated;
      
      print('👤 AuthProvider 사용자 확인: ${currentUser?.username}');
      print('🔐 인증 상태: $isAuthenticated');
      print('💬 성공 메시지: "${loginProvider.successMessage}"');
      
      // 🚀 조건 확인 후 대시보드로 이동 (조건 완화!)
      if (isAuthenticated && currentUser != null) {
        print('✅ 이동 조건 만족: 인증됨 + 사용자정보 있음');
        
        if (mounted) {
          print('🚀 대시보드로 이동 시작!');
          context.go('/dashboard');
          print('✅ 대시보드 이동 명령 완료');
          return; // 중요: 여기서 함수 종료
        } else {
          print('❌ Widget이 mounted되지 않음');
        }
      } else {
        print('❌ 이동 조건 불만족:');
        print('  - isAuthenticated: $isAuthenticated');
        print('  - currentUser: $currentUser');
        
        // 🔧 강제로 사용자 설정 시도
        if (currentUser == null) {
          print('🔧 강제 사용자 설정 시도');
          final userData = StorageHelper.getUserData();
          if (userData != null) {
            final userModel = UserModel.fromJson(userData);
            authProvider.setUser(userModel);
            print('👤 강제 사용자 설정 완료: ${userModel.username}');
            
            // 다시 이동 시도
            if (mounted) {
              print('🚀 강제 설정 후 대시보드로 이동!');
              context.go('/dashboard');
              print('✅ 대시보드 이동 완료');
              return;
            }
          }
        }
      }
    } else {
      print('❌ 로그인 실패');
      print('💬 에러 메시지: ${loginProvider.errorMessage}');
      print('💬 사용자명 에러: ${loginProvider.usernameError}');
      print('💬 비밀번호 에러: ${loginProvider.passwordError}');
      print('💬 캡차 에러: ${loginProvider.captchaError}');
    }
    
    print('🏁 _handleLogin 함수 완료');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              _buildHeader(),
              
              // 로그인 폼
              ResponsiveContainer(
                child: _buildLoginForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.padding),
      color: AppColors.white,
      child: Column(
        children: [
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Text(
          //   '현재 API URL: ${ApiConstants.baseUrl}',
          //   style: TextStyle(
          //     fontSize: AppDimensions.fontSizeMedium,
          //     color: AppColors.textSecondary,
          //   ),
          //   textAlign: TextAlign.center,
          // ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 제목
          Text(
            AppStrings.loginTitle,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // 상단 오류 메시지 (3회 이상 실패 시)
          Consumer<LoginProvider>(
            builder: (context, loginProvider, child) {
              return TopErrorMessage(
                message: AppStrings.captchaError,
                show: loginProvider.showCaptcha && loginProvider.loginFailCount >= 3,
              );
            },
          ),
          
          // 입력 필드들
          _buildInputFields(),
          const SizedBox(height: 16),
          
          // 로그인 옵션
          _buildLoginOptions(),
          const SizedBox(height: 16),
          
          // 캡차 (필요한 경우에만)
          _buildCaptcha(),
          
          // 로그인 버튼
          _buildLoginButton(),
          
          // 에러/성공 메시지
          _buildMessages(),
          _buildSignupButton(),
          // 소셜 로그인
          _buildSocialLogin(),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Consumer<LoginProvider>(
      builder: (context, loginProvider, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            children: [
              // 아이디 입력
              FloatingLabelInput(
                label: AppStrings.username,
                controller: loginProvider.usernameController,
                focusNode: loginProvider.usernameFocusNode,
                onChanged: (value) => loginProvider.validateUsername(),
                keyboardType: TextInputType.text,
                isFirst: true,
                isLast: false,
              ),
              // 구분선
              Container(
                height: 1,
                color: AppColors.inputBorder,
              ),
              // 비밀번호 입력
              FloatingLabelInput(
                label: AppStrings.password,
                controller: loginProvider.passwordController,
                focusNode: loginProvider.passwordFocusNode,
                obscureText: true,
                onChanged: (value) => loginProvider.validatePassword(),
                keyboardType: TextInputType.visiblePassword,
                isFirst: false,
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginOptions() {
    return Consumer<LoginProvider>(
      builder: (context, loginProvider, child) {
        return LoginOptions(
          rememberMe: loginProvider.rememberMe,
          ipSecurity: loginProvider.ipSecurity,
          onRememberMeChanged: loginProvider.toggleRememberMe,
          onIpSecurityChanged: loginProvider.toggleIpSecurity,
        );
      },
    );
  }

  Widget _buildCaptcha() {
    return Consumer2<LoginProvider, CaptchaProvider>(
      builder: (context, loginProvider, captchaProvider, child) {
        if (!loginProvider.showCaptcha) {
          return const SizedBox.shrink();
        }
        
        return CaptchaWidget(
          captchaImageUrl: captchaProvider.captchaImageUrl,
          captchaController: loginProvider.captchaController,
          onRefresh: captchaProvider.refreshCaptcha,
          onChanged: (value) => loginProvider.validateCaptcha(),
          isLoading: captchaProvider.isLoading,
          errorMessage: captchaProvider.errorMessage,
        );
      },
    );
  }

Widget _buildLoginButton() {
  return Consumer<LoginProvider>(
    builder: (context, loginProvider, child) {
      // 🔥 다른 로그인이 진행 중인지 확인
      final isOtherLoginInProgress = loginProvider.isKakaoLoading || loginProvider.isNaverLoading;
      
      print('🎯 로그인 버튼 빌드:');
      print('  - isFormValid: ${loginProvider.isFormValid}');
      print('  - isGeneralLoading: ${loginProvider.isGeneralLoading}');
      print('  - isOtherLoginInProgress: $isOtherLoginInProgress');
      
      return CustomButton(
        text: loginProvider.isGeneralLoading ? AppStrings.loginLoading : AppStrings.login,
        onPressed: () {
          print('🔴 로그인 버튼 클릭됨!');
          _handleLogin();
        },
        // 🔥 일반 로그인 로딩 상태만 사용
        isLoading: loginProvider.isGeneralLoading,
        // 🔥 폼이 유효하고, 일반 로그인이 로딩 중이 아니고, 다른 로그인도 진행 중이 아닐 때만 활성화
        isActive: loginProvider.isFormValid && 
                 !loginProvider.isGeneralLoading && 
                 !isOtherLoginInProgress,
      );
    },
  );
}
  Widget _buildMessages() {
    return Consumer<LoginProvider>(
      builder: (context, loginProvider, child) {
        return Column(
          children: [
            // 개별 필드 에러
            if (loginProvider.usernameError.isNotEmpty)
              ErrorMessage(message: loginProvider.usernameError)
            else if (loginProvider.passwordError.isNotEmpty)
              ErrorMessage(message: loginProvider.passwordError)
            else if (loginProvider.captchaError.isNotEmpty)
              ErrorMessage(message: loginProvider.captchaError)
            else if (loginProvider.errorMessage.isNotEmpty)
              ErrorMessage(message: loginProvider.errorMessage),
              
            // 성공 메시지
            if (loginProvider.successMessage.isNotEmpty)
              SuccessMessage(message: loginProvider.successMessage),
          ],
        );
      },
    );
  }
  Widget _buildSignupButton() {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: OutlinedButton(
        onPressed: () {
          // 회원가입 페이지로 이동
          context.go('/signup');
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '회원가입',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
Widget _buildSocialLogin() {
  return Consumer<LoginProvider>(
    builder: (context, loginProvider, child) {
      return Column(
        children: [
          const SizedBox(height: 32),
          const DividerWithText(text: AppStrings.or),
          const SizedBox(height: 24),
          // 🔥 모든 로딩 상태를 전달
          SocialLoginButtons(
            onKakaoLogin: loginProvider.kakaoLogin,
            onNaverLogin: loginProvider.naverLogin,
            // 🔥 각각의 로딩 상태를 분리해서 전달
            isKakaoLoading: loginProvider.isKakaoLoading,
            isNaverLoading: loginProvider.isNaverLoading,
            isGeneralLoading: loginProvider.isGeneralLoading,
          ),
        ],
      );
    },
  );
}
}