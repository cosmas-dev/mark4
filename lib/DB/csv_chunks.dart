/// CSV 한 파일에 담는 최대 데이터 수. 넘으면 새 파일로 이어서 저장한다.
const int csvMaxRows = 10000;

/// 기록을 최신순으로 정렬한 뒤 [maxRows]개씩 나눈다.
/// (가장 최신 10000개, 그다음 10000개, ...)
List<List<Map<String, dynamic>>> splitRowsForCsv(
  List<Map<String, dynamic>> raw, {
  int maxRows = csvMaxRows,
}) {
  final sorted = [...raw]..sort(
    (a, b) => DateTime.parse(
      b['createdAt'],
    ).compareTo(DateTime.parse(a['createdAt'])),
  );

  final chunks = <List<Map<String, dynamic>>>[];
  for (var i = 0; i < sorted.length; i += maxRows) {
    final end = i + maxRows < sorted.length ? i + maxRows : sorted.length;
    chunks.add(sorted.sublist(i, end));
  }
  return chunks;
}
