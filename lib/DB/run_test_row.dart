class RunTestRow {
  final String id;
  final DateTime date;
  final String userId;
  final String item;
  final String result;
  bool selected;

  RunTestRow({
    required this.id,
    required this.date,
    required this.userId,
    required this.item,
    required this.result,
    this.selected = false,
  });
}
