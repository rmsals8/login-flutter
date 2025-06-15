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

  // 🔥 회원가입용 검증 메서드들 추가
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해 주세요.';
    }

    final name = value.trim();

    if (name.length < 2) {
      return '이름은 2자 이상이어야 합니다.';
    }
    if (name.length > 20) {
      return '이름은 20자 이하여야 합니다.';
    }

    final nameRegex = RegExp(r'^[가-힣a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(name)) {
      return '이름은 한글 또는 영문만 사용할 수 있습니다.';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해 주세요.';
    }

    final email = value.trim();

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return '올바른 이메일 형식을 입력해 주세요.';
    }

    if (email.length > 100) {
      return '이메일은 100자 이하여야 합니다.';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '전화번호를 입력해 주세요.';
    }

    final phone = value.replaceAll(RegExp(r'[^0-9-]'), '');

    final phoneRegex = RegExp(r'^010-?[0-9]{4}-?[0-9]{4}$');
    if (!phoneRegex.hasMatch(phone)) {
      return '올바른 휴대폰 번호를 입력해 주세요. (예: 010-1234-5678)';
    }

    return null;
  }

  static String? validateSignupCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '가입코드를 입력해 주세요.';
    }

    final code = value.trim();

    if (code.length < 6) {
      return '가입코드는 6자 이상이어야 합니다.';
    }

    if (code.length > 50) {
      return '가입코드는 50자 이하여야 합니다.';
    }

    return null;
  }
}