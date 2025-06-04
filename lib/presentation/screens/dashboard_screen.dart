// lib/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/login_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/responsive_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _handleLogout() async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      '정말 로그아웃하시겠습니까?',
      title: '로그아웃',
      confirmText: '로그아웃',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      print('🚪 로그아웃 시작');
      
      final authProvider = context.read<AuthProvider>();
      final loginProvider = context.read<LoginProvider>();
      
      // 🔥 AuthProvider에서 로그아웃 처리
      await authProvider.logout();
      print('✅ AuthProvider 로그아웃 완료');
      
      // 🔥 LoginProvider 초기화 (입력 필드 등 클리어)
      loginProvider.onLogout();
      print('✅ LoginProvider 초기화 완료');
      
      // 로그인 화면으로 이동
      context.go('/login');
      print('🚀 로그인 화면으로 이동 완료');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: AppStrings.dashboard,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: AppDimensions.maxAppWidth,
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 사용자 환영 메시지
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                
                // 통계 카드들
                _buildStatsContainer(),
                const SizedBox(height: 24),
                
                // 빠른 작업 영역
                _buildActionsContainer(),
                const SizedBox(height: 40),
                
                // 푸터
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final username = user?.username ?? '사용자';
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                AppStrings.dashboard,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeLarge,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: '${AppStrings.welcome}, '),
                    TextSpan(
                      text: '${username}님!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsContainer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return _buildStatsRow([
          _buildStatCard('계정 상태', '정상', AppColors.success),
          _buildStatCard('마지막 로그인', DateHelper.getFormattedLoginTime(), AppColors.textPrimary),
          _buildStatCard('로그인 방식', _getLoginMethodText(user?.loginType ?? 'normal'), AppColors.textPrimary),
        ]);
      },
    );
  }

  Widget _buildStatsRow(List<Widget> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: stats.map((stat) => 
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: stat,
              ),
            ).toList(),
          );
        } else {
          return Row(
            children: stats.map((stat) => 
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: stat,
                ),
              ),
            ).toList(),
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeMedium,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '빠른 작업',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE),
          foregroundColor: const Color(0xFFE03131),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: 8),
            Text(
              AppStrings.logout,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeRegular,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            '환경: development | 클라우드타입으로 배포됨',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeMedium,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              AppStrings.poweredByCloudtype,
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppDimensions.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLoginMethodText(String loginType) {
    switch (loginType) {
      case 'kakao':
        return '카카오 로그인';
      case 'naver':
        return '네이버 로그인';
      default:
        return '일반 로그인';
    }
  }
}