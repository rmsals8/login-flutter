// lib/presentation/providers/login_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

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

// 🔥 네이버 로그인 디버그 강화 버전
Future<void> naverLogin() async {
  print('📱 네이버 Native SDK 로그인 시작');
  _isLoading = true;
  _clearErrors();
  notifyListeners();

  try {
    // 🔥 네이버 SDK 상태 확인
    print('🔍 네이버 SDK 상태 확인 중...');
    
    // 1. 네이버 로그인 실행
    print('🚀 네이버 로그인 실행...');
    final NaverLoginResult result = await FlutterNaverLogin.logIn();
    
    print('📊 네이버 로그인 상세 결과:');
    print('  - status: ${result.status}');
    print('  - account: ${result.account}');
    
    if (result.status == NaverLoginStatus.loggedIn) {
      print('✅ 네이버 로그인 성공! 토큰 가져오는 중...');
      
      // 2. 토큰 가져오기
      try {
        final NaverToken token = await FlutterNaverLogin.getCurrentAccessToken();
        
        print('📊 네이버 토큰 정보:');
        print('  - accessToken: ${token.accessToken.substring(0, 20)}...');
        print('  - refreshToken: ${token.refreshToken?.substring(0, 20) ?? "없음"}...');
        print('  - tokenType: ${token.tokenType}');
        print('  - expiresAt: ${token.expiresAt}');
        print('  - isValid: ${token.isValid()}');
        
        if (!token.isValid()) {
          throw Exception('네이버 토큰이 유효하지 않습니다');
        }
        
        // 3. 사용자 정보 가져오기 (선택적)
        try {
          final NaverAccountResult account = await FlutterNaverLogin.getCurrentAccount();
          print('📊 네이버 사용자 정보:');
          print('  - id: ${account.id}');
          print('  - name: ${account.name}');
          print('  - email: ${account.email}');
          print('  - nickname: ${account.nickname}');
        } catch (accountError) {
          print('⚠️ 사용자 정보 가져오기 실패: $accountError');
          // 사용자 정보 실패해도 토큰이 있으면 계속 진행
        }
        
        // 4. 서버로 토큰 전송
        print('📡 서버로 네이버 토큰 전송 시작...');
        await _sendNaverTokenToBackend(token.accessToken);
        
      } catch (tokenError) {
        print('❌ 네이버 토큰 처리 실패: $tokenError');
        throw Exception('네이버 토큰 처리 실패: $tokenError');
      }
      
    } else if (result.status == NaverLoginStatus.loggedOut) {
      print('❌ 네이버 로그인이 loggedOut 상태로 반환됨');
      print('🔍 가능한 원인들:');
      print('  1. 네이버 앱이 설치되지 않음');
      print('  2. strings.xml 설정 오류');
      print('  3. AndroidManifest.xml 설정 오류'); 
      print('  4. 네이버 개발자 콘솔 설정 오류');
      print('  5. 사용자가 로그인 취소');
      
      throw Exception('네이버 로그인이 취소되었거나 설정에 문제가 있습니다');
      
    } else if (result.status == NaverLoginStatus.error) {
      print('❌ 네이버 로그인 에러 상태');
      throw Exception('네이버 로그인 에러가 발생했습니다');
      
    } else {
      print('❌ 알 수 없는 네이버 로그인 상태: ${result.status}');
      throw Exception('알 수 없는 네이버 로그인 상태: ${result.status}');
    }

  } catch (error) {
    print('💥 네이버 로그인 전체 예외: $error');
    print('📋 예외 타입: ${error.runtimeType}');
    
    String errorString = error.toString().toLowerCase();
    
    if (errorString.contains('취소') || 
        errorString.contains('cancel') || 
        errorString.contains('사용자가') ||
        errorString.contains('loggedout')) {
      _errorMessage = '네이버 로그인이 취소되었습니다.';
    } else if (errorString.contains('설정') || 
               errorString.contains('config') ||
               errorString.contains('misconfigured')) {
      _errorMessage = '네이버 로그인 설정을 확인해주세요.';
    } else if (errorString.contains('네트워크') || 
               errorString.contains('network') || 
               errorString.contains('연결')) {
      _errorMessage = '네트워크 연결을 확인해주세요.';
    } else {
      _errorMessage = '네이버 로그인 중 오류가 발생했습니다.';
    }
    
    print('🎯 설정된 에러 메시지: $_errorMessage');
  } finally {
    _isLoading = false;
    notifyListeners();
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