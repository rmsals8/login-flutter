// lib/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/login_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/responsive_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  // 🔥 로딩 상태 관리
  bool _isLoading = false;

  // 🔥 완전히 새로 작성된 로그아웃 처리 메소드
  Future<void> _handleLogout() async {
    print('🚪 대시보드 로그아웃 시작');
    
    // 사용자에게 확인 받기
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      '정말 로그아웃하시겠습니까?\n\n소셜 로그인을 사용하셨다면 해당 플랫폼에서도 로그아웃됩니다.',
      title: '로그아웃',
      confirmText: '로그아웃',
      cancelText: '취소',
    );

    if (!confirmed) {
      print('로그아웃 취소됨');
      return;
    }

    if (!mounted) return;

    // 로딩 상태 시작
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 로그아웃 처리 시작');
      
      final authProvider = context.read<AuthProvider>();
      final loginProvider = context.read<LoginProvider>();
      
      // 🔥 AuthProvider에서 완전 로그아웃 처리 (소셜 로그아웃 포함)
      await authProvider.logout();
      print('✅ AuthProvider 완전 로그아웃 완료');
      
      // 🔥 LoginProvider 초기화
      loginProvider.onLogout();
      print('✅ LoginProvider 초기화 완료');
      
      // 성공 메시지 표시 (짧게)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '로그아웃되었습니다',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // 잠시 대기 후 로그인 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        context.go('/login');
        print('🚀 로그인 화면으로 이동 완료');
      }
      
    } catch (error) {
      print('❌ 로그아웃 처리 중 오류: $error');
      
      // 에러가 발생해도 로그인 화면으로 이동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '로그아웃 중 오류가 발생했지만 로그아웃되었습니다',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 에러가 발생해도 로그인 화면으로 이동
        context.go('/login');
      }
    } finally {
      // 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🔥 강력한 로그아웃 (소셜 계정 연결까지 끊기) - 선택적 기능
  Future<void> _handleCompleteLogout() async {
    print('🔗 완전 로그아웃 (연결 끊기 포함) 시작');
    
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      '소셜 로그인 계정과의 연결을 완전히 끊으시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 다시 로그인하려면 소셜 로그인을 다시 연동해야 합니다.',
      title: '계정 연결 끊기',
      confirmText: '연결 끊기',
      cancelText: '취소',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      
      // 소셜 계정 연결 끊기
      await authProvider.unlinkSocialAccounts();
      print('✅ 소셜 계정 연결 끊기 완료');
      
      // 일반 로그아웃도 함께 수행
      await _handleLogout();
      
    } catch (error) {
      print('❌ 계정 연결 끊기 실패: $error');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '계정 연결 끊기에 실패했습니다: $error',
              style: const TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          
          // 🔥 로그아웃 버튼들 (일반 로그아웃과 완전 로그아웃)
          _buildLogoutButtons(),
        ],
      ),
    );
  }

  // 🔥 로그아웃 버튼들을 빌드하는 새로운 메소드
  Widget _buildLogoutButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final isSocialLogin = user?.loginType != 'normal';
        
        return Column(
          children: [
            // 일반 로그아웃 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEBEE),
                  foregroundColor: const Color(0xFFE03131),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE03131)),
                      ),
                    )
                  : Row(
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
            ),
            
            // 🔥 소셜 로그인 사용자에게만 완전 로그아웃 버튼 표시
            if (isSocialLogin) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleCompleteLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE03131),
                    side: const BorderSide(color: Color(0xFFE03131)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link_off, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_getLoginMethodText(user?.loginType ?? 'normal')} 연결 끊기',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeRegular,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 🔥 소셜 로그인 안내 텍스트
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '소셜 로그인 안내',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 일반 로그아웃: ${_getLoginMethodText(user?.loginType ?? 'normal')}에서 로그아웃되고 우리 서비스에서도 로그아웃됩니다.\n'
                      '• 연결 끊기: ${_getLoginMethodText(user?.loginType ?? 'normal')}과의 연결을 완전히 끊습니다. (되돌릴 수 없음)',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeSmall,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
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