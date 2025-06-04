// lib/core/utils/url_launcher_helper.dart
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class UrlLauncherHelper {
  static Future<bool> launchURL(String url) async {
    print('🚀 URL 실행 시도: $url');
    
    try {
      final uri = Uri.parse(url);
      print('📍 파싱된 URI: $uri');
      
      // 🔥 모바일에서 강제로 외부 브라우저 사용
      if (!kIsWeb) {
        print('📱 모바일: 외부 브라우저 강제 실행');
        
        // canLaunchUrl 확인
        final canLaunch = await canLaunchUrl(uri);
        print('🔍 URL 실행 가능 여부: $canLaunch');
        
        if (canLaunch) {
          final result = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication, // 외부 앱 강제 사용
          );
          print('✅ URL 실행 결과: $result');
          return result;
        } else {
          print('❌ URL을 실행할 수 없음 - 브라우저 앱이 없을 수 있음');
          
          // 🔥 대체 방법: 플랫폼 기본 브라우저로 시도
          try {
            return await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );
          } catch (e) {
            print('💥 대체 방법도 실패: $e');
            return false;
          }
        }
      } else {
        // 웹에서는 새 탭으로 열기
        print('🌐 웹: 새 탭으로 열기');
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('💥 URL 실행 오류: $e');
      return false;
    }
  }

  static Future<bool> launchKakaoLogin() async {
    const url = 'https://3.37.89.76/api/auth/kakao/login';
    return await launchURL(url);
  }

  static Future<bool> launchNaverLogin() async {
    const url = 'https://3.37.89.76/api/auth/naver/login';
    return await launchURL(url);
  }
}