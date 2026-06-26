import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mark4/DB/run_test_json_store.dart';

class ResultSingle extends StatefulWidget {
  final String userId, sampleType, selectedItem, imagePath, shutterSpeed, ip;
  final Map<String, dynamic>? analysisResult;

  const ResultSingle({
    super.key,
    required this.shutterSpeed,
    required this.ip,
    required this.userId,
    required this.sampleType,
    required this.selectedItem,
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
        userId: widget.userId,
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
    final ratio = _readNumber(['t_c_ratio', 'tc_ratio', 'ct_ratio']);
    if (grade != '-') {
      return ratio == null ? grade : '$grade / T/C ${ratio.toStringAsFixed(3)}';
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

  num? _readNumber(List<String> keys) {
    for (final key in keys) {
      final value = _lookup(key);
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
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
                    _metricsGrid(),
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
          const SizedBox(height: 8),
          Text(
            'Status: $status',
            style: const TextStyle(fontSize: 17, color: Color(0xFF1A2A4A)),
          ),
          if (reason != '-') ...[
            const SizedBox(height: 6),
            Text(
              'Reason: $reason',
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B6B6B)),
            ),
          ],
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
          fit: BoxFit.contain,
          width: double.infinity,
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

  Widget _metricsGrid() {
    final tSnr = _readNumber(['t_snr']);
    final cSnr = _readNumber(['c_snr']);
    final ratio = _readNumber(['t_c_ratio', 'tc_ratio', 'ct_ratio']);
    final duration = _readNumber(['duration_ms']);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _metricTile('T SNR', tSnr?.toStringAsFixed(2) ?? '-'),
        _metricTile('C SNR', cSnr?.toStringAsFixed(2) ?? '-'),
        _metricTile('T/C Ratio', ratio?.toStringAsFixed(3) ?? '-'),
        _metricTile(
          'Duration',
          duration == null ? '-' : '${duration.toInt()} ms',
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE5F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A2A4A),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
          _infoRow('User ID', widget.userId),
          _infoRow('Item', widget.selectedItem),
          _infoRow('Sample Type', widget.sampleType),
          _infoRow('Shutter', widget.shutterSpeed),
          _infoRow('Kit ID', _readText(['kit_id'])),
          _infoRow('History ID', _readText(['id', 'history_id'])),
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
