// lib/presentation/providers/login_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:login/providers/captcha_provider.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

import 'package:flutter_naver_login/interface/types/naver_login_status.dart';


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

// lib/providers/login_provider.dart 파일에서 수정할 부분들

class LoginProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // Controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController captchaController = TextEditingController();

  // Focus nodes
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  // 🔥 로딩 상태를 분리해서 관리하기
  bool _isGeneralLoading = false;    // 일반 로그인 로딩
  bool _isKakaoLoading = false;      // 카카오 로그인 로딩
  bool _isNaverLoading = false;      // 네이버 로그인 로딩
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

  // 🔥 각각의 로딩 상태를 확인하는 getter들
  bool get isGeneralLoading => _isGeneralLoading;
  bool get isKakaoLoading => _isKakaoLoading;
  bool get isNaverLoading => _isNaverLoading;
  bool get isAnyLoading => _isGeneralLoading || _isKakaoLoading || _isNaverLoading;
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

  // 🔥 기존의 isLoading getter는 호환성을 위해 남겨두되 isAnyLoading으로 변경
  bool get isLoading => isAnyLoading;

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

  // 🔥 캡차가 필요하면 즉시 로드 시작
  if (_showCaptcha && _context != null) {
    print('🚀 캡차가 필요함 - 즉시 로드 시작');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final captchaProvider = Provider.of<CaptchaProvider>(_context!, listen: false);
      captchaProvider.refreshCaptcha();
    });
  }

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

  Future<bool> login() async {
    print('🚀 LoginProvider.login() 시작');

    // 🔥 다른 로그인이 진행 중인지 확인
    if (_isKakaoLoading || _isNaverLoading) {
      print('⚠️ 다른 로그인이 진행 중입니다. 일반 로그인을 건너뜁니다.');
      return false;
    }

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

    // 🔥 일반 로그인 로딩 상태만 true로 설정
    _isGeneralLoading = true;
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
      // 🔥 일반 로그인 로딩 상태만 false로 설정
      _isGeneralLoading = false;
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

// 🔥 카카오 로그인 (빠른 버전 - 최적화됨)
  Future<void> kakaoLogin() async {
    print('📱 카카오 로그인 시작 - 빠른 모드');

    // 🔥 다른 로그인이 진행 중인지 확인
    if (_isGeneralLoading || _isNaverLoading) {
      print('⚠️ 다른 로그인이 진행 중입니다. 카카오 로그인을 건너뜁니다.');
      _errorMessage = '다른 로그인이 진행 중입니다. 잠시 후 다시 시도해주세요.';
      notifyListeners();
      return;
    }

    // 🔥 카카오 로그인 로딩 상태만 true로 설정
    _isKakaoLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      print('🧹 카카오 토큰 빠른 삭제');

      // 🔥 빠른 토큰 삭제 (안전한 방법)
      try {
        // 로그아웃 시도 (에러 무시)
        try {
          await UserApi.instance.logout();
          print('✅ 카카오 로그아웃 완료');
        } catch (e) {
          print('ℹ️ 로그아웃 에러 (무시): $e');
        }

        // 토큰 삭제 시도 (에러 무시)
        try {
          await TokenManagerProvider.instance.manager.clear();
          print('✅ 카카오 토큰 삭제 완료');
        } catch (e) {
          print('ℹ️ 토큰 삭제 에러 (무시): $e');
        }

        print('✅ 카카오 데이터 정리 완료');
      } catch (e) {
        print('ℹ️ 카카오 데이터 삭제 과정: $e');
      }

      print('🚀 강제 재인증 로그인 시작');

      // 🔥 즉시 강제 재인증 로그인 (대기시간 없음)
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount(
        prompts: [Prompt.login], // 강제 재인증
      );

      print('✅ 카카오 토큰 받음: ${token.accessToken.substring(0, 20)}...');

      // 🔥 서버로 토큰 전송
      await _sendKakaoTokenToBackend(token.accessToken);

      print('🎉 카카오 로그인 완료!');

    } catch (error) {
      print('❌ 카카오 로그인 실패: $error');

      String errorString = error.toString().toLowerCase();

      if (errorString.contains('canceled') || errorString.contains('취소')) {
        _errorMessage = '카카오 로그인이 취소되었습니다.';
      } else if (errorString.contains('kakaoauthexception')) {
        _errorMessage = '카카오 로그인 중 문제가 발생했습니다. 다시 시도해주세요.';
      } else {
        _errorMessage = '카카오 로그인 중 오류가 발생했습니다.';
      }

      print('🎯 설정된 에러 메시지: $_errorMessage');
    } finally {
      // 🔥 카카오 로그인 로딩 상태만 false로 설정
      _isKakaoLoading = false;
      notifyListeners();
    }
  }


