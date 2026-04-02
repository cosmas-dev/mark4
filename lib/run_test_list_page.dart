import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mark4/DB/run_test_json_store.dart';
import 'package:mark4/DB/run_test_row.dart';
import 'package:mark4/components/current_time.dart';

class RunTestListPage extends StatefulWidget {
  const RunTestListPage({super.key});

  @override
  State<RunTestListPage> createState() => _RunTestListPageState();
}

class _RunTestListPageState extends State<RunTestListPage> {
  final store = RunTestJsonStore();
  List<RunTestRow> rows = [];
  bool headerChecked = false;

  int page = 0;
  final int pageSize = 9;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Directory? findUsbDirectory() {
    const baseDirs = ['/media/cosmas', '/run/media/cosmas'];

    for (final base in baseDirs) {
      final dir = Directory(base);
      if (!dir.existsSync()) continue;

      final subDirs = dir.listSync().whereType<Directory>().toList();

      if (subDirs.isNotEmpty) {
        return subDirs.first; // 첫 번째 USB 사용
      }
    }
    return null;
  }

  String buildCsv(List<RunTestRow> rows) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Date,Name,Item,Result');

    for (final r in rows) {
      final date =
          '${r.date.year}-${_two(r.date.month)}-${_two(r.date.day)} '
          '${_two(r.date.hour)}:${_two(r.date.minute)}:${_two(r.date.second)}';

      buffer.writeln('$date,${r.userName},${r.item},${r.result}');
    }

