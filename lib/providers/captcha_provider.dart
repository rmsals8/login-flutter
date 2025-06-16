// lib/providers/captcha_provider.dart
import 'package:flutter/material.dart';
import 'package:login/data/repositories/auth_repository.dart';

class CaptchaProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  String? _captchaImageUrl;
  bool _isLoading = false;
  String _errorMessage = '';
  int _retryCount = 0; // 재시도 횟수를 추가한다
  static const int maxRetries = 3; // 최대 3번까지 재시도한다

  String? get captchaImageUrl => _captchaImageUrl;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get retryCount => _retryCount;

  // 🔥 캡차 이미지 새로고침 (개선된 버전)
  Future<void> refreshCaptcha() async {
    print('🔄 캡차 새로고침 시작 (재시도 횟수: $_retryCount)');
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 🔥 이전 이미지 URL을 먼저 null로 만들어서 깜빡임 효과를 준다
      _captchaImageUrl = null;
      notifyListeners();
      
      // 🔥 잠시 대기해서 UI가 업데이트되도록 한다
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('📡 서버에 캡차 이미지 요청 중...');
      final response = await _authRepository.getCaptchaImage();
      
      if (response.success && response.data != null) {
        // 🔥 서버에서 받은 base64 데이터를 그대로 사용한다 (타임스탬프는 서버 요청 시에만 사용)
        _captchaImageUrl = response.data;
        _retryCount = 0; // 성공하면 재시도 횟수를 0으로 초기화한다
        _errorMessage = '';
        
        print('✅ 캡차 이미지 로드 성공');
        print('🔍 이미지 URL 길이: ${_captchaImageUrl?.length ?? 0} characters');
      } else {
        throw Exception(response.message ?? '캡차 이미지를 불러올 수 없습니다.');
      }
    } catch (e) {
      print('❌ 캡차 이미지 로드 실패: $e');
      
      _retryCount++;
      
      // 🔥 최대 재시도 횟수보다 적으면 자동으로 다시 시도한다
      if (_retryCount < maxRetries) {
        print('🔄 자동 재시도 ($_retryCount/$maxRetries)');
        _errorMessage = '캡차 이미지 로딩 중... (${_retryCount}/$maxRetries)';
        notifyListeners();
        
        // 🔥 잠시 대기 후 자동 재시도
        await Future.delayed(Duration(seconds: _retryCount)); // 재시도할수록 더 오래 기다린다
        return refreshCaptcha(); // 재귀호출로 다시 시도한다
      } else {
        // 🔥 최대 재시도 횟수를 넘으면 에러 메시지를 보여준다
        _errorMessage = '캡차 이미지를 불러올 수 없습니다. 새로고침 버튼을 눌러주세요.';
        _captchaImageUrl = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥 수동 새로고침 (사용자가 버튼을 눌렀을 때)
  Future<void> manualRefresh() async {
    print('👆 사용자가 수동으로 캡차 새로고침 요청');
    _retryCount = 0; // 수동 새로고침 시에는 재시도 횟수를 초기화한다
    await refreshCaptcha();
  }

  // 🔥 캡차 초기화 (더 완전한 초기화)
  void resetCaptcha() {
    print('🧹 캡차 완전 초기화');
    _captchaImageUrl = null;
    _errorMessage = '';
    _retryCount = 0;
    _isLoading = false;
    notifyListeners();
  }

  // 🔥 강제 새로고침 (API 오류 시 사용)
  Future<void> forceRefresh() async {
    print('💪 캡차 강제 새로고침');
    resetCaptcha();
    await Future.delayed(const Duration(milliseconds: 500));
    await refreshCaptcha();
  }
}