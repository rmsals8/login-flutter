// lib/providers/signup_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../data/models/signup_request.dart';

class SignupProvider extends ChangeNotifier {
  // Controllers - 텍스트 입력 필드들을 관리하는 컨트롤러들이다
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController signupCodeController = TextEditingController();

  // Focus nodes - 각 입력 필드의 포커스 상태를 관리한다
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode signupCodeFocusNode = FocusNode();

  // 상태 변수들
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isFormValid = false;
  int _selectedRole = 0; // 0: 일반사용자, 1: 관리자
  bool? _usernameAvailable; // null: 확인안함, true: 사용가능, false: 사용불가

  // 에러 메시지들
  String _errorMessage = '';
  String _successMessage = '';
  String _usernameError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';
  String _nameError = '';
  String _emailError = '';
  String _phoneError = '';
  String _signupCodeError = '';

  // Getters - 외부에서 상태를 읽을 수 있게 해주는 메서드들이다
  bool get isLoading => _isLoading;
  bool get isCheckingUsername => _isCheckingUsername;
  bool get isFormValid => _isFormValid;
  int get selectedRole => _selectedRole;
  bool? get usernameAvailable => _usernameAvailable;

  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;
  String get usernameError => _usernameError;
  String get passwordError => _passwordError;
  String get confirmPasswordError => _confirmPasswordError;
  String get nameError => _nameError;
  String get emailError => _emailError;
  String get phoneError => _phoneError;
  String get signupCodeError => _signupCodeError;

  // 역할 설정 메서드
  void setRole(int role) {
    _selectedRole = role;
    _validateForm();
    notifyListeners();
  }

  // 사용자명 유효성 검사 메서드
  void validateUsername() {
    final username = usernameController.text.trim();

    // 기본 유효성 검사 (기존 방식 사용)
    if (username.isEmpty) {
      _usernameError = '아이디를 입력해 주세요.';
    } else if (username.length < 4) {
      _usernameError = '아이디는 4자 이상이어야 합니다.';
    } else if (username.length > 20) {
      _usernameError = '아이디는 20자 이하여야 합니다.';
    } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
      _usernameError = '아이디는 영문과 숫자만 사용할 수 있습니다.';
    } else if (!RegExp(r'^[a-zA-Z]').hasMatch(username)) {
      _usernameError = '아이디는 영문으로 시작해야 합니다.';
    } else {
      _usernameError = '';
    }

    // 사용자명이 유효하고 변경되었다면 중복 확인
    if (_usernameError.isEmpty && username.isNotEmpty) {
      _checkUsernameAvailability(username);
    } else {
      _usernameAvailable = null;
    }

