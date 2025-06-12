// lib/core/utils/storage_helper.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class StorageHelper {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageHelper not initialized. Call StorageHelper.init() first.');
    }
    return _prefs!;
  }

  // 토큰 관련
  static Future<bool> setToken(String token) async {
    return await prefs.setString(StorageKeys.userToken, token);
  }

  static String? getToken() {
    return prefs.getString(StorageKeys.userToken);
  }

  static Future<bool> removeToken() async {
    return await prefs.remove(StorageKeys.userToken);
  }

  static bool hasToken() {
    return prefs.containsKey(StorageKeys.userToken) && getToken()?.isNotEmpty == true;
  }

  // 사용자 데이터 관련
  static Future<bool> setUserData(Map<String, dynamic> userData) async {
    final userDataString = jsonEncode(userData);
    return await prefs.setString(StorageKeys.userData, userDataString);
  }

  static Map<String, dynamic>? getUserData() {
    final userDataString = prefs.getString(StorageKeys.userData);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  static Future<bool> removeUserData() async {
    return await prefs.remove(StorageKeys.userData);
  }

  // 로그인 실패 횟수
  static Future<bool> setLoginFailCount(int count) async {
    return await prefs.setInt(StorageKeys.loginFailCount, count);
  }

  static int getLoginFailCount() {
    return prefs.getInt(StorageKeys.loginFailCount) ?? 0;
  }

  static Future<bool> removeLoginFailCount() async {
    return await prefs.remove(StorageKeys.loginFailCount);
  }

  // 로그인 유지
  static Future<bool> setRememberMe(bool remember) async {
    return await prefs.setBool(StorageKeys.rememberMe, remember);
  }

  static bool getRememberMe() {
    return prefs.getBool(StorageKeys.rememberMe) ?? false;
  }

  // IP 보안
  static Future<bool> setIpSecurity(bool ipSecurity) async {
    return await prefs.setBool(StorageKeys.ipSecurity, ipSecurity);
  }

  static bool getIpSecurity() {
    return prefs.getBool(StorageKeys.ipSecurity) ?? false;
  }

  // 모든 데이터 삭제
  static Future<bool> clearAll() async {
    return await prefs.clear();
  }

  // 로그아웃 시 필요한 데이터만 삭제
  static Future<void> clearAuthData() async {
    await Future.wait([
      removeToken(),
      removeUserData(),
      removeLoginFailCount(),
    ]);
  }

  // 🔥 모든 소셜 로그인 관련 데이터 강제 삭제 (Android 전용)
static Future<void> clearAllSocialLoginData() async {
  print('🧹 StorageHelper: 모든 소셜 로그인 데이터 강제 삭제 시작');
  
  try {
    // 1. 우리 앱의 모든 SharedPreferences 파일들 확인
    final allKeys = prefs.getKeys();
    print('📋 현재 저장된 모든 키: $allKeys');
    
    // 2. 소셜 로그인 관련 키 패턴들
    final socialPatterns = [
      'kakao', 'naver', 'google', 'facebook', 'apple',
      'oauth', 'token', 'auth', 'social', 'login',
      'access', 'refresh', 'session', 'credential'
    ];
    
    int deletedCount = 0;
    
    // 3. 패턴 매칭으로 삭제
    for (String key in allKeys.toList()) {
      for (String pattern in socialPatterns) {
        if (key.toLowerCase().contains(pattern)) {
          await prefs.remove(key);
          print('🗑️ 삭제된 키: $key');
          deletedCount++;
          break;
        }
      }
    }
    
    print('✅ StorageHelper: 총 ${deletedCount}개의 소셜 로그인 관련 키 삭제 완료');
    
  } catch (e) {
    print('❌ StorageHelper: 소셜 로그인 데이터 삭제 실패: $e');
  }
}

// 🔥 완전한 앱 데이터 초기화 (핵옵션)
static Future<void> nuclearClear() async {
  print('💥 StorageHelper: 핵옵션 - 모든 앱 데이터 완전 삭제');
  
  try {
    // 모든 SharedPreferences 데이터 삭제
    await prefs.clear();
    print('✅ 모든 SharedPreferences 데이터 삭제 완료');
    
    // 재초기화
    await init();
    print('✅ StorageHelper 재초기화 완료');
    
  } catch (e) {
    print('❌ 핵옵션 실패: $e');
  }
}
}
