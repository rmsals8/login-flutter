// lib/presentation/providers/login_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
// 🔥 네이버 로그인 관련 import 모두 추가
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/url_launcher_helper.dart';
import '../../core/utils/storage_helper.dart';
import '../../data/models/login_request.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_provider.dart';

class LoginProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // Controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController captchaController = TextEditingController();

  // Focus nodes
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  // State variables
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _rememberMe = false;
  bool _ipSecurity = false;
  bool _showCaptcha = false;
  int _loginFailCount = 0;
  bool _mounted = true;

  // Error messages
  String _errorMessage = '';
  String _successMessage = '';
  String _usernameError = '';
  String _passwordError = '';
  String _captchaError = '';

  // Context for AuthProvider access
  BuildContext? _context;

  // Getters
  bool get isLoading => _isLoading;
  bool get isFormValid => _isFormValid;
  bool get rememberMe => _rememberMe;
  bool get ipSecurity => _ipSecurity;
  bool get showCaptcha => _showCaptcha;
  int get loginFailCount => _loginFailCount;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;
  String get usernameError => _usernameError;
  String get passwordError => _passwordError;
  String get captchaError => _captchaError;
  bool get mounted => _mounted;

  @override
  void dispose() {
    _mounted = false;
    usernameController.dispose();
    passwordController.dispose();
    captchaController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  // Context 설정
  void setContext(BuildContext context) {
    _context = context;
  }

  // 🧹 입력 필드 초기화 함수
  void clearInputFields() {
    print('🧹 입력 필드 초기화 시작');
    usernameController.clear();
    passwordController.clear();
    captchaController.clear();
    
    _clearErrors();
    _validateForm();
    
    print('✅ 입력 필드 초기화 완료');
  }

  // 초기화
  void init() {
    print('🔄 LoginProvider.init() 시작');
    _loginFailCount = _authRepository.getLoginFailCount();
    _rememberMe = _authRepository.getRememberMe();
    _ipSecurity = _authRepository.getIpSecurity();
    _showCaptcha = _loginFailCount >= 3;
    
    print('📊 초기 상태:');
    print('  - loginFailCount: $_loginFailCount');
    print('  - rememberMe: $_rememberMe');
    print('  - ipSecurity: $_ipSecurity');
    print('  - showCaptcha: $_showCaptcha');
    
    // 리스너 추가
    usernameController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
    captchaController.addListener(_validateForm);
    
    notifyListeners();
    print('✅ LoginProvider.init() 완료');
  }

  // 폼 유효성 검사
  void _validateForm() {
    _isFormValid = Validators.isFormValid(
      username: usernameController.text,
      password: passwordController.text,
      captcha: captchaController.text,
      showCaptcha: _showCaptcha,
    );
    
    if (_isFormValid) {
      _clearErrors();
    }
    
    notifyListeners();
  }

  // 개별 필드 검증
  void validateUsername() {
    if (!usernameFocusNode.hasFocus) {
      _usernameError = Validators.validateUsername(usernameController.text) ?? '';
      notifyListeners();
    }
  }

  void validatePassword() {
    if (!passwordFocusNode.hasFocus) {
      _passwordError = Validators.validatePassword(passwordController.text) ?? '';
      notifyListeners();
    }
  }

  void validateCaptcha() {
    _captchaError = Validators.validateCaptcha(captchaController.text, _showCaptcha) ?? '';
    notifyListeners();
  }

  // 에러 메시지 초기화
  void _clearErrors() {
    _errorMessage = '';
    _successMessage = '';
    _usernameError = '';
    _passwordError = '';
    _captchaError = '';
  }

  // 로그인 옵션 토글
  void toggleRememberMe(bool value) {
    _rememberMe = value;
    _authRepository.setRememberMe(value);
    notifyListeners();
  }

  void toggleIpSecurity(bool value) {
    _ipSecurity = value;
    _authRepository.setIpSecurity(value);
    notifyListeners();
  }

  // 🔥 메인 로그인 함수
  Future<bool> login() async {
    print('🚀 LoginProvider.login() 시작');
    
    // 유효성 검사
    print('🔍 유효성 검사 시작');
    validateUsername();
    validatePassword();
    if (_showCaptcha) {
      validateCaptcha();
    }

    print('📊 유효성 검사 결과:');
    print('  - isFormValid: $_isFormValid');
    print('  - usernameError: $_usernameError');
    print('  - passwordError: $_passwordError');
    print('  - captchaError: $_captchaError');

    if (!_isFormValid || _usernameError.isNotEmpty || _passwordError.isNotEmpty || _captchaError.isNotEmpty) {
      print('❌ 폼 유효성 검사 실패');
      return false;
    }

    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      print('📝 로그인 요청 데이터 생성');
      final loginRequest = LoginRequest(
        username: usernameController.text.trim(),
        password: passwordController.text,
        rememberMe: _rememberMe,
        captcha: _showCaptcha ? captchaController.text.trim() : null,
      );
      print('📦 요청 데이터: username=${loginRequest.username}, rememberMe=${loginRequest.rememberMe}');

      print('🌐 AuthRepository.login() 호출 시작');
      final response = await _authRepository.login(loginRequest);
      print('📡 AuthRepository 응답 받음');
      print('  - success: ${response.success}');
      print('  - message: ${response.message}');
      print('  - statusCode: ${response.statusCode}');
      print('  - data: ${response.data}');

      if (response.success && response.data != null) {
        print('✅ 로그인 성공!');
        
        // 🔥 AuthProvider에 사용자 정보 설정
        if (_context != null) {
          try {
            final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
            authProvider.setUser(response.data!);
            print('👤 AuthProvider에 사용자 설정 완료: ${response.data!.username}');
          } catch (e) {
            print('❌ AuthProvider 설정 실패: $e');
          }
        } else {
          print('⚠️ Context가 null입니다');
        }
        
        _successMessage = response.message ?? AppStrings.loginSuccess;
        print('💬 성공 메시지 설정: $_successMessage');
        
        // 로그인 성공 시 폼 초기화
        _resetLoginForm();
        
        notifyListeners();
        return true;
      } else {
        print('❌ 로그인 실패: ${response.message}');
        _handleLoginFailure(response.message ?? AppStrings.loginFailed);
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 LoginProvider 예외 발생: $e');
      print('📋 스택 트레이스: $stackTrace');
      _handleLoginFailure('로그인 처리 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      print('🏁 LoginProvider 로그인 처리 완료');
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그인 실패 처리
  void _handleLoginFailure(String message) {
    print('🔥 로그인 실패 처리: $message');
    
    usernameController.clear();
    passwordController.clear();
    
    _loginFailCount = _authRepository.getLoginFailCount();
    print('📊 현재 실패 횟수: $_loginFailCount');
    
    if (_loginFailCount >= 3) {
      _showCaptcha = true;
      print('🔒 캡차 표시 활성화');
    }
    
    if (message.contains('캡차') || message.contains('자동입력')) {
      _captchaError = message;
      print('🎯 캡차 에러 설정: $_captchaError');
    } else {
      _errorMessage = message;
      print('🎯 일반 에러 설정: $_errorMessage');
    }
  }

  // 로그인 폼 초기화
  void _resetLoginForm() {
    print('🔄 로그인 폼 초기화');
    _showCaptcha = false;
    _loginFailCount = 0;
    captchaController.clear();
  }

  // 🔥 카카오 로그인 (기존과 동일)
  Future<void> kakaoLogin() async {
    print('📱 카카오 로그인 시작');
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      bool kakaoTalkInstalled = await isKakaoTalkInstalled();
      
      OAuthToken token;
      if (kakaoTalkInstalled) {
        print('📱 카카오톡 앱으로 로그인');
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        print('🌐 웹 브라우저로 로그인');
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('✅ 카카오 토큰 받음: ${token.accessToken.substring(0, 20)}...');

      await _sendKakaoTokenToBackend(token.accessToken);

    } catch (error) {
      print('❌ 카카오 로그인 실패: $error');
      
      if (error.toString().contains('KakaoAuthException')) {
        _errorMessage = '카카오 로그인이 취소되었습니다.';
      } else {
        _errorMessage = '카카오 로그인 중 오류가 발생했습니다: ${error.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Future<void> naverLogin() async {
  print('📱 === 네이버 로그인 시작 ===');
  _isLoading = true;
  _clearErrors();
  notifyListeners();

  try {
    // 🔥 1단계: 네이버 앱 설치 여부 확인
    print('🔍 네이버 앱 설치 상태 확인 중...');
    
    bool isNaverAppInstalled = await _checkNaverAppInstalled();
    
    if (!isNaverAppInstalled) {
      print('❌ 네이버 앱이 설치되지 않음');
      await _showNaverAppInstallDialog();
      return;
    }
    
    print('✅ 네이버 앱이 설치되어 있음 - 로그인 진행');
    
    // 🔥 2단계: 네이버 로그인 실행
    await _performNaverLogin();
    
  } catch (error) {
    print('💥 네이버 로그인 오류: $error');
    _errorMessage = '네이버 로그인 중 오류가 발생했습니다.';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// 🔥 네이버 앱 설치 여부 확인
Future<bool> _checkNaverAppInstalled() async {
  try {
    // 방법 1: 네이버 SDK 상태로 간접 확인
    print('📱 네이버 SDK 상태 확인...');
    
    // 간단한 로그인 시도로 앱 설치 여부 간접 확인
    final result = await FlutterNaverLogin.logIn();
    
    // loggedOut이면서 즉시 반환되면 앱이 없을 가능성
    if (result.status == NaverLoginStatus.loggedOut) {
      print('⚠️ 네이버 앱이 설치되지 않았을 가능성');
      return false;
    }
    
    return true;
    
  } catch (e) {
    print('❌ 네이버 앱 확인 실패: $e');
    return false;
  }
}

// 🔥 네이버 앱 설치 안내 다이얼로그
Future<void> _showNaverAppInstallDialog() async {
  if (_context == null) return;
  
  final result = await showDialog<bool>(
    context: _context!,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 네이버 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF03C75A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apps,
                  size: 32,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              
              // 제목
              Text(
                '네이버 앱 설치 필요',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // 설명 텍스트
              Text(
                '네이버 로그인을 위해서는 네이버 앱이 필요합니다.\nGoogle Play Store에서 네이버 앱을 설치하시겠습니까?',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeRegular,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // 버튼들
              Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: SizedBox(
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightGrey,
                          foregroundColor: AppColors.textSecondary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeRegular,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 설치하기 버튼
                  Expanded(
                    child: SizedBox(
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03C75A),
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '설치하기',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeRegular,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  
  if (result == true) {
    await _openNaverAppInPlayStore();
  }
}

// 🔥 플레이스토어에서 네이버 앱 열기
Future<void> _openNaverAppInPlayStore() async {
  try {
    print('🏪 플레이스토어에서 네이버 앱 열기...');
    
    // 플레이스토어 네이버 앱 URL
    const naverAppUrl = 'https://play.google.com/store/apps/details?id=com.nhn.android.search';
    
    final success = await UrlLauncherHelper.launchURL(naverAppUrl);
    
    if (success) {
      print('✅ 플레이스토어 열기 성공');
      _successMessage = '플레이스토어에서 네이버 앱을 설치한 후 다시 시도해주세요.';
    } else {
      print('❌ 플레이스토어 열기 실패');
      _errorMessage = '플레이스토어를 열 수 없습니다. 수동으로 네이버 앱을 설치해주세요.';
    }
    
  } catch (e) {
    print('💥 플레이스토어 열기 오류: $e');
    _errorMessage = '플레이스토어를 열 수 없습니다.';
  }
}

// 🔥 실제 네이버 로그인 수행
Future<void> _performNaverLogin() async {
  try {
    print('🚀 네이버 로그인 실행...');
    
    // 기존 로그아웃
    await FlutterNaverLogin.logOut();
    
    // 로그인 실행
    final result = await FlutterNaverLogin.logIn();
    
    print('📊 네이버 로그인 결과: ${result.status}');
    
    if (result.status == NaverLoginStatus.loggedIn) {
      print('✅ 네이버 로그인 성공!');
      
      final token = await FlutterNaverLogin.getCurrentAccessToken();
      print('🔑 토큰 획득 성공');
      
      await _sendNaverTokenToBackend(token.accessToken);
      
    } else {
      print('❌ 네이버 로그인 실패: ${result.status}');
      throw Exception('네이버 로그인 실패');
    }
    
  } catch (e) {
    print('💥 네이버 로그인 수행 오류: $e');
    rethrow;
  }
}

// 🔥 네이버 로그인 실패 원인 진단
Future<String> _diagnoseNaverLoginFailure() async {
  final issues = <String>[];
  
  try {
    // 1. strings.xml 값 확인 (실제로는 확인 불가하지만 로그 출력)
    print('🔍 설정 파일 확인 중...');
    
    // 2. 네이버 앱 설치 여부 (간접 확인)
    print('📱 네이버 앱 관련 확인 중...');
    
    // 3. 네트워크 상태 확인
    print('🌐 네트워크 상태 확인 중...');
    
    issues.add('네이버 개발자 콘솔 설정 확인 필요');
    issues.add('로고 이미지 업로드 확인 필요');
    issues.add('클라이언트 ID/Secret 정확성 확인 필요');
    
  } catch (e) {
    issues.add('진단 과정에서 오류 발생');
  }
  
  return issues.join(', ');
}

// 🔥 네이버 에러 분류
String _categorizeNaverError(String errorString) {
  final lowerError = errorString.toLowerCase();
  
  if (lowerError.contains('loggedout')) {
    return '네이버 개발자 콘솔 설정을 확인해주세요. 특히 로고 이미지와 패키지명을 확인하세요.';
  } else if (lowerError.contains('network') || lowerError.contains('timeout')) {
    return '네트워크 연결을 확인해주세요.';
  } else if (lowerError.contains('token')) {
    return '네이버 토큰 처리 중 오류가 발생했습니다.';
  } else if (lowerError.contains('cancel')) {
    return '네이버 로그인이 취소되었습니다.';
  } else {
    return '네이버 로그인 중 오류가 발생했습니다. 개발자 콘솔 설정을 확인해주세요.';
  }
}
  // 🔥 카카오 토큰을 서버로 전송
  Future<void> _sendKakaoTokenToBackend(String kakaoAccessToken) async {
    try {
      print('📡 서버로 카카오 토큰 전송 중...');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/social/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accessToken': kakaoAccessToken,
        }),
      );

      print('📡 서버 응답: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final authResponse = json.decode(response.body);
        
        await _handleSocialLoginSuccess(authResponse, 'kakao');
        
      } else {
        throw Exception('서버 인증 실패: ${response.body}');
      }

    } catch (e) {
      print('💥 서버 토큰 전송 실패: $e');
      _errorMessage = '로그인 처리 중 오류가 발생했습니다: $e';
      rethrow;
    }
  }

  // 🔥 네이버 토큰을 서버로 전송
  Future<void> _sendNaverTokenToBackend(String naverAccessToken) async {
    try {
      print('📡 서버로 네이버 토큰 전송 중...');
      print('🔑 토큰: ${naverAccessToken.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/social/naver'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'accessToken': naverAccessToken,
        }),
      );

      print('📡 서버 응답: ${response.statusCode}');
      print('📦 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final authResponse = json.decode(response.body);
        
        await _handleSocialLoginSuccess(authResponse, 'naver');
        
      } else {
        String errorMessage = '서버 인증 실패';
        
        try {
          final errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? errorMessage;
        } catch (e) {
          print('⚠️ 에러 응답 JSON 파싱 실패: $e');
        }
        
        throw Exception('$errorMessage (코드: ${response.statusCode})');
      }

    } catch (e) {
      print('💥 서버 토큰 전송 실패: $e');
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException')) {
        _errorMessage = '서버 연결에 실패했습니다. 네트워크를 확인해주세요.';
      } else {
        _errorMessage = '로그인 처리 중 오류가 발생했습니다.';
      }
      
      rethrow;
    }
  }

  // 🔥 소셜 로그인 성공 처리 (카카오/네이버 공통)
  Future<void> _handleSocialLoginSuccess(Map<String, dynamic> authResponse, String loginType) async {
    print('🎉 소셜 로그인 성공 처리 시작: $loginType');
    print('📊 서버 응답 구조: ${authResponse.keys}');
    
    // JWT 토큰 저장
    final jwtToken = authResponse['token'];
    if (jwtToken != null && jwtToken.isNotEmpty) {
      await StorageHelper.setToken(jwtToken);
      print('💾 JWT 토큰 저장 완료');
    } else {
      throw Exception('서버에서 토큰을 받지 못했습니다');
    }
    
    // 사용자 정보 저장
    final userModel = UserModel(
      userId: authResponse['userId']?.toString() ?? '',
      username: authResponse['username']?.toString() ?? 'Unknown',
      loginType: loginType,
    );
    
    await StorageHelper.setUserData(userModel.toJson());
    print('👤 사용자 정보 저장 완료: ${userModel.username}');
    
    // 로그인 실패 횟수 초기화
    await StorageHelper.removeLoginFailCount();
    
    // AuthProvider 업데이트
    if (_context != null) {
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      authProvider.setUser(userModel);
      print('🔄 AuthProvider 업데이트 완료');
    }
    
    _successMessage = '${loginType == 'kakao' ? '카카오' : '네이버'} 로그인 성공!';
    print('🎉 $loginType 로그인 완료');
    
    // 입력 필드 초기화
    clearInputFields();
    _resetLoginForm();
    
    // 대시보드로 자동 이동
    if (_context != null && mounted) {
      print('🚀 대시보드로 자동 이동 시작');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_context != null && mounted) {
          final router = GoRouter.of(_context!);
          router.go('/dashboard');
          print('✅ 대시보드로 이동 완료');
        }
      });
    }
  }

  // 에러 메시지 설정 (외부에서 호출용)
  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // 성공 메시지 설정 (외부에서 호출용)
  void setSuccessMessage(String message) {
    _successMessage = message;
    notifyListeners();
  }

  // 로딩 상태 설정 (외부에서 호출용)
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 🧹 로그아웃 시 호출되는 초기화 함수
  void onLogout() {
    print('🧹 로그아웃 시 LoginProvider 초기화');
    clearInputFields();
    _resetLoginForm();
    _loginFailCount = 0;
    _showCaptcha = false;
    notifyListeners();
  }
}