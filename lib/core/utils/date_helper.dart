// lib/core/utils/date_helper.dart
import 'package:intl/intl.dart';

class DateHelper {
  static String formatToKorean(DateTime dateTime) {
    return DateFormat('yyyy년 M월 d일 HH:mm').format(dateTime);
  }

  static String formatToKoreanShort(DateTime dateTime) {
    return DateFormat('M월 d일 HH:mm').format(dateTime);
  }

  static String getCurrentTimeString() {
    return formatToKorean(DateTime.now());
  }

  static String getFormattedLoginTime() {
    return formatToKorean(DateTime.now());
  }
}