// lib/presentation/providers/captcha_provider.dart
import 'package:flutter/material.dart';
import 'package:login/data/repositories/auth_repository.dart';


class CaptchaProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  String? _captchaImageUrl;
  bool _isLoading = false;
  String _errorMessage = '';

  String? get captchaImageUrl => _captchaImageUrl;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // 캡차 이미지 새로고침
  Future<void> refreshCaptcha() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _authRepository.getCaptchaImage();
      
      if (response.success && response.data != null) {
        _captchaImageUrl = response.data;
      } else {
        _errorMessage = response.message ?? '캡차 이미지를 불러올 수 없습니다.';
        _captchaImageUrl = null;
      }
    } catch (e) {
      _errorMessage = '캡차 이미지 로딩 중 오류가 발생했습니다.';
      _captchaImageUrl = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 캡차 초기화
  void resetCaptcha() {
    _captchaImageUrl = null;
    _errorMessage = '';
    notifyListeners();
  }
}