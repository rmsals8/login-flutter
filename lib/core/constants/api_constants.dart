
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://3.37.89.76';
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