    return buffer.toString();
  }

  List<RunTestRow> get pagedRows {
    final start = page * pageSize;
    return rows.skip(start).take(pageSize).toList();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final totalPages = (rows.length / pageSize).ceil().clamp(1, 999);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "     ${getCurrentTime()}     ${getCurrentDate()}",
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Image.asset('images/homeButton.png', scale: 4),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // ✅ 테이블 카드 (두번째 스샷 핵심)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _tableCard(),
            ),
          ),

          const SizedBox(height: 20),

          // ✅ 페이지네이션 카드 (두번째 스샷처럼)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _paginationBar(totalPages),
          ),

          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: _bottomButtons(),
    );
  }

  // ---------------- 테이블 카드 ----------------

  Widget _tableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _header(), // 헤더도 카드 상단 라운드 포함
          const Divider(height: 1),

          Expanded(
            child:
                rows.isEmpty
                    ? const Center(
                      child: Text(
                        'No Data',
                        style: TextStyle(color: Colors.black54, fontSize: 25),
                      ),
                    )
                    : ListView.separated(
                      itemCount: pagedRows.length,
                      itemBuilder: (_, i) => _row(pagedRows[i]),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E8E8E), Color(0xFF5F5F5F)],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Center(
              child: Checkbox(
                value: headerChecked,
                onChanged: (v) {
                  setState(() {
                    headerChecked = v!;
                    // ✅ 현재 페이지 전체 선택/해제
                    for (final row in pagedRows) {
                      row.selected = headerChecked;
                    }
                  });
                },
              ),
            ),
          ),
          const _HeaderCell('Date'),
          const _HeaderCell('Name'),
          const _HeaderCell('Item'),
          const _HeaderCell('Result'),
        ],
      ),
    );
  }

  Widget _row(RunTestRow row) {
    return Container(
      height: 58,
      color: row.selected ? const Color(0xFFDFF5F3) : Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Center(
              child: Checkbox(
                value: row.selected,
                onChanged: (v) {
                  setState(() {
                    for (final r in rows) {
                      if (r.id == row.id) {
                        r.selected = v!;
                      }
                    }
                    headerChecked = pagedRows.every((r) => r.selected);
                  });
                },
              ),
            ),
          ),
          _Cell(_formatDate(row.date)),
          _Cell(row.userName),
          _Cell(row.item),
          _Cell(row.result),
        ],
      ),
    );
  }

  // ---------------- 페이지네이션 바 ----------------

  Widget _paginationBar(int totalPages) {
    return Row(
      children: [
        const SizedBox(width: 10),
        _pageBtn(Icons.chevron_left, page > 0, () {
          setState(() => page--);
        }),
        Expanded(
          child: Center(
            child: Text(
              '${page + 1}/$totalPages',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30),
            ),
          ),
        ),
        _pageBtn(Icons.chevron_right, page < totalPages - 1, () {
          setState(() => page++);
        }),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 150,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: Icon(icon, size: 40),
        ),
      ),
    );
  }

  Widget _bottomButtons() {
    final Size size = MediaQuery.of(context).size;
    return Container(
      height: 200,
      width: size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () {
                // exportAllToUsb();
                _confirmExportAll();
              },
              child: Container(
                color: const Color(0xFF6B6B6B),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("images/holder_icon.png", scale: 3),
                      const SizedBox(height: 4),
                      Text(
                        "All Copy",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // _bottomButton("Stop", Icons.close, const Color(0xFFE83C3C), () {}),
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () {
                setState(() {
                  // exportSelectedToUsb();
                  _confirmExportSelected();
                });
              },
              child: Container(
                color: const Color(0xFF227BFF),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('images/start_icon.png', scale: 3),
                      const SizedBox(height: 10),
                      Text(
                        "Sel Copy",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: _deleteSelected, // ✅ 실제 삭제 연결
              child: Container(
                color: Colors.red,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('images/start_icon.png', scale: 3),
                      const SizedBox(height: 10),
                      const Text(
                        "Delete",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    final raw = await store.readAll();
    rows = [];

    for (final e in raw) {
      rows.add(
        RunTestRow(
          id: e['id'],
          date: DateTime.parse(e['createdAt']),
          userName: e['userName'] ?? 'Unknown',
          // age: e['age'] ?? 'Unknown',
          // gender: e['gender'] ?? 'Unknown',
          item: e['item'] ?? 'Unknown',
          result: e['result'] ?? '0 ng/mL',
        ),
      );
    }

    setState(() {});
  }

  // ---------------- USB 전체 저장 ----------------

  Future<void> exportAllToUsb() async {
    if (rows.isEmpty) {
      _showSnack('No data to save');
      return;
    }

    final usbDir = findUsbDirectory();
    if (usbDir == null) {
      _showSnack('USB not connected');
      return;
    }

    final fileName =
        'run_test_ALL_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${usbDir.path}/$fileName');

    final csv = buildCsv(rows);
    await file.writeAsString(csv, flush: true);

    _showSaveCompletedDialog();
  }

  void _confirmExportAll() {
    if (rows.isEmpty) {
      _showSnack('No data to save');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4), // dim 처리
      builder: (context) {
        return Center(
          child: Container(
            width: 600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Save all data to the\nconnected USB?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2A4A),
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    // YES 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await exportAllToUsb(); // ✅ 전체 CSV 저장
                        },
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF2FD3E3), Color(0xFF22B8D6)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'YES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // NO 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFF5A5A), Color(0xFFE83C3C)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'NO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- Export to USB ----------------

  Future<void> exportSelectedToUsb() async {
    final selected = rows.where((r) => r.selected).toList();

    if (selected.isEmpty) {
      _showSnack('No selected items to save');
      return;
    }

    final usbDir = findUsbDirectory();
    if (usbDir == null) {
      _showSnack('USB not connected');
      return;
    }

    final fileName = 'run_test_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${usbDir.path}/$fileName');

    final csv = buildCsv(selected);
    await file.writeAsString(csv, flush: true);

    _showSaveCompletedDialog();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _confirmExportSelected() {
    final selected = rows.where((r) => r.selected).toList();

    if (selected.isEmpty) {
      _showSnack('No selected items to save');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4), // ✅ dim 처리
      builder: (context) {
        return Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Save selected data to the\nconnected USB?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2A4A),
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    // YES
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await exportSelectedToUsb();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2FD3E3), Color(0xFF22B8D6)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'YES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // NO
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5A5A), Color(0xFFE83C3C)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'NO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- 저장 완료 팝업 ----------------
  void _showSaveCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Save completed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2A4A),
                  ),
                ),
                const SizedBox(height: 24),

                // OK 버튼
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2FD3E3), Color(0xFF22B8D6)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- Actions ----------------

  Future<void> _deleteSelected() async {
    final ids = rows.where((r) => r.selected).map((r) => r.id).toSet().toList();
    await store.deleteByIds(ids);
    // 페이지 범위가 넘어가면 0으로
    if (page > 0 && (rows.length - ids.length) <= page * pageSize) page = 0;
    await _load();
  }

  // ---------------- utils ----------------

  String _formatDate(DateTime d) {
    return '${d.year}-${_two(d.month)}-${_two(d.day)}\n'
        '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

// ---------------- Small widgets ----------------
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          height: 1.2,
          color: Colors.black87,
        ),
      ),
    );
  }
}
