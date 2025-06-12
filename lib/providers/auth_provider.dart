// lib/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:login/core/utils/storage_helper.dart';
import 'package:login/data/models/user_model.dart';
import 'package:login/data/repositories/auth_repository.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// 🔥 완전히 새로 작성된 로그아웃 메소드 (핵옵션 포함)
Future<void> logout() async {
  print('🚪 AuthProvider 핵옵션 로그아웃 시작');
  
  try {
    // 🔥 1. 소셜 로그인 플랫폼에서 로그아웃
    await _logoutFromSocialPlatforms();
    
    // 🔥 2. 우리 서비스에서 로그아웃  
    await _authRepository.logout();
    
    // 🔥 3. StorageHelper의 핵옵션 사용
    await StorageHelper.nuclearClear();
    
    // 🔥 4. 추가 강제 삭제
    await _additionalForceClear();
    
    // 🔥 5. 상태 초기화
    _currentUser = null;
    _isAuthenticated = false;
    
    if (!_disposed) {
      notifyListeners();
    }
    
    print('✅ AuthProvider 핵옵션 로그아웃 성공');
    
  } catch (e) {
    print('❌ AuthProvider 핵옵션 로그아웃 오류: $e');
    
    // 오류가 발생해도 상태는 초기화
    _currentUser = null;
    _isAuthenticated = false;
    
    if (!_disposed) {
      notifyListeners();
    }
  }
}

