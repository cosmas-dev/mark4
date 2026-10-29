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

String dualInvalidMessage(String? reason) {
  switch (reason) {
    case 'CONTROL_NOT_DETECTED':
      return '대조선(Control)이 검출되지 않았습니다. 재측정해 주세요.';
    case 'DIVIDER_NOT_FOUND':
      return '카트리지 장착 불량 또는 이물이 의심됩니다. 재장착 후 재측정해 주세요.';
    case 'ANCHOR_PAIR_MISMATCH':
      return '좌/우 대조선 높이가 일치하지 않습니다. 재측정해 주세요.';
    case 'PROFILE_TOO_NOISY':
      return '노이즈가 너무 큽니다. 재측정해 주세요.';
    case 'ROI_INVALID':
      return '분석 영역이 올바르지 않습니다. 재측정해 주세요.';
    case 'ANALYSIS_FAILED':
      return '분석에 실패했습니다. 장비가 Dual 분석을 지원하는지 확인해 주세요.';
    default:
      return '판정할 수 없습니다. 재측정해 주세요.${reason == null ? '' : ' ($reason)'}';
  }
}
