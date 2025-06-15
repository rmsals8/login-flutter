// lib/data/models/signup_request.dart
class SignupRequest {
  final String username;
  final String password;
  final String name;
  final String email;
  final String phone;
  final int role;
  final String signupCode;

  SignupRequest({
    required this.username,
    required this.password,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.signupCode,
  });

  // JSON으로 변환하는 메서드
  // 서버에 데이터를 보낼 때 사용한다
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'signupCode': signupCode,
    };
  }

  // JSON에서 객체로 변환하는 메서드 (나중에 필요하면 사용)
  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    return SignupRequest(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 0,
      signupCode: json['signupCode'] ?? '',
    );
  }

  // 디버깅용 문자열 표현
  @override
  String toString() {
    return 'SignupRequest(username: $username, name: $name, email: $email, role: $role)';
  }

  // 객체 복사 메서드 (필요시 사용)
  SignupRequest copyWith({
    String? username,
    String? password,
    String? name,
    String? email,
    String? phone,
    int? role,
    String? signupCode,
  }) {
    return SignupRequest(
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      signupCode: signupCode ?? this.signupCode,
    );
  }
}