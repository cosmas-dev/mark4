import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mark4/DB/run_test_json_store.dart';

class ResultSingle extends StatefulWidget {
  final String userName,
      age,
      gender,
      sampleType,
      selectedItem,
      imagePath,
      shutterSpeed,
      ip;
  final Map<String, dynamic>? analysisResult;

  const ResultSingle({
    super.key,
    required this.shutterSpeed,
    required this.ip,
    required this.userName,
    required this.gender,
    required this.sampleType,
    required this.selectedItem,
    required this.age,
    required this.imagePath,
    this.analysisResult,
  });

  @override
  State<ResultSingle> createState() => _ResultSingleState();
}

class _ResultSingleState extends State<ResultSingle> {
  final store = RunTestJsonStore();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveResultOnce();
  }

  Future<void> _saveResultOnce() async {
    if (_saved) return;
    _saved = true;

    try {
      await store.save(
        shutterSpeed: widget.shutterSpeed,
        name: widget.userName,
        age: widget.age,
        gender: widget.gender,
        item: widget.selectedItem,
        sampleType: widget.sampleType,
        imagePath: widget.imagePath,
        result: _buildResultString(),
      );
    } catch (e) {
      debugPrint('결과 저장 실패: $e');
    }
  }

  String _buildResultString() {
    final grade = _readText(['grade', 'verdict', 'result']);
    final status = _readText(['status', 'state']);

    if (grade != '-') {
      return status == '-'
          ? grade.toUpperCase()
          : '${grade.toUpperCase()} / ${status.toUpperCase()}';
    }
    return 'Analysis Pending';
  }

  dynamic _lookup(String key) {
    return _lookupDeep(widget.analysisResult, key);
  }

  dynamic _lookupDeep(dynamic node, String key) {
    if (node == null) return null;

    if (node is Map) {
      if (node.containsKey(key)) {
        final value = node[key];
        if (value is! Map && value is! List) return value;
      }

      for (final value in node.values) {
        final found = _lookupDeep(value, key);
        if (found != null) return found;
      }
    }

    if (node is List) {
      for (final value in node) {
        final found = _lookupDeep(value, key);
        if (found != null) return found;
      }
    }

    return null;
  }

  String _readText(List<String> keys) {
    for (final key in keys) {
      final value = _lookup(key);
      if (value == null || value is Map || value is List) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '-';
  }

  bool? _readBool(List<String> keys) {
    for (final key in keys) {
      final value = _lookup(key);
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (['true', 'yes', 'y', '1'].contains(normalized)) return true;
        if (['false', 'no', 'n', '0'].contains(normalized)) return false;
      }
    }
    return null;
  }

  String _formatBool(bool? value) {
    if (value == null) return '-';
    return value ? 'YES' : 'NO';
  }

  Color _gradeColor(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('positive')) return const Color(0xFFE85D5D);
    if (normalized.contains('negative')) return const Color(0xFF227BFF);
    if (normalized.contains('invalid') || normalized.contains('error')) {
      return const Color(0xFF6B6B6B);
    }
    return const Color(0xFF2B478B);
  }

  @override
  Widget build(BuildContext context) {
    final grade = _readText(['grade', 'verdict', 'result']);
    final status = _readText(['status', 'state']);
    final reason = _readText(['reason', 'error']);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Test Result',
          style: TextStyle(
            color: Color(0xFF1A2A4A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFEFF3F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryCard(grade, status, reason),
                    const SizedBox(height: 16),
                    _capturedImage(),
                    const SizedBox(height: 16),
                    _patientCard(),
                  ],
                ),
              ),
            ),
            _bottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String grade, String status, String reason) {
    final color = _gradeColor(grade == '-' ? status : grade);
    final hasAnalysis = widget.analysisResult != null;
    final retestRecommended = _readBool([
      'retest_recommended',
      'retestRecommended',
      'retest',
    ]);
    final typeMismatchWarning = _readBool([
      'type_mismatch_warning',
      'typeMismatchWarning',
      'type_warning',
    ]);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                hasAnalysis ? 'Analysis Completed' : 'Analysis Pending',
                style: const TextStyle(
                  color: Color(0xFF2B478B),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            grade == '-' ? 'No Result' : grade.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 14),
          _resultLine('Status', status == '-' ? '-' : status.toUpperCase()),
          _resultLine('Retest Recommended', _formatBool(retestRecommended)),
          _resultLine(
            'Type Mismatch Warning',
            _formatBool(typeMismatchWarning),
          ),
          if (reason != '-') _resultLine('Reason', reason),
        ],
      ),
    );
  }

  Widget _resultLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF1A2A4A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _capturedImage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
          // width: double.infinity,
          height: 1200,
          errorBuilder: (context, error, stackTrace) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('이미지를 불러올 수 없습니다.')),
            );
          },
        ),
      ),
    );
  }

  Widget _patientCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sample Information',
            style: TextStyle(
              color: Color(0xFF1A2A4A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('User ID', widget.userName),
          _infoRow('Age / Gender', '${widget.age} / ${widget.gender}'),
          _infoRow('Item', widget.selectedItem),
          _infoRow('Sample Type', widget.sampleType),
          _infoRow('Test Time', DateTime.now().toString().split('.').first),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xFF1A2A4A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
            child: _actionButton(
              text: 'Back',
              color: const Color(0xFF6B6B6B),
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionButton(
              text: 'Completed',
              color: const Color(0xFF227BFF),
              onTap:
                  () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
