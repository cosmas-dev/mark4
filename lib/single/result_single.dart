import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mark4/DB/run_test_json_store.dart';
import 'package:mark4/dual/dual_analysis.dart';

class ResultSingle extends StatefulWidget {
  final String userId, sampleType, selectedItem, imagePath, shutterSpeed, ip;

  final String? analysisPlotPath;
  final Map<String, dynamic>? analysisResult;

  const ResultSingle({
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

  @override
  State<ResultSingle> createState() => _ResultSingleState();
}

class _ResultSingleState extends State<ResultSingle> {
  // final store = RunTestJsonStore();
  // bool _saved = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _saveResultOnce();
  // }

  // Future<void> _saveResultOnce() async {
  //   if (_saved) return;
  //   _saved = true;

  //   try {
  //     await store.save(
  //       shutterSpeed: widget.shutterSpeed,
  //       name: widget.userId,
  //       age: widget.age,
  //       gender: widget.gender,
  //       item: widget.selectedItem,
  //       sampleType: widget.sampleType,
  //       imagePath: widget.imagePath,
  //       analysisPlotPath: widget.analysisPlotPath,
  //       analysisResult: widget.analysisResult,
  //       result: _buildResultString(),
  //     );
  //   } catch (e) {
  //     debugPrint('결과 저장 실패: $e');
  //   }
  // }

  String _buildResultString() {
    final c = _readDetected(['control', 'detected']);
    final t = _readDetected(['test', 'detected']);
    return 'C: $c / T: $t';
  }

  dynamic _lookupPath(List<String> path) {
    dynamic node = widget.analysisResult;

    for (final key in path) {
      if (node is Map && node.containsKey(key)) {
        node = node[key];
      } else {
        return null;
      }
    }

    return node;
  }

  String _readPathText(List<String> path) {
    final value = _lookupPath(path);
    if (value == null) return '-';

    if (value is num) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }

    return value.toString();
  }

  String _readDetected(List<String> path) {
    final value = _lookupPath(path);

    if (value == true) return 'Detected';
    if (value == false) return 'Not Detected';

    return '-';
  }

  String? _invalidReason() {
    final verdict = widget.analysisResult?['verdict'];
    if (verdict is Map && verdict['status'] == 'invalid') {
      return verdict['reason']?.toString() ?? 'UNKNOWN';
    }
    return null;
  }

  Color _detectedColor(String value, bool isTest) {
    if (value == 'Detected') {
      return isTest ? const Color(0xFFE85D5D) : const Color(0xFF227BFF);
    }
    return const Color(0xFF6B6B6B);
  }

  @override
  Widget build(BuildContext context) {
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
                    _ctResultCard(),
                    const SizedBox(height: 16),
                    _capturedImageWithAnalysisRoi(),
                    const SizedBox(height: 16),
                    _patientCard(),
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

  Widget _ctResultCard() {
    final cDetected = _readDetected(['control', 'detected']);
    final tDetected = _readDetected(['test', 'detected']);

    // final cSnr = _readPathText(['control', 'snr']);
    // final tSnr = _readPathText(['test', 'snr']);

    final cIntensity = _readPathText(['raw_metrics', 'c_int_vs_lod']);
    final tIntensity = _readPathText(['raw_metrics', 't_int_vs_lod']);

    // final c = double.tryParse(cIntensity);
    // final t = double.tryParse(tIntensity);
    // final ratio =
    //     (c != null && t != null && t != 0) ? (c / t).toStringAsFixed(2) : '-';

    // final cY = _readPathText(['control', 'y_px_r_only']);
    // final tY = _readPathText(['test', 'y_px_r_only']);

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
          const Text(
            'C / T Line Result',
            style: TextStyle(
              color: Color(0xFF1A2A4A),
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (_invalidReason() != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dualInvalidMessage(_invalidReason()),
                style: const TextStyle(color: Color(0xFF1A2A4A), fontSize: 24),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _ctLineRow(
            label: 'C Line',
            detected: cDetected,
            intensity: cIntensity,
            color: _detectedColor(cDetected, false),
          ),
          const SizedBox(height: 14),
          _ctLineRow(
            label: 'T Line',
            detected: tDetected,
            intensity: tIntensity,
            color: _detectedColor(tDetected, true),
          ),
          const SizedBox(height: 14),
          // Container(
          //   padding: const EdgeInsets.all(18),
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFEFF3F8),
          //     borderRadius: BorderRadius.circular(18),
          //   ),
          //   child: Row(
          //     children: [
          //       SizedBox(
          //         width: 200,
          //         child: Text(
          //           'C/T Ratio',
          //           style: TextStyle(
          //             color: Colors.black,
          //             fontSize: 36,
          //             fontWeight: FontWeight.w900,
          //           ),
          //         ),
          //       ),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Ratio: $ratio',
          //               style: const TextStyle(
          //                 color: Color(0xFF1A2A4A),
          //                 fontSize: 28,
          //                 fontWeight: FontWeight.w600,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _ctLineRow({
    required String label,
    required String detected,
    required String intensity,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detected,
                  style: TextStyle(
                    color: color,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Intensity: $intensity',
                  style: const TextStyle(
                    color: Color(0xFF1A2A4A),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
  // Widget _capturedImageWithAnalysisRoi() {
  //   const imageHeight = 360.0;

  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(22),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withAlpha(16),
  //           blurRadius: 12,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(16),
  //       child: SizedBox(
  //         width: double.infinity,
  //         height: imageHeight,
  //         child: CenterCroppedFileImage(
  //           imagePath: widget.imagePath,
  //           cropWidthRatio: 0.08,
  //           cropHeightRatio: 0.30,
  //           cropCenterYRatio: 0.55,
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
          _infoRow('User ID', widget.userId),
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
            width: 300,
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

  Widget _bottomButtons(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: const Color(0xFF227BFF),
                child: const Center(
                  child: Text(
                    "Back",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pop(context),
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

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (!mounted) {
        frame.image.dispose();
        return;
      }

      setState(() => _image = frame.image);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
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
  final double srcLeftRatio;
  final double srcTopRatio;
  final double srcWidthRatio;
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

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (!mounted) {
        frame.image.dispose();
        return;
      }

      setState(() => _image = frame.image);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
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
