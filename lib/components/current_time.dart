// utils/date_utils.dart
import 'package:intl/intl.dart';

String getCurrentTime() {
  final now = DateTime.now();
  return DateFormat('HH:mm').format(now);
}

String getCurrentDate() {
  try {
    return DateFormat("yyyy.MM.dd", "ko_KR").format(DateTime.now());
  } catch (_) {
    // GitHub Actions 환경을 위해 fallback
    return DateFormat("yyyy.MM.dd").format(DateTime.now());
  }
}
