// lib/presentation/providers/captcha_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../data/repositories/auth_repository.dart';

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
    print('🔄 캡차 이미지 새로고침 시작');
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _authRepository.getCaptchaImage();
      print('📡 캡차 API 응답: ${response.success}');
      
      if (response.success && response.data != null) {
        // 🔥 바이트 데이터를 base64로 변환
        if (response.data is String) {
          _captchaImageUrl = response.data;
          print('✅ 캡차 이미지 URL 설정 완료 (String)');
        } else {
          // 바이트 배열인 경우 base64로 변환
          final bytes = response.data as List<int>;
          final base64String = base64Encode(Uint8List.fromList(bytes));
          _captchaImageUrl = 'data:image/jpeg;base64,$base64String';
          print('✅ 캡차 이미지 URL 설정 완료 (Base64): ${_captchaImageUrl?.substring(0, 50)}...');
        }
      } else {
        _errorMessage = response.message ?? '캡차 이미지를 불러올 수 없습니다.';
        _captchaImageUrl = null;
        print('❌ 캡차 이미지 로드 실패: $_errorMessage');
      }
    } catch (e) {
      print('💥 캡차 이미지 로딩 예외: $e');
      _errorMessage = '캡차 이미지 로딩 중 오류가 발생했습니다.';
      _captchaImageUrl = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🏁 캡차 이미지 새로고침 완료');
    }
  }

  // 캡차 초기화
  void resetCaptcha() {
    _captchaImageUrl = null;
    _errorMessage = '';
    notifyListeners();
  }
}