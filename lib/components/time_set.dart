String makeFileName(String type, String name) {
  final now = DateTime.now();

  final y = now.year.toString();
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');

  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  final ss = now.second.toString().padLeft(2, '0');

  final datePart = "$y$m$d";
  final timePart = "${hh}${mm}${ss}";

  return "${name}_${type}_${datePart}_${timePart}.jpg";
}
