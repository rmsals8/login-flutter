// lib/data/repositories/auth_repository.dart
import '../models/user_model.dart';
import '../models/login_request.dart';
import '../models/api_response.dart';
import '../models/hello_response.dart';
import '../services/auth_service.dart';
import '../../core/utils/storage_helper.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  // 🔥 로그인 메인 함수
  Future<ApiResponse<UserModel>> login(LoginRequest loginRequest) async {
    print('🏪 AuthRepository.login() 시작');
    
    try {
      final response = await _authService.login(loginRequest);
      print('📡 AuthService 응답 받음: ${response.toString()}');
      
      if (response.success && response.data != null) {
        final loginResponse = response.data!;
        print('🎯 LoginResponse 데이터:');
        print('  - token: ${loginResponse.token?.substring(0, 20)}...');
        print('  - userId: ${loginResponse.userId}');
        print('  - username: ${loginResponse.username}');
        
        // 🔥 토큰 저장
        if (loginResponse.token != null && loginResponse.token!.isNotEmpty) {
          await StorageHelper.setToken(loginResponse.token!);
          print('💾 토큰 저장 완료');
        } else {
          print('❌ 토큰이 없음!');
          return ApiResponse.error('토큰이 없습니다.');
        }
        
        // 🔥 사용자 정보 저장
        final userModel = loginResponse.toUserModel();
        if (userModel != null) {
          await StorageHelper.setUserData(userModel.toJson());
          print('👤 사용자 정보 저장 완료: ${userModel.username}');
          
          // 로그인 실패 횟수 초기화
          await StorageHelper.removeLoginFailCount();
          print('📊 로그인 실패 횟수 초기화');
          
          return ApiResponse.success(
            userModel,
            message: response.message ?? '로그인 성공',
            statusCode: response.statusCode,
          );
        } else {
          print('❌ UserModel 변환 실패');
          return ApiResponse.error('사용자 정보를 처리할 수 없습니다.');
        }
      } else {
        print('❌ AuthService 응답 실패: ${response.message}');
        
        // 로그인 실패 시 실패 횟수 증가
        final currentFailCount = StorageHelper.getLoginFailCount();
        await StorageHelper.setLoginFailCount(currentFailCount + 1);
        print('📊 로그인 실패 횟수 증가: ${currentFailCount + 1}');
        
        return ApiResponse.error(
          response.message ?? '로그인에 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('💥 AuthRepository 예외: $e');
      return ApiResponse.error('로그인 처리 중 오류가 발생했습니다: $e');
    }
  }

  // 로그아웃
  Future<ApiResponse<bool>> logout() async {
    try {

      await StorageHelper.clearAuthData();
      return ApiResponse.success(true, message: '로그아웃되었습니다.');
    } catch (e) {
      await StorageHelper.clearAuthData();
      return ApiResponse.success(true, message: '로그아웃되었습니다.');
    }
  }

  // Hello API
  Future<ApiResponse<HelloResponse>> getHello() async {
    return await _authService.getHello();
  }

  // 캡차 이미지
  Future<ApiResponse<String>> getCaptchaImage() async {
    return await _authService.getCaptchaImage();
  }

  // 현재 사용자 정보
  UserModel? getCurrentUser() {
    final userData = StorageHelper.getUserData();
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  // 인증 상태 확인
  bool isAuthenticated() {
    return StorageHelper.hasToken();
  }

  // 로그인 실패 횟수
  int getLoginFailCount() {
    return StorageHelper.getLoginFailCount();
  }

  // 설정
  bool getRememberMe() {
    return StorageHelper.getRememberMe();
  }

  bool getIpSecurity() {
    return StorageHelper.getIpSecurity();
  }

  Future<void> setRememberMe(bool value) async {
    await StorageHelper.setRememberMe(value);
  }

  Future<void> setIpSecurity(bool value) async {
    await StorageHelper.setIpSecurity(value);
  }
}