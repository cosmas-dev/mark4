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

// 장비가 보낸 강도(intensity_fixed_scale)를 그대로 반환한다.
// 외부공개 키트는 이 값을 보내지 않으므로 null이다.
num? dualIntensity(Map? result, String name) {
  final strips = result?['strips'];
  if (strips is! List) return null;
  for (final s in strips) {
    final lines = _asMap(s)['lines'];
    if (lines is! List) continue;
    for (final l in lines) {
      final line = _asMap(l);
      if (line['name'] == name) {
        final v = line['intensity_fixed_scale'];
        return v is num ? v : null;
      }
    }
  }
  return null;
}

num? dualCtrlIntensity(Map? result, String stripId) {
  final strips = result?['strips'];
  if (strips is! List) return null;
  for (final s in strips) {
    final strip = _asMap(s);
    if (strip['id'] == stripId) {
      final v = _asMap(strip['control'])['intensity_fixed_scale'];
      return v is num ? v : null;
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
