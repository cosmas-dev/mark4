/// CSV 한 파일에 담는 최대 데이터 수. 넘으면 새 파일로 이어서 저장한다.
const int csvMaxRows = 10000;

/// 기록을 오래된 순으로 정렬한 뒤 [maxRows]개씩 나눈다.
/// (1~10000, 10001~20000, ...)
List<List<Map<String, dynamic>>> splitRowsForCsv(
  List<Map<String, dynamic>> raw, {
  int maxRows = csvMaxRows,
}) {
  final sorted = [...raw]..sort(
    (a, b) => DateTime.parse(
      a['createdAt'],
    ).compareTo(DateTime.parse(b['createdAt'])),
  );

  final chunks = <List<Map<String, dynamic>>>[];
  for (var i = 0; i < sorted.length; i += maxRows) {
    final end = i + maxRows < sorted.length ? i + maxRows : sorted.length;
    chunks.add(sorted.sublist(i, end));
  }
  return chunks;
}
