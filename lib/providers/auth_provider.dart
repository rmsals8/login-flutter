// lib/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:login/data/models/user_model.dart';
import 'package:login/data/repositories/auth_repository.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  // 🔥 안전한 초기화 함수
  Future<void> init() async {
    try {
      print('🔄 AuthProvider 초기화 시작');
      
      _isAuthenticated = _authRepository.isAuthenticated();
      print('📊 인증 상태: $_isAuthenticated');
      
      if (_isAuthenticated) {
        _currentUser = _authRepository.getCurrentUser();
        print('👤 현재 사용자: ${_currentUser?.username}');
      }
      
      _isInitialized = true;
      print('✅ AuthProvider 초기화 완료');
      
      // 🔥 안전하게 알림 (빌드 중이 아닐 때만)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
      
    } catch (e) {
      print('❌ AuthProvider 초기화 실패: $e');
      _isAuthenticated = false;
      _currentUser = null;
      _isInitialized = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // 로그인 성공 시 호출
  void setUser(UserModel user) {
    _currentUser = user;
    _isAuthenticated = true;
    _isInitialized = true;
    
    if (!_disposed) {
      notifyListeners();
    }
  }

  // 🔥 완전히 새로 작성된 로그아웃 메소드 (소셜 로그아웃 포함)
  Future<void> logout() async {
    print('🚪 AuthProvider 완전 로그아웃 시작');
    
    try {
      // 🔥 1. 소셜 로그인 플랫폼에서 로그아웃
      await _logoutFromSocialPlatforms();
      
      // 🔥 2. 우리 서비스에서 로그아웃
      await _authRepository.logout();
      
      // 🔥 3. 상태 초기화
      _currentUser = null;
      _isAuthenticated = false;
      
      if (!_disposed) {
        notifyListeners();
      }
      
      print('✅ AuthProvider 완전 로그아웃 성공');
      
    } catch (e) {
      print('❌ AuthProvider 로그아웃 오류: $e');
      
      // 오류가 발생해도 상태는 초기화
      _currentUser = null;
      _isAuthenticated = false;
      
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // 🔥 소셜 로그인 플랫폼에서 로그아웃하는 private 메소드
  Future<void> _logoutFromSocialPlatforms() async {
    print('📱 소셜 플랫폼 로그아웃 시작');
    
    if (_currentUser == null || _currentUser!.loginType == 'normal') {
      print('일반 로그인 사용자 - 소셜 로그아웃 스킵');
      return;
    }
    
    final loginType = _currentUser!.loginType;
    print('로그인 타입: $loginType');
    
    // 카카오 로그아웃
    if (loginType == 'kakao') {
      await _logoutFromKakao();
    }
    
    // 네이버 로그아웃
    if (loginType == 'naver') {
      await _logoutFromNaver();
    }
  }

  // 🔥 카카오에서 로그아웃하는 메소드
  Future<void> _logoutFromKakao() async {
    print('🍯 카카오 로그아웃 시작');
    
    try {
      // 카카오 로그인 상태 확인
      final user = await UserApi.instance.me();
      if (user.id != null) {
        print('카카오에 로그인되어 있음 - 로그아웃 진행');
        
        // 카카오에서 로그아웃
        await UserApi.instance.logout();
        print('✅ 카카오 로그아웃 성공');
      } else {
        print('카카오에 이미 로그아웃되어 있음');
      }
    } catch (e) {
      print('⚠️ 카카오 로그아웃 실패 (이미 로그아웃되어 있을 수 있음): $e');
      // 실패해도 계속 진행
    }
  }

  // 🔥 네이버에서 로그아웃하는 메소드
  Future<void> _logoutFromNaver() async {
    print('🟢 네이버 로그아웃 시작');
    
    try {
      // 네이버 로그아웃
      await FlutterNaverLogin.logOut();
      print('✅ 네이버 로그아웃 성공');
    } catch (e) {
      print('⚠️ 네이버 로그아웃 실패 (이미 로그아웃되어 있을 수 있음): $e');
      // 실패해도 계속 진행
    }
  }

  // 🔥 강력한 로그아웃 (소셜 로그인 연결까지 끊기) - 선택사항
  Future<void> unlinkSocialAccounts() async {
    print('🔗 소셜 계정 연결 끊기 시작');
    
    if (_currentUser == null || _currentUser!.loginType == 'normal') {
      print('일반 로그인 사용자 - 연결 끊기 스킵');
      return;
    }
    
    final loginType = _currentUser!.loginType;
    
    try {
      // 카카오 연결 끊기
      if (loginType == 'kakao') {
        await _unlinkKakao();
      }
      
      // 네이버 연결 끊기
      if (loginType == 'naver') {
        await _unlinkNaver();
      }
      
      print('✅ 소셜 계정 연결 끊기 완료');
      
    } catch (e) {
      print('❌ 소셜 계정 연결 끊기 실패: $e');
    }
  }

  // 🔥 카카오 연결 끊기
  Future<void> _unlinkKakao() async {
    try {
      await UserApi.instance.unlink();
      print('✅ 카카오 연결 끊기 성공');
    } catch (e) {
      print('❌ 카카오 연결 끊기 실패: $e');
      rethrow;
    }
  }

  // 🔥 네이버 연결 끊기
  Future<void> _unlinkNaver() async {
    try {
      // 네이버는 앱에서 직접 연결 끊기를 지원하지 않으므로
      // 로그아웃만 진행
      await FlutterNaverLogin.logOut();
      print('✅ 네이버 로그아웃 완료 (연결 끊기는 웹에서만 가능)');
    } catch (e) {
      print('❌ 네이버 로그아웃 실패: $e');
      rethrow;
    }
  }

  // 사용자 정보 업데이트
  void updateUser(UserModel user) {
    _currentUser = user;
    if (!_disposed) {
      notifyListeners();
    }
  }
}