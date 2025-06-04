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
}
