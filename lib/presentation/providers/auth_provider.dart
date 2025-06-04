// lib/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:login/data/models/user_model.dart';
import 'package:login/data/repositories/auth_repository.dart';


class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // 초기화
  Future<void> init() async {
    _isAuthenticated = _authRepository.isAuthenticated();
    if (_isAuthenticated) {
      _currentUser = _authRepository.getCurrentUser();
    }
    notifyListeners();
  }

  // 로그인 성공 시 호출
  void setUser(UserModel user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  // 로그아웃
  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // 사용자 정보 업데이트
  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}