    _validateForm();
    notifyListeners();
  }

  // 사용자명 중복 확인 메서드
  Future<void> _checkUsernameAvailability(String username) async {
    if (_isCheckingUsername) return;

    _isCheckingUsername = true;
    notifyListeners();

    try {
      print('🔍 사용자명 중복 확인: $username');

      // 🔥 ApiConstants.baseUrl 사용
      final fullUrl = '${ApiConstants.baseUrl}/api/check-username/$username';
      print('🌐 Base URL from env: ${ApiConstants.baseUrl}');
      print('🌐 요청 URL: $fullUrl');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 중복 확인 응답: ${response.statusCode}');
      print('📦 응답 내용: ${response.body}');
      print('📋 응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _usernameAvailable = data['available'] ?? false;

        if (!_usernameAvailable!) {
          _usernameError = data['message'] ?? '이미 사용중인 사용자명입니다';
        } else {
          _usernameError = '';
        }

        print('✅ 중복 확인 성공: available=${_usernameAvailable}');
      } else {
        print('❌ 서버 오류: ${response.statusCode}');
        print('❌ 오류 내용: ${response.body}');

        _usernameAvailable = null;
        if (response.statusCode == 401) {
          _usernameError = '인증 오류가 발생했습니다';
        } else if (response.statusCode == 404) {
          _usernameError = 'API를 찾을 수 없습니다';
        } else {
          _usernameError = '사용자명 확인 중 오류가 발생했습니다 (${response.statusCode})';
        }
      }
    } catch (e) {
      print('❌ 사용자명 중복 확인 실패: $e');
      _usernameAvailable = null;
      _usernameError = '네트워크 오류가 발생했습니다: ${e.toString()}';
    } finally {
      _isCheckingUsername = false;
      _validateForm();
      notifyListeners();
    }
  }


  // 비밀번호 유효성 검사 메서드
  void validatePassword() {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      _passwordError = '비밀번호를 입력해 주세요.';
    } else if (password.length < 8) {
      _passwordError = '비밀번호는 8자 이상이어야 합니다.';
    } else if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      _passwordError = '비밀번호는 영문을 포함해야 합니다.';
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      _passwordError = '비밀번호는 숫자를 포함해야 합니다.';
    } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _passwordError = '비밀번호는 특수문자를 포함해야 합니다.';
    } else {
      _passwordError = '';
    }

    // 비밀번호가 변경되면 확인 비밀번호도 다시 검사
    if (confirmPasswordController.text.isNotEmpty) {
      validateConfirmPassword();
    }

    _validateForm();
    notifyListeners();
  }

  // 비밀번호 확인 유효성 검사 메서드
  void validateConfirmPassword() {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = '비밀번호 확인을 입력해주세요';
    } else if (password != confirmPassword) {
      _confirmPasswordError = '비밀번호가 일치하지 않습니다';
    } else {
      _confirmPasswordError = '';
    }

    _validateForm();
    notifyListeners();
  }

  // 이름 유효성 검사 메서드
  void validateName() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      _nameError = '이름을 입력해 주세요.';
    } else if (name.length < 2) {
      _nameError = '이름은 2자 이상이어야 합니다.';
    } else if (name.length > 20) {
      _nameError = '이름은 20자 이하여야 합니다.';
    } else if (!RegExp(r'^[가-힣a-zA-Z\s]+$').hasMatch(name)) {
      _nameError = '이름은 한글 또는 영문만 사용할 수 있습니다.';
    } else {
      _nameError = '';
    }

    _validateForm();
    notifyListeners();
  }

  // 이메일 유효성 검사 메서드
  void validateEmail() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _emailError = '이메일을 입력해 주세요.';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _emailError = '올바른 이메일 형식을 입력해 주세요.';
    } else if (email.length > 100) {
      _emailError = '이메일은 100자 이하여야 합니다.';
    } else {
      _emailError = '';
    }

    _validateForm();
    notifyListeners();
  }

  // 전화번호 유효성 검사 메서드
  void validatePhone() {
    final phone = phoneController.text.replaceAll(RegExp(r'[^0-9-]'), '');

    if (phone.isEmpty) {
      _phoneError = '전화번호를 입력해 주세요.';
    } else if (!RegExp(r'^010-?[0-9]{4}-?[0-9]{4}$').hasMatch(phone)) {
      _phoneError = '올바른 휴대폰 번호를 입력해 주세요. (예: 010-1234-5678)';
    } else {
      _phoneError = '';
    }

    _validateForm();
    notifyListeners();
  }

  // 가입코드 유효성 검사 메서드
  void validateSignupCode() {
    final code = signupCodeController.text.trim();

    if (code.isEmpty) {
      _signupCodeError = '가입코드를 입력해주세요';
    } else if (code.length < 6) {
      _signupCodeError = '가입코드는 6자 이상이어야 합니다';
    } else if (code.length > 50) {
      _signupCodeError = '가입코드는 50자 이하여야 합니다';
    } else {
      _signupCodeError = '';
    }

    _validateForm();
    notifyListeners();
  }

  // 전체 폼 유효성 검사 메서드
  void _validateForm() {
    _isFormValid = usernameController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        signupCodeController.text.trim().isNotEmpty &&
        _usernameError.isEmpty &&
        _passwordError.isEmpty &&
        _confirmPasswordError.isEmpty &&
        _nameError.isEmpty &&
        _emailError.isEmpty &&
        _phoneError.isEmpty &&
        _signupCodeError.isEmpty &&
        (_usernameAvailable == true); // 사용자명이 사용 가능해야 함
  }

  // 에러 메시지 초기화 메서드
  void _clearMessages() {
    _errorMessage = '';
    _successMessage = '';
  }

  // 회원가입 처리 메서드
