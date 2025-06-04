// lib/data/models/login_request.dart
class LoginRequest {
  final String username;
  final String password;
  final bool rememberMe;
  final String? captcha;

  LoginRequest({
    required this.username,
    required this.password,
    this.rememberMe = false,
    this.captcha,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'password': password,
      'rememberMe': rememberMe,
    };
    
    if (captcha != null && captcha!.isNotEmpty) {
      data['captcha'] = captcha;
    }
    
    return data;
  }

  @override
  String toString() {
    return 'LoginRequest{username: $username, password: [HIDDEN], rememberMe: $rememberMe, captcha: ${captcha != null ? '[PROVIDED]' : '[NULL]'}}';
  }
}