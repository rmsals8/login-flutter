// lib/core/utils/validators.dart
class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '아이디를 입력해 주세요.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '비밀번호를 입력해 주세요.';
    }
    return null;
  }

  static String? validateCaptcha(String? value, bool showCaptcha) {
    if (showCaptcha && (value == null || value.trim().isEmpty)) {
      return '자동입력 방지 문자를 입력해 주세요.';
    }
    return null;
  }

  static bool isFormValid({
    required String username,
    required String password,
    String? captcha,
    bool showCaptcha = false,
  }) {
    return username.trim().isNotEmpty &&
           password.trim().isNotEmpty &&
           (!showCaptcha || (captcha != null && captcha.trim().isNotEmpty));
  }
}