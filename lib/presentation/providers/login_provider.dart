// lib/presentation/providers/login_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 🔥 카카오 SDK 추가
import 'package:http/http.dart' as http; // 🔥 HTTP 추가
import 'dart:convert'; // 🔥 JSON 추가
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/url_launcher_helper.dart';
import '../../core/utils/storage_helper.dart'; // 🔥 StorageHelper 추가
import '../../data/models/login_request.dart';
import '../../data/models/user_model.dart'; // 🔥 UserModel 추가
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
  bool _mounted = true; // 🔥 mounted 상태 추가

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
  bool get mounted => _mounted; // 🔥 mounted getter 추가

  @override
  void dispose() {
    _mounted = false; // 🔥 dispose 시 mounted = false
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

  // 🧹 입력 필드 초기화 함수 (로그인 성공/로그아웃 시 호출)
  void clearInputFields() {
    print('🧹 입력 필드 초기화 시작');
    usernameController.clear();
    passwordController.clear();
    captchaController.clear();

    // 에러 메시지도 초기화
    _clearErrors();

    // 폼 유효성도 재검사
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

        // 🔥 AuthProvider에 사용자 정보 설정 (중요!)
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

    // 🧹 입력 필드 초기화 (실패 시에도)
    usernameController.clear();
    passwordController.clear();

    // 실패 횟수 증가
    _loginFailCount = _authRepository.getLoginFailCount();
    print('📊 현재 실패 횟수: $_loginFailCount');

    // 3회 이상 실패 시 캡차 표시
    if (_loginFailCount >= 3) {
      _showCaptcha = true;
      print('🔒 캡차 표시 활성화');
    }

    // 캡차 관련 오류인지 확인
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

  // 🔥 모바일 전용 카카오 로그인 (수정됨)
  Future<void> kakaoLogin() async {
    print('📱 모바일 카카오 로그인 시작');
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      // 🔥 수정: 함수명 중복 해결
      bool kakaoTalkInstalled = await isKakaoTalkInstalled();

      OAuthToken token;
      if (kakaoTalkInstalled) {
        // 2-1. 카카오톡 앱으로 로그인
        print('📱 카카오톡 앱으로 로그인');
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        // 2-2. 웹 브라우저로 로그인
        print('🌐 웹 브라우저로 로그인');
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('✅ 카카오 토큰 받음: ${token.accessToken.substring(0, 20)}...');

      // 3. 서버로 토큰 전송
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

  // 🔥 서버로 카카오 토큰 전송하는 함수 (수정됨)
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

        // 🔥 받은 JWT 토큰 저장
        final jwtToken = authResponse['token'];
        if (jwtToken != null) {
          await StorageHelper.setToken(jwtToken);
          print('💾 JWT 토큰 저장 완료');
        }

        // 🔥 사용자 정보 저장
        final userModel = UserModel(
          userId: authResponse['userId'].toString(),
          username: authResponse['username'] ?? 'Unknown',
          loginType: 'kakao',
        );

        await StorageHelper.setUserData(userModel.toJson());
        print('👤 사용자 정보 저장 완료: ${userModel.username}');

        // 로그인 실패 횟수 초기화
        await StorageHelper.removeLoginFailCount();

        // 🔥 AuthProvider 업데이트
        if (_context != null) {
          final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
          authProvider.setUser(userModel);
          print('🔄 AuthProvider 업데이트 완료');
        }

        _successMessage = '카카오 로그인 성공!';
        print('🎉 카카오 로그인 완료');

        // 🔥 입력 필드 초기화 (카카오 로그인 성공 시)
        clearInputFields();
        _resetLoginForm();

        // 🔥 대시보드로 자동 이동
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

      } else {
        throw Exception('서버 인증 실패: ${response.body}');
      }

    } catch (e) {
      print('💥 서버 토큰 전송 실패: $e');
      _errorMessage = '로그인 처리 중 오류가 발생했습니다: $e';
      rethrow;
    }
  }

  Future<void> naverLogin() async {
    print('📱 네이버 로그인 시작');
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      // 🔥 현재 Flutter 앱의 콜백 URL 생성
      final currentOrigin = html.window.location.origin;
      final flutterCallbackUrl = '$currentOrigin/auth/callback';

      // 🔥 백엔드에 Flutter 콜백 URL 전달
      final naverLoginUrl = '${ApiConstants.baseUrl}/api/auth/naver/login'
          '?redirect_uri=${Uri.encodeComponent(flutterCallbackUrl)}'
          '&app_type=flutter';

      print('🔗 네이버 로그인 URL: $naverLoginUrl');
      print('📍 Flutter 콜백 URL: $flutterCallbackUrl');

      final success = await UrlLauncherHelper.launchURL(naverLoginUrl);
      if (!success) {
        _errorMessage = '네이버 로그인을 시작할 수 없습니다.';
        print('❌ 네이버 로그인 실패: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = '네이버 로그인 중 오류가 발생했습니다.';
      print('💥 네이버 로그인 예외: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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