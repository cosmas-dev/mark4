dynamic _path(Map? result, List<String> keys) {
  dynamic node = result;
  for (final key in keys) {
    if (node is Map && node.containsKey(key)) {
      node = node[key];
    } else {
      return null;
    }
  }
  return node;
}

// 'positive' / 'negative' / 'invalid'.
// 장비가 invalid를 알려주거나 C 라인이 없으면 invalid,
// 그 외에는 T 라인 검출 여부로 판정한다.
String singleVerdict(Map? result) {
  if (_path(result, ['verdict', 'status']) == 'invalid') return 'invalid';

  final control = _path(result, ['control', 'detected']);
  final test = _path(result, ['test', 'detected']);
  if (control != true || test is! bool) return 'invalid';

  return test ? 'positive' : 'negative';
}

// 장비가 보낸 강도 값을 그대로 반환한다. line은 'control' 또는 'test'.
// intensity_fixed_scale이 없는 이전 기록은 raw_metrics 값을 사용한다.
num? singleIntensity(Map? result, String line) {
  final v = _path(result, [line, 'intensity_fixed_scale']);
  if (v is num) return v;

  final legacy = _path(result, [
    'raw_metrics',
    line == 'control' ? 'c_int_vs_lod' : 't_int_vs_lod',
  ]);
  return legacy is num ? legacy : null;
}
