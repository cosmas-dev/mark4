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
      return 'Control line not detected. Check that the reader kit setting matches the cartridge, then retest.';
    case 'DIVIDER_NOT_FOUND':
      return 'Cartridge divider not found. Reinsert the cartridge and retest.';
    case 'ANCHOR_PAIR_MISMATCH':
      return 'Left and right control lines do not match. Please retest.';
    case 'PROFILE_TOO_NOISY':
      return 'Signal is too noisy. Please retest.';
    case 'ROI_INVALID':
      return 'Invalid analysis region. Please retest.';
    case 'ANALYSIS_FAILED':
      return 'Analysis failed. Check that the reader supports this kit.';
    default:
      return 'Unable to judge. Please retest.${reason == null ? '' : ' ($reason)'}';
  }
}

String dualWarningMessage(Map warning) {
  final lines = warning['lines'];
  final names = lines is List ? lines.join(' + ') : '';
  switch (warning['code']) {
    case 'CROSSREACT_SUSPECT':
      return '$names both positive: co-infection, or cross-reaction from the stronger line. Consider a diluted retest.';
    default:
      return warning['code']?.toString() ?? '';
  }
}
