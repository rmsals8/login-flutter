// lib/core/utils/url_launcher_helper.dart
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<bool> launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('Could not launch $url');
        return false;
      }
    } catch (e) {
      print('Error launching URL: $e');
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