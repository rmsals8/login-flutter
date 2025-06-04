// lib/data/models/login_response.dart
import 'user_model.dart';

class LoginResponse {
  final String? token;
  final String? userId;
  final String? username;
  final String? loginType;
  final String? message;
  final bool success;

  LoginResponse({
    this.token,
    this.userId,
    this.username,
    this.loginType,
    this.message,
    this.success = false,
  });

  // 🔥 JSON 파싱 함수 (여기서 실패하고 있음!)
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 LoginResponse.fromJson 시작');
    print('📦 입력 JSON: $json');
    
    try {
      final response = LoginResponse(
        token: json['token']?.toString(),
        userId: json['userId']?.toString(), 
        username: json['username']?.toString(),
        loginType: json['loginType']?.toString() ?? 'normal',
        message: json['message']?.toString(),
        success: json['token'] != null,
      );
      
      print('✅ LoginResponse 파싱 성공');
      print('  - token: ${response.token?.substring(0, 20)}...');
      print('  - userId: ${response.userId}');
      print('  - username: ${response.username}');
      print('  - success: ${response.success}');
      
      return response;
    } catch (e) {
      print('💥 LoginResponse 파싱 실패: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'username': username,
      'loginType': loginType,
      'message': message,
      'success': success,
    };
  }

  // UserModel로 변환
  UserModel? toUserModel() {
    if (userId != null && username != null) {
      return UserModel(
        userId: userId!,
        username: username!,
        loginType: loginType ?? 'normal',
      );
    }
    return null;
  }

  @override
  String toString() {
    return 'LoginResponse{token: ${token != null ? '[PROVIDED]' : '[NULL]'}, userId: $userId, username: $username, loginType: $loginType, message: $message, success: $success}';
  }
}