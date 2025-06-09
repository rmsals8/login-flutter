// lib/core/constants/api_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // 🔥 .env에서 BASE_URL 읽기
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  
  // 🔥 baseUrl 검증 함수
  static String getValidatedBaseUrl() {
    final url = baseUrl;
    if (url.isEmpty) {
      throw Exception('BASE_URL이 .env 파일에 설정되지 않았습니다!');
    }
    return url;
  }
  
  static const String loginEndpoint = '/api/auth/login';
  static const String logoutEndpoint = '/logout';
  static const String captchaImageEndpoint = '/api/captcha/image';
  static const String kakaoLoginEndpoint = '/api/auth/kakao/login';
  static const String naverLoginEndpoint = '/api/auth/naver/login';
  static const String helloEndpoint = '/api/hello';
  
  // 헤더
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
  
  // 타임아웃
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
  static const int sendTimeout = 10000;
}