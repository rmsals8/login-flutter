// lib/data/models/hello_response.dart
class HelloResponse {
  final String message;

  HelloResponse({required this.message});

  factory HelloResponse.fromJson(Map<String, dynamic> json) {
    return HelloResponse(
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }

  @override
  String toString() {
    return 'HelloResponse{message: $message}';
  }
}