// 폼 초기화 메서드 - 회원가입 성공 후 입력 필드들을 비운다
void clearForm() {
  print('🧹 회원가입 폼 초기화 시작');
  
  // 모든 텍스트 컨트롤러 비우기
  usernameController.clear();
  passwordController.clear();
  confirmPasswordController.clear();
  nameController.clear();
  emailController.clear();
  phoneController.clear();
  signupCodeController.clear();
  
  // 상태 변수들 초기화
  _selectedRole = 0; // 일반 사용자로 초기화
  _usernameAvailable = null; // 사용자명 확인 상태 초기화
  
  // 모든 에러 메시지 초기화
  _usernameError = '';
  _passwordError = '';
  _confirmPasswordError = '';
  _nameError = '';
  _emailError = '';
  _phoneError = '';
  _signupCodeError = '';
  _errorMessage = '';
  _successMessage = '';
  
  // 폼 유효성 상태 초기화
  _isFormValid = false;
  
  print('✅ 회원가입 폼 초기화 완료');
  notifyListeners();
}

// 회원가입 처리 메서드
Future<bool> signup() async {
  print('🚀 SignupProvider.signup() 시작');

  if (_isLoading) {
    print('⚠️ 이미 처리 중입니다');
    return false;
  }

  // 최종 유효성 검사
  validateUsername();
  validatePassword();
  validateConfirmPassword();
  validateName();
  validateEmail();
  validatePhone();
  validateSignupCode();

  if (!_isFormValid) {
    print('❌ 폼 유효성 검사 실패');
    _errorMessage = '입력 정보를 다시 확인해주세요';
    notifyListeners();
    return false;
  }

  _isLoading = true;
  _clearMessages();
  notifyListeners();

  try {
    print('📝 회원가입 요청 데이터 생성');
    final signupRequest = SignupRequest(
      username: usernameController.text.trim(),
      password: passwordController.text,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      role: _selectedRole,
      signupCode: signupCodeController.text.trim(),
    );

    print('📦 요청 데이터: ${signupRequest.toJson()}');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(signupRequest.toJson()),
    );

    print('📡 서버 응답: ${response.statusCode}');
    print('📦 응답 내용: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        print('✅ 회원가입 성공!');
        _successMessage = '회원가입이 완료되었습니다. 로그인 페이지로 이동합니다.';
        _errorMessage = '';
        
        // 🔥 회원가입 성공 후 폼 초기화
        clearForm();
        
        notifyListeners();
        return true;
      } else {
        print('❌ 회원가입 실패: ${data['message']}');
        _errorMessage = data['message'] ?? '회원가입에 실패했습니다';
        notifyListeners();
        return false;
      }
    } else {
      print('❌ 서버 오류: ${response.statusCode}');
      final data = json.decode(response.body);
      _errorMessage = data['message'] ?? '서버 오류가 발생했습니다';
      notifyListeners();
      return false;
    }
  } catch (e) {
    print('❌ 회원가입 처리 중 오류: $e');
    _errorMessage = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
    notifyListeners();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  // 메모리 정리 메서드
  @override
  void dispose() {
    // 컨트롤러들 정리
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    signupCodeController.dispose();

    // 포커스 노드들 정리
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    phoneFocusNode.dispose();
    signupCodeFocusNode.dispose();

    super.dispose();
  }
}