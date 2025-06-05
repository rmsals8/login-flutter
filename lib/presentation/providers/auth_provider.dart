// lib/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:login/data/models/user_model.dart';
import 'package:login/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false; // 🔥 초기화 상태 추적

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized; // 🔥 초기화 상태 getter

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
        if (!_disposed) { // dispose되지 않았을 때만
          notifyListeners();
        }
      });
      
    } catch (e) {
      print('❌ AuthProvider 초기화 실패: $e');
      _isAuthenticated = false;
      _currentUser = null;
      _isInitialized = true;
      
      // 에러 시에도 안전하게 알림
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    }
  }

  bool _disposed = false; // 🔥 dispose 상태 추적

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

  // 로그아웃
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _currentUser = null;
      _isAuthenticated = false;
      
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      print('❌ 로그아웃 오류: $e');
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