// 🔥 추가 강제 삭제 메소드
Future<void> _additionalForceClear() async {
  print('💥 추가 강제 삭제 시작');
  
  try {
    // 1. 카카오 SDK 강제 초기화
    try {
      await TokenManagerProvider.instance.manager.clear();
      print('✅ 카카오 TokenManager 강제 삭제');
    } catch (e) {
      print('⚠️ 카카오 TokenManager 삭제 실패: $e');
    }
    
    // 2. 네이버 SDK 강제 초기화
    try {
      await FlutterNaverLogin.logOut();
      await FlutterNaverLogin.logOutAndDeleteToken();
      print('✅ 네이버 로그인 강제 삭제');
    } catch (e) {
      print('⚠️ 네이버 로그인 삭제 실패: $e');
    }
    
    // 3. SharedPreferences 직접 접근해서 강제 삭제
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences 직접 강제 삭제');
    } catch (e) {
      print('⚠️ SharedPreferences 직접 삭제 실패: $e');
    }
    
    print('✅ 추가 강제 삭제 완료');
    
  } catch (e) {
    print('❌ 추가 강제 삭제 실패: $e');
  }
}

  // 🔥 소셜 로그인 플랫폼에서 로그아웃 + 로컬 데이터 완전 삭제 (통합 버전)
  Future<void> _logoutFromSocialPlatforms() async {
    print('📱 소셜 플랫폼 로그아웃 + 로컬 데이터 완전 삭제 시작');
    
    if (_currentUser == null || _currentUser!.loginType == 'normal') {
      print('일반 로그인 사용자 - 소셜 로그아웃 스킵');
      return;
    }
    
    final loginType = _currentUser!.loginType;
    print('🎯 로그인 타입: $loginType');
    
    // 카카오 로그아웃 + 데이터 삭제
    if (loginType == 'kakao') {
      await _logoutFromKakao();
    }
    
    // 네이버 로그아웃 + 데이터 삭제
    if (loginType == 'naver') {
      await _logoutFromNaver();
    }
    
    // 추가로 모든 소셜 로그인 관련 SharedPreferences 데이터 삭제
    await _clearAllSocialLoginSharedPrefs();
    
    print('✅ 소셜 플랫폼 로그아웃 + 로컬 데이터 완전 삭제 완료');
  }

  // 🔥 카카오에서 완전 로그아웃 + 모든 데이터 삭제
  Future<void> _logoutFromKakao() async {
    print('🍯 카카오 완전 로그아웃 + 데이터 삭제 시작');
    
    try {
      // 1단계: 카카오 서버에서 로그아웃
      try {
        final user = await UserApi.instance.me();
        if (user.id != null) {
          print('카카오에 로그인되어 있음 - 서버 로그아웃 진행');
          await UserApi.instance.logout();
          print('✅ 카카오 서버 로그아웃 성공');
        } else {
          print('카카오에 이미 로그아웃되어 있음');
        }
      } catch (e) {
        print('⚠️ 카카오 서버 로그아웃 실패 (이미 로그아웃되어 있을 수 있음): $e');
      }
      
      // 2단계: 기기에 저장된 모든 카카오 토큰 데이터 완전 삭제
      try {
        await TokenManagerProvider.instance.manager.clear();
        print('✅ 카카오 로컬 토큰 데이터 완전 삭제 성공');
      } catch (e) {
        print('⚠️ 카카오 로컬 토큰 삭제 실패: $e');
      }
      
      // 3단계: 추가 안전장치 - 카카오 SDK 초기화
      try {
        // 카카오 SDK를 완전히 초기화하여 모든 상태 리셋
        await TokenManagerProvider.instance.manager.clear();
        print('✅ 카카오 SDK 완전 초기화 성공');
      } catch (e) {
        print('⚠️ 카카오 SDK 초기화 실패: $e');
      }
      
      print('✅ 카카오 완전 로그아웃 + 데이터 삭제 완료');
      
    } catch (e) {
      print('❌ 카카오 로그아웃 + 데이터 삭제 중 오류: $e');
      // 오류가 발생해도 로컬 토큰만이라도 삭제 시도
      try {
        await TokenManagerProvider.instance.manager.clear();
        print('✅ 오류 발생했지만 카카오 로컬 토큰은 삭제 완료');
      } catch (clearError) {
        print('❌ 카카오 로컬 토큰 삭제도 실패: $clearError');
      }
    }
  }

  // 🔥 네이버에서 완전 로그아웃 + 모든 데이터 삭제
  Future<void> _logoutFromNaver() async {
    print('🟢 네이버 완전 로그아웃 + 데이터 삭제 시작');
    
    try {
      // 1단계: 네이버 서버에서 로그아웃
      await FlutterNaverLogin.logOut();
      print('✅ 네이버 서버 로그아웃 성공');
      
      // 2단계: 네이버 토큰 완전 삭제
      try {
        await FlutterNaverLogin.logOutAndDeleteToken();
        print('✅ 네이버 토큰 완전 삭제 성공');
      } catch (e) {
        print('⚠️ 네이버 토큰 추가 삭제 실패 (이미 삭제되었을 수 있음): $e');
      }
      
      print('✅ 네이버 완전 로그아웃 + 데이터 삭제 완료');
      
    } catch (e) {
      print('❌ 네이버 로그아웃 + 데이터 삭제 실패: $e');
    }
  }

  // 🔥 SharedPreferences의 소셜 로그인 관련 데이터 완전 삭제
  Future<void> _clearAllSocialLoginSharedPrefs() async {
    print('🧹 SharedPreferences의 모든 소셜 로그인 데이터 삭제 시작');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 🔥 모든 키를 가져와서 소셜 로그인 관련 키들을 찾아서 삭제
      final allKeys = prefs.getKeys();
      print('📋 현재 저장된 모든 키: $allKeys');
      
      // 소셜 로그인 관련 키 패턴들
      final socialKeyPatterns = [
        'kakao',
        'naver',
        'social',
        'oauth',
        'token',
        'auth',
      ];
      
      // 패턴이 포함된 키들 찾아서 삭제
      for (String key in allKeys) {
        for (String pattern in socialKeyPatterns) {
          if (key.toLowerCase().contains(pattern.toLowerCase())) {
            await prefs.remove(key);
            print('🗑️ 삭제된 SharedPreferences 키: $key');
            break;
          }
        }
      }
      
      // 추가로 명시적 키들도 삭제
      final explicitSocialKeys = [
        'kakao_token',
        'naver_token', 
        'social_login_type',
        'social_user_info',
        'login_type',
        'access_token',
        'refresh_token',
      ];
      
      for (String key in explicitSocialKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          print('🗑️ 삭제된 명시적 키: $key');
        }
      }
      
      print('✅ SharedPreferences 소셜 로그인 데이터 완전 삭제 완료');
      
    } catch (e) {
      print('❌ SharedPreferences 소셜 로그인 데이터 삭제 중 오류: $e');
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
      
      // 연결 끊기 후에도 로컬 데이터 삭제
      await _clearAllSocialLoginSharedPrefs();
      
      print('✅ 소셜 계정 연결 끊기 완료');
      
    } catch (e) {
      print('❌ 소셜 계정 연결 끊기 실패: $e');
    }
  }

  // 🔥 카카오 연결 끊기
  Future<void> _unlinkKakao() async {
    try {
      await UserApi.instance.unlink();
      await TokenManagerProvider.instance.manager.clear();
      print('✅ 카카오 연결 끊기 + 데이터 삭제 성공');
    } catch (e) {
      print('❌ 카카오 연결 끊기 실패: $e');
      rethrow;
    }
  }

  // 🔥 네이버 연결 끊기
  Future<void> _unlinkNaver() async {
    try {
      // 네이버는 앱에서 직접 연결 끊기를 지원하지 않으므로 로그아웃만 진행
      await FlutterNaverLogin.logOut();
      await FlutterNaverLogin.logOutAndDeleteToken();
      print('✅ 네이버 로그아웃 + 데이터 삭제 완료 (연결 끊기는 웹에서만 가능)');
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