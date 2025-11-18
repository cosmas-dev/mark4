// utils/date_utils.dart
import 'package:intl/intl.dart';

String getCurrentTime() {
  final now = DateTime.now();
  return DateFormat('HH:mm').format(now);
}

String getCurrentDate() {
  final now = DateTime.now();
  return DateFormat('yyyy. MM. dd. EEE', 'en_EN').format(now);
}
