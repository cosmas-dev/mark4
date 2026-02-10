class RunTestRow {
  final String id;
  final DateTime date;
  final String userName;
  final String item;
  final String result;
  bool selected;

  RunTestRow({
    required this.id,
    required this.date,
    required this.userName,
    required this.item,
    required this.result,
    this.selected = false,
  });
}
