const dualAnalyteOrder = ['FluA', 'RSV', 'FluB', 'AdV', 'CoV'];

bool isDualResult(Map? result) {
  final kit = result?['kit'];
  return kit is Map && kit['type'] == 'dual_line';
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

Map<String, dynamic> dualVerdict(Map? result) => _asMap(result?['verdict']);

String dualAnalyteStatus(Map? result, String name) {
  final analytes = _asMap(dualVerdict(result)['analytes']);
  return analytes[name]?.toString() ?? 'invalid';
}

double? dualIntensityMultiple(Map? result, String name) {
  final strips = result?['strips'];
  if (strips is! List) return null;
  for (final s in strips) {
    final lines = _asMap(s)['lines'];
    if (lines is! List) continue;
    for (final l in lines) {
      final line = _asMap(l);
      if (line['name'] == name) {
        final v = line['intensity_vs_threshold'];
        return v is num ? v.toDouble() : null;
      }
    }
  }
  return null;
}

double? dualCtrlMultiple(Map? result, String stripId) {
  final strips = result?['strips'];
  if (strips is! List) return null;
  for (final s in strips) {
    final strip = _asMap(s);
    if (strip['id'] == stripId) {
      final v = _asMap(strip['control'])['intensity_vs_threshold'];
      return v is num ? v.toDouble() : null;
    }
  }
  return null;
}

String dualResultSummary(Map? result) {
  final verdict = dualVerdict(result);
  if (verdict.isEmpty) return '-';

  if (verdict['status'] == 'invalid') {
    return 'Invalid: ${verdict['reason'] ?? '-'}';
  }

  final positives = dualAnalyteOrder.where(
    (n) => dualAnalyteStatus(result, n) == 'positive',
  );
  if (positives.isEmpty) return 'Negative';

  final coinfection = verdict['coinfection'] == true ? ' (Co-infection)' : '';
  return 'Positive: ${positives.join(', ')}$coinfection';
}
