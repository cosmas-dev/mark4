import 'package:mark4/dual/dual_analysis.dart';
import 'package:path/path.dart' as p;

String _two(int n) => n.toString().padLeft(2, '0');

String _escape(dynamic value) {
  final text = (value ?? '').toString();
  final escaped = text.replaceAll('"', '""');
  if (escaped.contains(',') ||
      escaped.contains('\n') ||
      escaped.contains('"')) {
    return '"$escaped"';
  }
  return escaped;
}

String _date(Map<String, dynamic> e) {
  final d = DateTime.tryParse(e['createdAt']?.toString() ?? '');
  if (d == null) return '';
  return '${d.year}-${_two(d.month)}-${_two(d.day)} '
      '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';
}

String buildDualCsv(List<Map<String, dynamic>> rawRows) {
  final buffer = StringBuffer();

  buffer.writeln(
    'Date,UserId,SampleType,StripType,'
    'Ctrl(L) Intensity,FluA Intensity,RSV Intensity,'
    'Ctrl(R) Intensity,FluB Intensity,AdV Intensity,CoV Intensity,'
    'FluA Result,RSV Result,FluB Result,AdV Result,CoV Result,CaptureImage',
  );

  for (final e in rawRows) {
    final result =
        e['analysisResult'] is Map ? e['analysisResult'] as Map : null;
    final imagePath = e['imagePath']?.toString() ?? '';

    String status(String name) {
      final v = dualAnalyteStatus(result, name);
      return '${v[0].toUpperCase()}${v.substring(1)}';
    }

    buffer.writeln(
      [
        _date(e),
        e['userId'] ?? '',
        e['sampleType'] ?? '',
        'Dual',
        dualCtrlMultiple(result, 'left'),
        dualIntensityMultiple(result, 'FluA'),
        dualIntensityMultiple(result, 'RSV'),
        dualCtrlMultiple(result, 'right'),
        dualIntensityMultiple(result, 'FluB'),
        dualIntensityMultiple(result, 'AdV'),
        dualIntensityMultiple(result, 'CoV'),
        status('FluA'),
        status('RSV'),
        status('FluB'),
        status('AdV'),
        status('CoV'),
        imagePath.isNotEmpty ? 'images/${p.basename(imagePath)}' : '',
      ].map(_escape).join(','),
    );
  }

  return buffer.toString();
}
