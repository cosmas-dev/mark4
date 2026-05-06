import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

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

  final String? analysisPlotPath;
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
    this.analysisPlotPath,
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

        if (['true', 'yes', 'y', '1'].contains(normalized)) {
          return true;
        }

        if (['false', 'no', 'n', '0'].contains(normalized)) {
          return false;
        }
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

    if (normalized.contains('positive')) {
      return const Color(0xFFE85D5D);
    }

    if (normalized.contains('negative')) {
      return const Color(0xFF227BFF);
    }

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

                    // 여기 한 카드 안에
                    // 왼쪽: 기존 검은 바탕 촬영 이미지
                    // 오른쪽: Analysis Plot PNG 안의 ROI heatmap crop
                    _capturedImageWithAnalysisRoi(),

                    const SizedBox(height: 16),
                    _patientCard(),
                  ],
                ),
              ),
            ),
            // _bottomActions(context),
            _bottomButtons(context),
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
                  fontSize: 35,
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
            width: 500,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 33,
                color: Color(0xFF6B6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 33,
                color: Color(0xFF1A2A4A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _capturedImageWithAnalysisRoi() {
    const imageHeight = 360.0;

    final plotPath = widget.analysisPlotPath;
    final hasAnalysisPlot =
        plotPath != null && plotPath.isNotEmpty && File(plotPath).existsSync();

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
        child: SizedBox(
          width: double.infinity,
          height: imageHeight,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: CenterCroppedFileImage(
                    imagePath: widget.imagePath,
                    cropWidthRatio: 0.08,
                    cropHeightRatio: 0.30,
                    cropCenterYRatio: 0.55,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child:
                      hasAnalysisPlot
                          ? AnalysisPlotRoiCropImage(
                            imagePath: plotPath,

                            // Analysis Plot PNG 안에서 왼쪽 위 ROI heatmap만 crop.
                            // 위치가 조금 안 맞으면 아래 4개 값만 조절하면 됨.
                            srcLeftRatio: 0.10,
                            srcTopRatio: 0.10,
                            srcWidthRatio: 0.24,
                            srcHeightRatio: 0.45,
                          )
                          : const ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: Text(
                                'Analysis Plot 없음',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                ),
              ),
            ],
          ),
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
              fontSize: 35,
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
              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 33),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xFF1A2A4A),
                fontSize: 33,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //   Widget _bottomActions(BuildContext context) {
  //     return Container(
  //       padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //         boxShadow: [
  //           BoxShadow(
  //             blurRadius: 8,
  //             color: Colors.black12,
  //             offset: Offset(0, -2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: _actionButton(
  //               text: 'Back',
  //               color: const Color(0xFF6B6B6B),
  //               onTap: () => Navigator.pop(context),
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: _actionButton(
  //               text: 'Completed',
  //               color: const Color(0xFF227BFF),
  //               onTap:
  //                   () => Navigator.popUntil(context, (route) => route.isFirst),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   Widget _actionButton({
  //     required String text,
  //     required Color color,
  //     required VoidCallback onTap,
  //   }) {
  //     return GestureDetector(
  //       onTap: onTap,
  //       child: Container(
  //         height: 58,
  //         decoration: BoxDecoration(
  //           color: color,
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //         child: Center(
  //           child: Text(
  //             text,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 20,
  //               fontWeight: FontWeight.w800,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  // }

  // ======================= BOTTOM BUTTONS =======================
  Widget _bottomButtons(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap:
                  () => Navigator.popUntil(context, (route) => route.isFirst),
              child: Container(
                color: const Color(0xFF227BFF),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 60),
                      SizedBox(height: 4),
                      Text(
                        "Back",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 50,
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
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF7D7D7D), Color(0xFF555555)],
                ),
              ),
              child: const Center(
                child: Text(
                  "Completed",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CenterCroppedFileImage extends StatefulWidget {
  final String imagePath;
  final double cropWidthRatio;
  final double cropHeightRatio;
  final double cropCenterYRatio;

  const CenterCroppedFileImage({
    super.key,
    required this.imagePath,
    this.cropWidthRatio = 0.5,
    this.cropHeightRatio = 0.36,
    this.cropCenterYRatio = 0.7,
  });

  @override
  State<CenterCroppedFileImage> createState() => _CenterCroppedFileImageState();
}

class _CenterCroppedFileImageState extends State<CenterCroppedFileImage> {
  ui.Image? _image;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CenterCroppedFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imagePath != widget.imagePath) {
      _image?.dispose();
      _image = null;
      _error = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (!mounted) {
        frame.image.dispose();
        return;
      }

      setState(() {
        _image = frame.image;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e;
      });
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            '이미지를 불러올 수 없습니다.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_image == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _CenterCropPainter(
        image: _image!,
        cropWidthRatio: widget.cropWidthRatio,
        cropHeightRatio: widget.cropHeightRatio,
        cropCenterYRatio: widget.cropCenterYRatio,
      ),
    );
  }
}

