// lib/data/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_helper.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;

  Dio get dio => _dio;

  void init() {
    print('🚀 ApiService 초기화 시작 (Web: $kIsWeb)');
    
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
      headers: {
        'Content-Type': ApiConstants.contentType,
        'Accept': ApiConstants.accept,
      },
    ));

    // 🔥 모바일에서만 SSL 검증 무시 (강화된 버전)
    if (!kIsWeb) {
      print('📱 모바일 환경 - SSL 검증 무시 설정 시작');
      
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            print('🔒 SSL 인증서 검증 무시: $host:$port');
            return true; // 모든 인증서 허용
          };
          return client;
        },
      );
      
      print('✅ SSL 검증 무시 설정 완료');
    } else {
      print('🌐 웹 환경 - SSL 검증 무시 스킵');
    }

    // 요청 인터셉터
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 요청 로깅
          print('🚀 API 요청: ${options.method} ${options.baseUrl}${options.path}');
          print('📝 요청 헤더: ${options.headers}');
          if (options.data != null) {
            print('📦 요청 데이터: ${options.data}');
          }

          // 토큰 추가
          final token = StorageHelper.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
            print('🔑 토큰 추가됨');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // 응답 로깅
          print('✅ API 응답: ${response.statusCode}');
          print('📦 응답 데이터: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          // 에러 로깅
          print('❌ API 에러: ${error.message}');
          if (error.response != null) {
            print('❌ 에러 상태: ${error.response?.statusCode}');
            print('❌ 에러 데이터: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
    
    print('✅ ApiService 초기화 완료');
  }

  // GET 요청
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      print('💥 GET 요청 실패: $e');
      rethrow;
    }
  }

  // POST 요청
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('📡 POST 요청 시작: $path');
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      print('✅ POST 요청 성공');
      return response;
    } catch (e) {
      print('💥 POST 요청 실패: $e');
      rethrow;
    }
  }

  // DELETE 요청
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      print('💥 DELETE 요청 실패: $e');
      rethrow;
    }
  }

  // 캡차 이미지 요청 (Uint8List 반환)
  Future<Response> getCaptchaImage() async {
    try {
      final response = await _dio.get(
        ApiConstants.captchaImageEndpoint,
        queryParameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
      return response;
    } catch (e) {
      print('💥 캡차 이미지 요청 실패: $e');
      rethrow;
    }
  }
}