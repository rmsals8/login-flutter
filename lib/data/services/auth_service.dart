// lib/data/services/auth_service.dart
import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/api_response.dart';
import '../models/hello_response.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';
import '../../core/utils/storage_helper.dart';
import 'dart:convert';
class AuthService {
  final ApiService _apiService = ApiService();

  // 🔥 로그인 API 호출 (예외 처리 강화)
  Future<ApiResponse<LoginResponse>> login(LoginRequest loginRequest) async {
    print('🌐 AuthService.login() - 실제 API 호출 시작');
    print('📡 API 엔드포인트: ${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
    print('📝 요청 데이터: ${loginRequest.toJson()}');
    
    try {
      final response = await _apiService.post(
        ApiConstants.loginEndpoint,
        data: loginRequest.toJson(),
      );

      print('✅ API 응답 성공 - 상태코드: ${response.statusCode}');
      print('📦 원본 응답 데이터: ${response.data}');
      print('📦 응답 데이터 타입: ${response.data.runtimeType}');

      if (response.statusCode == 200 && response.data != null) {
        try {
          // 🔥 응답 데이터를 Map으로 확실히 변환
          Map<String, dynamic> responseMap;
          if (response.data is Map<String, dynamic>) {
            responseMap = response.data as Map<String, dynamic>;
          } else if (response.data is String) {
            // 문자열인 경우 JSON 파싱 시도
            print('📝 문자열 응답을 JSON으로 파싱 시도');
            responseMap = Map<String, dynamic>.from(response.data);
          } else {
            print('⚠️ 예상하지 못한 응답 데이터 타입: ${response.data.runtimeType}');
            responseMap = Map<String, dynamic>.from(response.data);
          }
          
          print('🔍 파싱할 Map 데이터: $responseMap');
          
          // LoginResponse 변환
          final loginResponse = LoginResponse.fromJson(responseMap);
          print('🎉 LoginResponse 변환 성공: ${loginResponse.toString()}');
          
          return ApiResponse.success(
            loginResponse,
            message: '로그인 성공',
            statusCode: response.statusCode,
          );
          
        } catch (parseError) {
          print('💥 응답 파싱 실패: $parseError');
          print('📋 파싱 에러 상세: ${parseError.toString()}');
          
          // 파싱 실패해도 토큰이 있으면 수동으로 LoginResponse 생성
          if (response.data != null && response.data['token'] != null) {
            print('🔧 수동 LoginResponse 생성 시도');
            final manualResponse = LoginResponse(
              token: response.data['token']?.toString(),
              userId: response.data['userId']?.toString(),
              username: response.data['username']?.toString(),
              loginType: response.data['loginType']?.toString() ?? 'normal',
              success: true,
            );
            
            print('✅ 수동 생성 성공: ${manualResponse.toString()}');
            return ApiResponse.success(
              manualResponse,
              message: '로그인 성공 (수동 파싱)',
              statusCode: response.statusCode,
            );
          }
          
          return ApiResponse.error('응답 데이터 파싱에 실패했습니다: $parseError');
        }
      } else {
        print('❌ API 응답 실패 - 상태코드: ${response.statusCode}');
        return ApiResponse.error(
          '로그인에 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('💥 AuthService 예외 발생: $e');
      print('📋 예외 타입: ${e.runtimeType}');
      print('📋 예외 상세: ${e.toString()}');
      return ApiResponse.error(_handleError(e));
    }
  }

  // 로그아웃 API
  Future<ApiResponse<bool>> logout() async {
    try {
      print('🚪 AuthService.logout() 시작');

      // 🔥 토큰 상태 확인
      final token = StorageHelper.getToken();
      print('🔑 현재 저장된 토큰: ${token != null ? "${token.substring(0, 20)}..." : "null"}');
      print('📍 토큰 존재 여부: ${token != null && token.isNotEmpty}');

      print('📡 DELETE 요청 시작: ${ApiConstants.baseUrl}${ApiConstants.logoutEndpoint}');

      final response = await _apiService.delete(ApiConstants.logoutEndpoint);

      print('✅ DELETE 응답 받음');
      print('📊 응답 상태코드: ${response.statusCode}');
      print('📦 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        print('🎉 서버 로그아웃 성공');
        return ApiResponse.success(true, message: '로그아웃 성공');
      } else {
        print('❌ 서버 로그아웃 실패: ${response.statusCode}');
        return ApiResponse.error('로그아웃에 실패했습니다.');
      }
    } catch (e) {
      print('💥 AuthService.logout() 예외: $e');
      print('📋 예외 타입: ${e.runtimeType}');
      return ApiResponse.error(_handleError(e));
    }
  }

  // Hello API
  Future<ApiResponse<HelloResponse>> getHello() async {
    try {
      final response = await _apiService.get(ApiConstants.helloEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        final helloResponse = HelloResponse.fromJson(response.data);
        return ApiResponse.success(helloResponse);
      } else {
        return ApiResponse.error('Hello API 요청에 실패했습니다.');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // 캡차 이미지
// 캐차 이미지
Future<ApiResponse<String>> getCaptchaImage() async {
  try {
    print('📸 캡차 이미지 요청 시작');
    
    // 🔥 타임스탬프를 쿼리 파라미터에 추가해서 캐시를 방지한다
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final response = await _apiService.get(
      ApiConstants.captchaImageEndpoint,
      queryParameters: {
        'timestamp': timestamp,
        'v': '2.0', // 버전 파라미터도 추가한다
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate', // 🔥 캐시 완전 방지
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        // 🔥 타임아웃 설정은 Options에서 제거 (BaseOptions에서 이미 설정됨)
      ),
    );
    
    print('✅ 캡차 이미지 데이터 받음');
    
    if (response.statusCode == 200 && response.data != null) {
      try {
        final bytes = response.data as List<int>;
        print('📏 바이트 길이: ${bytes.length}');
        
        // 🔥 이미지 데이터가 너무 작으면 오류로 처리한다
        if (bytes.length < 100) {
          throw Exception('받은 이미지 데이터가 너무 작습니다 (${bytes.length} bytes)');
        }
        
        // 🔥 base64 인코딩을 더 안전하게 처리한다
        print('🔄 Base64 변환 시작');
        final base64Bytes = base64Encode(bytes);
        final base64String = 'data:image/jpeg;base64,$base64Bytes';
        print('🔄 Base64 변환 완료');
        print('📏 Base64 문자열 길이: ${base64String.length}');
        
        return ApiResponse.success(base64String);
      } catch (e) {
        print('❌ 이미지 데이터 처리 실패: $e');
        return ApiResponse.error('이미지 데이터 처리 중 오류가 발생했습니다: $e');
      }
    } else {
      print('❌ 캡차 API 응답 실패: ${response.statusCode}');
      return ApiResponse.error('캡차 이미지를 불러올 수 없습니다 (${response.statusCode})');
    }
  } catch (e) {
    print('❌ 캡차 이미지 API 호출 실패: $e');
    return ApiResponse.error(_handleError(e));
  }
}
  // 에러 처리
  String _handleError(dynamic error) {
    print('🔍 AuthService 에러 분석: $error');
    
    if (error.toString().contains('DioException')) {
      final dioError = error;
      if (dioError.response != null) {
        final statusCode = dioError.response?.statusCode;
        final errorData = dioError.response?.data;
        
        print('  - 상태코드: $statusCode');
        print('  - 에러 데이터: $errorData');
        
        if (errorData != null && errorData is Map<String, dynamic>) {
          final message = errorData['message'];
          if (message != null && message.toString().isNotEmpty) {
            return message.toString();
          }
        }
        
        switch (statusCode) {
          case 400: return '잘못된 요청입니다.';
          case 401: return '인증에 실패했습니다.';
          case 403: return '접근이 거부되었습니다.';
          case 404: return '리소스를 찾을 수 없습니다.';
          case 500: return '서버 내부 오류가 발생했습니다.';
          default: return '네트워크 오류가 발생했습니다. (코드: $statusCode)';
        }
      } else {
        return '서버에서 응답이 없습니다. 네트워크 연결을 확인해주세요.';
      }
    }
    
    return '예외 발생: $error';
  }
}