class _CenterCropPainter extends CustomPainter {
  final ui.Image image;
  final double cropWidthRatio;
  final double cropHeightRatio;
  final double cropCenterYRatio;

  _CenterCropPainter({
    required this.image,
    required this.cropWidthRatio,
    required this.cropHeightRatio,
    required this.cropCenterYRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    final viewAspect = size.width / size.height;

    var cropWidth = (imageWidth * cropWidthRatio).clamp(1.0, imageWidth);
    var cropHeight = cropWidth / viewAspect;

    final maxCropHeight = (imageHeight * cropHeightRatio).clamp(
      1.0,
      imageHeight,
    );

    if (cropHeight > maxCropHeight) {
      cropHeight = maxCropHeight;
      cropWidth = (cropHeight * viewAspect).clamp(1.0, imageWidth);
    }

    final left = ((imageWidth - cropWidth) / 2).clamp(
      0.0,
      imageWidth - cropWidth,
    );

    final centerY = imageHeight * cropCenterYRatio;

    final top = (centerY - cropHeight / 2).clamp(0.0, imageHeight - cropHeight);

    final src = Rect.fromLTWH(left, top, cropWidth, cropHeight);
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(dst, Paint()..color = Colors.black);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _CenterCropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.cropWidthRatio != cropWidthRatio ||
        oldDelegate.cropHeightRatio != cropHeightRatio ||
        oldDelegate.cropCenterYRatio != cropCenterYRatio;
  }
}

class AnalysisPlotRoiCropImage extends StatefulWidget {
  final String imagePath;

  /// Analysis Plot PNG 전체 기준 crop 시작 X 위치 비율.
  /// 값을 키우면 crop 영역이 오른쪽으로 이동.
  final double srcLeftRatio;

  /// Analysis Plot PNG 전체 기준 crop 시작 Y 위치 비율.
  /// 값을 키우면 crop 영역이 아래로 이동.
  final double srcTopRatio;

  /// Analysis Plot PNG 전체 기준 crop 가로 폭 비율.
  /// 값을 줄이면 더 확대됨.
  final double srcWidthRatio;

  /// Analysis Plot PNG 전체 기준 crop 세로 폭 비율.
  /// 값을 줄이면 더 확대됨.
  final double srcHeightRatio;

  const AnalysisPlotRoiCropImage({
    super.key,
    required this.imagePath,
    this.srcLeftRatio = 0.1,
    this.srcTopRatio = 0.1,
    this.srcWidthRatio = 0.20,
    this.srcHeightRatio = 0.50,
  });

  @override
  State<AnalysisPlotRoiCropImage> createState() =>
      _AnalysisPlotRoiCropImageState();
}

class _AnalysisPlotRoiCropImageState extends State<AnalysisPlotRoiCropImage> {
  ui.Image? _image;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant AnalysisPlotRoiCropImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imagePath != widget.imagePath) {
      _image?.dispose();
      _image = null;
      _error = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (!mounted) {
        frame.image.dispose();
        return;
      }

      setState(() {
        _image = frame.image;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e;
      });
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Analysis Plot 이미지를 불러올 수 없습니다.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_image == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _AnalysisPlotRoiCropPainter(
        image: _image!,
        srcLeftRatio: widget.srcLeftRatio,
        srcTopRatio: widget.srcTopRatio,
        srcWidthRatio: widget.srcWidthRatio,
        srcHeightRatio: widget.srcHeightRatio,
      ),
    );
  }
}

class _AnalysisPlotRoiCropPainter extends CustomPainter {
  final ui.Image image;
  final double srcLeftRatio;
  final double srcTopRatio;
  final double srcWidthRatio;
  final double srcHeightRatio;

  _AnalysisPlotRoiCropPainter({
    required this.image,
    required this.srcLeftRatio,
    required this.srcTopRatio,
    required this.srcWidthRatio,
    required this.srcHeightRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    var srcLeft = imageWidth * srcLeftRatio;
    var srcTop = imageHeight * srcTopRatio;
    var srcWidth = imageWidth * srcWidthRatio;
    var srcHeight = imageHeight * srcHeightRatio;

    srcWidth = srcWidth.clamp(1.0, imageWidth);
    srcHeight = srcHeight.clamp(1.0, imageHeight);

    srcLeft = srcLeft.clamp(0.0, imageWidth - srcWidth);
    srcTop = srcTop.clamp(0.0, imageHeight - srcHeight);

    final src = Rect.fromLTWH(srcLeft, srcTop, srcWidth, srcHeight);
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(dst, Paint()..color = Colors.black);

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalysisPlotRoiCropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.srcLeftRatio != srcLeftRatio ||
        oldDelegate.srcTopRatio != srcTopRatio ||
        oldDelegate.srcWidthRatio != srcWidthRatio ||
        oldDelegate.srcHeightRatio != srcHeightRatio;
  }
}
