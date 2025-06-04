// lib/data/models/user_model.dart
class UserModel {
  final String userId;
  final String username;
  final String loginType;

  UserModel({
    required this.userId,
    required this.username,
    required this.loginType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      loginType: json['loginType'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'loginType': loginType,
    };
  }

  UserModel copyWith({
    String? userId,
    String? username,
    String? loginType,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  String toString() {
    return 'UserModel{userId: $userId, username: $username, loginType: $loginType}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          username == other.username &&
          loginType == other.loginType;

  @override
  int get hashCode => userId.hashCode ^ username.hashCode ^ loginType.hashCode;
}