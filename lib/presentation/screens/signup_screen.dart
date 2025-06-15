// lib/presentation/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/signup_provider.dart';
import '../widgets/common/responsive_container.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              _buildHeader(),

              // 회원가입 폼
              ResponsiveContainer(
                child: _buildSignupForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.padding),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            children: [
              // 뒤로가기 버튼
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.go('/login');
                },
              ),
              // 제목
              Expanded(
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // 공간 맞추기용 여백
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '새 계정을 만들어 서비스를 이용해보세요',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeMedium,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            '회원 정보 입력',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '모든 필드는 필수 입력사항입니다.',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // 입력 필드들
          _buildInputFields(),
          const SizedBox(height: 24),

          // 역할 선택
          _buildRoleSelection(),
          const SizedBox(height: 24),

          // 회원가입 버튼
          _buildSignupButton(),

          // 에러/성공 메시지
          _buildMessages(),

          // 로그인으로 돌아가기
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Consumer<SignupProvider>(
      builder: (context, signupProvider, child) {
        return Column(
          children: [
            // 사용자명 (아이디)
            _buildInputField(
              label: '사용자명 (아이디)',
              controller: signupProvider.usernameController,
              onChanged: (value) => signupProvider.validateUsername(),
              errorText: signupProvider.usernameError.isEmpty ? null : signupProvider.usernameError,
              hint: '영문, 숫자 조합 4-20자',
              suffixIcon: signupProvider.isCheckingUsername
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : signupProvider.usernameAvailable == true
                  ? Icon(Icons.check_circle, color: AppColors.success)
                  : signupProvider.usernameAvailable == false
                  ? Icon(Icons.error, color: AppColors.error)
                  : null,
            ),
            const SizedBox(height: 16),

            // 비밀번호
            _buildInputField(
              label: '비밀번호',
              controller: signupProvider.passwordController,
              onChanged: (value) => signupProvider.validatePassword(),
              errorText: signupProvider.passwordError.isEmpty ? null : signupProvider.passwordError,
              obscureText: true,
              hint: '영문, 숫자, 특수문자 조합 8자 이상',
            ),
            const SizedBox(height: 16),

            // 비밀번호 확인
            _buildInputField(
              label: '비밀번호 확인',
              controller: signupProvider.confirmPasswordController,
              onChanged: (value) => signupProvider.validateConfirmPassword(),
              errorText: signupProvider.confirmPasswordError.isEmpty ? null : signupProvider.confirmPasswordError,
              obscureText: true,
              hint: '위에서 입력한 비밀번호를 다시 입력하세요',
            ),
            const SizedBox(height: 16),

            // 이름
            _buildInputField(
              label: '이름',
              controller: signupProvider.nameController,
              onChanged: (value) => signupProvider.validateName(),
              errorText: signupProvider.nameError.isEmpty ? null : signupProvider.nameError,
              hint: '실명을 입력하세요',
            ),
            const SizedBox(height: 16),

            // 이메일
            _buildInputField(
              label: '이메일',
              controller: signupProvider.emailController,
              onChanged: (value) => signupProvider.validateEmail(),
              errorText: signupProvider.emailError.isEmpty ? null : signupProvider.emailError,
              keyboardType: TextInputType.emailAddress,
              hint: 'example@email.com',
            ),
            const SizedBox(height: 16),

            // 전화번호
            _buildInputField(
              label: '전화번호',
              controller: signupProvider.phoneController,
              onChanged: (value) => signupProvider.validatePhone(),
              errorText: signupProvider.phoneError.isEmpty ? null : signupProvider.phoneError,
              keyboardType: TextInputType.phone,
              hint: '010-1234-5678',
            ),
            const SizedBox(height: 16),

            // 가입코드
            _buildInputField(
              label: '가입코드',
              controller: signupProvider.signupCodeController,
              onChanged: (value) => signupProvider.validateSignupCode(),
              errorText: signupProvider.signupCodeError.isEmpty ? null : signupProvider.signupCodeError,
              hint: '관리자에게 받은 가입코드를 입력하세요',
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? errorText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeMedium,
            ),
            errorText: errorText,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Consumer<SignupProvider>(
      builder: (context, signupProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '사용자 역할',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Column(
                children: [
                  RadioListTile<int>(
                    title: const Text('일반 사용자'),
                    subtitle: const Text('기본 사용 권한'),
                    value: 0,
                    groupValue: signupProvider.selectedRole,
                    onChanged: (value) => signupProvider.setRole(value!),
                    activeColor: AppColors.primary,
                  ),
                  Divider(height: 1, color: AppColors.inputBorder),
                  RadioListTile<int>(
                    title: const Text('관리자'),
                    subtitle: const Text('관리자 권한 (승인 필요)'),
                    value: 1,
                    groupValue: signupProvider.selectedRole,
                    onChanged: (value) => signupProvider.setRole(value!),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignupButton() {
    return Consumer<SignupProvider>(
      builder: (context, signupProvider, child) {
        return Container(
          width: double.infinity,
          height: 50,
          margin: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
            onPressed: isLoading || !signupProvider.isFormValid
                ? null
                : () => _handleSignup(signupProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.disabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              '회원가입',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessages() {
    return Consumer<SignupProvider>(
      builder: (context, signupProvider, child) {
        if (signupProvider.errorMessage.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    signupProvider.errorMessage,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
        }

        if (signupProvider.successMessage.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    signupProvider.successMessage,
                    style: TextStyle(color: AppColors.success),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoginLink() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '이미 계정이 있으신가요? ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeMedium,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.go('/login');
            },
            child: Text(
              '로그인',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppDimensions.fontSizeMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignup(SignupProvider signupProvider) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    print('🚀 회원가입 시작');

    try {
      final success = await signupProvider.signup();

      if (success && mounted) {
        print('✅ 회원가입 성공');

        // 성공 메시지를 보여주고 잠시 후 로그인 페이지로 이동
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      print('❌ 회원가입 처리 중 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}