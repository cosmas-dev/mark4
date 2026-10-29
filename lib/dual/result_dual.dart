import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mark4/dual/dual_analysis.dart';
import 'package:mark4/single/result_single.dart';

class ResultDual extends StatelessWidget {
  final String userId, sampleType, selectedItem, imagePath, shutterSpeed, ip;
  final String? analysisPlotPath;
  final Map<String, dynamic>? analysisResult;

  const ResultDual({
    super.key,
    required this.shutterSpeed,
    required this.ip,
    required this.userId,
    required this.sampleType,
    required this.selectedItem,
    required this.imagePath,
    this.analysisPlotPath,
    this.analysisResult,
  });

  static const _navy = Color(0xFF1A2A4A);
  static const _red = Color(0xFFE85D5D);
  static const _gray = Color(0xFF6B6B6B);
  static const _amber = Color(0xFFF5A623);

  Map<String, dynamic> get _verdict => dualVerdict(analysisResult);
  bool get _invalid => _verdict['status'] == 'invalid';
  bool get _hasResult => _verdict.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Test Result',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
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
                    _summaryCard(),
                    const SizedBox(height: 16),
                    _analyteCard(),
                    const SizedBox(height: 16),
                    _plotCard(),
                    const SizedBox(height: 16),
                    _sampleCard(),
                  ],
                ),
              ),
            ),
            _bottomButtons(context),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(double radius) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(18),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget _summaryCard() {
    final String label;
    final Color color;

    if (!_hasResult || _invalid) {
      label = 'INVALID';
      color = _amber;
    } else if (_verdict['grade'] == 'positive') {
      label = 'POSITIVE';
      color = _red;
    } else {
      label = 'NEGATIVE';
      color = _gray;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dual Strip Result',
            style: TextStyle(
              color: _navy,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyteCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(24),
      child: Column(
        children: [for (final name in dualAnalyteOrder) _analyteRow(name)],
      ),
    );
  }

  Widget _analyteRow(String name) {
    final status =
        _hasResult ? dualAnalyteStatus(analysisResult, name) : 'invalid';
    final multiple = dualIntensityMultiple(analysisResult, name);

    final String text;
    final Color color;
    switch (status) {
      case 'positive':
        text = 'Positive';
        color = _red;
      case 'negative':
        text = 'Negative';
        color = _gray;
      default:
        text = 'Invalid';
        color = _amber;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Text(
              name,
              style: TextStyle(
                color: status == 'positive' ? _red : _navy,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (multiple != null && status != 'invalid')
            Text(
              '×${multiple.toStringAsFixed(1)}',
              style: const TextStyle(
                color: _navy,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // Dual 분석 PNG(1502x1214)에서 ROI 히트맵(제목·축·컬러바 포함) 영역 비율
  static const _plotCropLeft = 0.027;
  static const _plotCropTop = 0.095;
  static const _plotCropWidth = 0.325;
  static const _plotCropHeight = 0.435;
  static const _imageAspect =
      (_plotCropWidth * 1502) / (_plotCropHeight * 1214);

  Widget _plotCard() {
    final path = analysisPlotPath;
    final hasPlot = path != null && path.isNotEmpty && File(path).existsSync();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: _imageAspect,
                child: CenterCroppedFileImage(
                  imagePath: imagePath,
                  cropWidthRatio: 0.08,
                  cropHeightRatio: 0.30,
                  cropCenterYRatio: 0.55,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AspectRatio(
                aspectRatio: _imageAspect,
                child:
                    hasPlot
                        ? AnalysisPlotRoiCropImage(
                          imagePath: path,
                          srcLeftRatio: _plotCropLeft,
                          srcTopRatio: _plotCropTop,
                          srcWidthRatio: _plotCropWidth,
                          srcHeightRatio: _plotCropHeight,
                        )
                        : const ColoredBox(
                          color: Colors.black,
                          child: Center(
                            child: Text(
                              'No analysis plot',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sampleCard() {
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
              color: _navy,
              fontSize: 35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('User ID', userId),
          _infoRow('Sample Type', sampleType),
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
            width: 300,
            child: Text(
              label,
              style: const TextStyle(color: _gray, fontSize: 33),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: _navy,
                fontSize: 33,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButtons(BuildContext context) {
    Widget button(String text, BoxDecoration decoration) {
      return Expanded(
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: decoration,
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          button('Back', const BoxDecoration(color: Color(0xFF227BFF))),
          button(
            'Completed',
            const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7D7D7D), Color(0xFF555555)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