Future<void> naverLogin() async {
    print('📱 네이버 로그인 시작 - 카카오 방식과 동일');

    // 🔥 다른 로그인이 진행 중인지 확인
    if (_isGeneralLoading || _isKakaoLoading) {
      print('⚠️ 다른 로그인이 진행 중입니다. 네이버 로그인을 건너뜁니다.');
      _errorMessage = '다른 로그인이 진행 중입니다. 잠시 후 다시 시도해주세요.';
      notifyListeners();
      return;
    }

    // 🔥 네이버 로그인 로딩 상태만 true로 설정
    _isNaverLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      print('🧹 네이버 토큰 빠른 삭제');

      // 🔥 빠른 토큰 삭제 (카카오와 동일한 방식)
      try {
        // 로그아웃 시도 (에러 무시)
        try {
          await FlutterNaverLogin.logOut();
          print('✅ 네이버 로그아웃 완료');
        } catch (e) {
          print('ℹ️ 로그아웃 에러 (무시): $e');
        }

        // 토큰 삭제 시도 (에러 무시)
        try {
          await FlutterNaverLogin.logOutAndDeleteToken();
          print('✅ 네이버 토큰 삭제 완료');
        } catch (e) {
          print('ℹ️ 토큰 삭제 에러 (무시): $e');
        }

        print('✅ 네이버 데이터 정리 완료');
      } catch (e) {
        print('ℹ️ 네이버 데이터 삭제 과정: $e');
      }

      print('🚀 강제 재인증 로그인 시작');

      // 🔥 즉시 강제 재인증 로그인 (카카오와 동일한 방식, 대기시간 없음)
      final result = await FlutterNaverLogin.logIn();

      print('📊 네이버 로그인 결과: ${result.status}');

      if (result.status == NaverLoginStatus.loggedIn) {
        print('✅ 네이버 로그인 성공!');

        final token = await FlutterNaverLogin.getCurrentAccessToken();
        print('✅ 네이버 토큰 받음: ${token.accessToken.substring(0, 20)}...');

        // 🔥 서버로 토큰 전송
        await _sendNaverTokenToBackend(token.accessToken);

        print('🎉 네이버 로그인 완료!');

      } else {
        print('❌ 네이버 로그인 실패: ${result.status}');
        
        // 🔥 네이버 로그인 상태에 따른 정확한 에러 메시지 설정
        if (result.status == NaverLoginStatus.loggedOut) {
          // 사용자가 취소한 경우
          _errorMessage = '네이버 로그인이 취소되었습니다.';
          print('🔍 네이버 로그인 취소됨');
        } else {
          // 기타 오류
          throw Exception('네이버 로그인이 실패했습니다: ${result.status}');
        }
      }

    } catch (error) {
      print('❌ 네이버 로그인 실패: $error');

      String errorString = error.toString().toLowerCase();

      // 🔥 네이버 로그인 취소 감지를 더 정확하게 처리
      if (errorString.contains('canceled') || 
          errorString.contains('취소') ||
          errorString.contains('cancelled') ||
          errorString.contains('user_cancel') ||
          errorString.contains('사용자') ||
          errorString.contains('cancel')) {
        _errorMessage = '네이버 로그인이 취소되었습니다.';
        print('🔍 네이버 로그인 취소 감지됨');
      } else if (errorString.contains('naverloginexception')) {
        _errorMessage = '네이버 로그인 중 문제가 발생했습니다. 다시 시도해주세요.';
      } else if (errorString.contains('network') || 
                 errorString.contains('connection') ||
                 errorString.contains('timeout')) {
        _errorMessage = '네트워크 연결을 확인하고 다시 시도해주세요.';
      } else {
        _errorMessage = '네이버 로그인 중 오류가 발생했습니다.';
      }

      print('🎯 설정된 에러 메시지: $_errorMessage');
    } finally {
      // 🔥 네이버 로그인 로딩 상태만 false로 설정
      _isNaverLoading = false;
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

  // 🔥 소셜 로그인 성공 처리
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

  // 🔥 각각의 로딩 상태 설정 함수들
  void setGeneralLoading(bool loading) {
    _isGeneralLoading = loading;
    notifyListeners();
  }

  void setKakaoLoading(bool loading) {
    _isKakaoLoading = loading;
    notifyListeners();
  }

  void setNaverLoading(bool loading) {
    _isNaverLoading = loading;
    notifyListeners();
  }

  // 기존 setLoading은 호환성을 위해 남겨두되 모든 로딩을 false로 설정
  void setLoading(bool loading) {
    if (!loading) {
      _isGeneralLoading = false;
      _isKakaoLoading = false;
      _isNaverLoading = false;
    }
    notifyListeners();
  }

  // 🧹 로그아웃 시 호출되는 초기화 함수
  void onLogout() {
    print('🧹 로그아웃 시 LoginProvider 초기화');
    clearInputFields();
    _resetLoginForm();
    _loginFailCount = 0;
    _showCaptcha = false;
    // 🔥 모든 로딩 상태 초기화
    _isGeneralLoading = false;
    _isKakaoLoading = false;
    _isNaverLoading = false;
    notifyListeners();
  }
}