// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:mark4/components/time_set.dart';
// import 'package:mark4/single/result_single1.dart';
// import 'package:path_provider/path_provider.dart';

// class ProgressPageSingle extends StatefulWidget {
//   final String userId,
//       age,
//       gender,
//       sampleType,
//       selectedItem,
//       shutterSpeed,
//       ip;

//   const ProgressPageSingle({
//     super.key,
//     required this.userId,
//     required this.shutterSpeed,
//     required this.gender,
//     required this.sampleType,
//     required this.selectedItem,
//     required this.age,
//     required this.ip,
//   });

//   @override
//   State<ProgressPageSingle> createState() => _ProgressPageSingleState();
// }

// class _ProgressPageSingleState extends State<ProgressPageSingle>
//     with SingleTickerProviderStateMixin {
//   late AnimationController controller;
//   late Animation<double> progress;

//   Socket? socket;
//   final List<int> _buffer = [];

//   String? _imagePath;
//   Map<String, dynamic>? _analysisResult;
//   bool _isSavingImage = false;
//   bool _hasNavigated = false;
//   Timer? _fallbackTimer;

//   @override
//   void initState() {
//     super.initState();

//     controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 7),
//     );

//     progress = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

//     controller.forward();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       captureImageFromIoT();
//     });
//   }

//   @override
//   void dispose() {
//     _fallbackTimer?.cancel();
//     socket?.destroy();
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEFF3F8),
//       appBar: AppBar(backgroundColor: const Color(0xFFEFF3F8)),
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Center(
//               child: AnimatedBuilder(
//                 animation: controller,
//                 builder: (context, child) {
//                   return CustomPaint(
//                     painter: RingPainter(progress.value),
//                     child: SizedBox(
//                       width: 400,
//                       height: 400,
//                       child: Center(
//                         child: Text(
//                           "${(progress.value * 100).toInt()}%",
//                           style: const TextStyle(
//                             fontSize: 50,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF1A2A4A),
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 35),
//             const Text(
//               "Reading..",
//               style: TextStyle(
//                 fontSize: 40,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF2850A7),
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "Do not Open the Tray",
//               style: TextStyle(fontSize: 28, color: Color(0xFF2B478B)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _sendCommand({
//     required String header,
//     required String cmd,
//     required Object data,
//   }) async {
//     final currentSocket = socket;
//     if (currentSocket == null) return;

//     final requestData = jsonEncode({
//       "header": header,
//       "body": {"CMD": cmd, "DATA": data},
//     });

//     debugPrint("SEND -> $requestData");
//     currentSocket.write('$requestData\n');
//     await currentSocket.flush();
//   }

//   Future<void> captureImageFromIoT() async {
//     try {
//       socket = await Socket.connect(widget.ip, 9191);
//       debugPrint("IoT 기기와 연결 성공: ${widget.ip}:9191");

//       socket!.listen(
//         (Uint8List data) {
//           _buffer.addAll(data);
//           processBuffer();
//         },
//         onError: (error) => debugPrint("Socket error: $error"),
//         onDone: () => debugPrint("Socket closed"),
//       );

//       final shutter = int.tryParse(widget.shutterSpeed.trim());
//       if (shutter != null && shutter > 0) {
//         await _sendCommand(header: "C001", cmd: "SHUTTER", data: shutter);
//         await Future.delayed(const Duration(milliseconds: 120));
//       }

//       // MARK-4 v1.3 기준 자동 시퀀스: BL ON → RAW10+JPEG 캡처 → BL OFF
//       // → JPEG 전송 → Capture Complete JSON → ANALYSIS_DONE 비동기 통지.
//       await _sendCommand(header: "A001", cmd: "RUN", data: 1);
//     } catch (e) {
//       debugPrint("IoT 기기 연결 실패: $e");
//     }
//   }

//   bool _isJpeg(List<int> bytes) {
//     return bytes.length >= 4 &&
//         bytes[0] == 0xFF &&
//         bytes[1] == 0xD8 &&
//         bytes[bytes.length - 2] == 0xFF &&
//         bytes[bytes.length - 1] == 0xD9;
//   }

//   bool _isPng(List<int> bytes) {
//     return bytes.length >= 8 &&
//         bytes[0] == 0x89 &&
//         bytes[1] == 0x50 &&
//         bytes[2] == 0x4E &&
//         bytes[3] == 0x47;
//   }

//   int _readUint32LE(int offset) {
//     final bytes = Uint8List.fromList(_buffer.sublist(offset, offset + 4));
//     return ByteData.sublistView(bytes).getUint32(0, Endian.little);
//   }

//   void processBuffer() {
//     while (_buffer.length >= 4 && !_hasNavigated) {
//       final firstLength = _readUint32LE(0);

//       if (firstLength <= 0) {
//         debugPrint('잘못된 length prefix: $firstLength');
//         _buffer.clear();
//         return;
//       }

//       // 이미지 응답은 2-Block: [4B + image_size(4B)] + [4B + Binary]
//       if (firstLength == 4) {
//         if (_buffer.length < 12) return;

//         final imageSize = _readUint32LE(4);
//         final dataLength = _readUint32LE(8);
//         if (imageSize <= 0 || dataLength <= 0) {
//           _buffer.removeRange(0, 4);
//           continue;
//         }

//         if (_buffer.length < 12 + dataLength) return;

//         final imageData = _buffer.sublist(12, 12 + dataLength);
//         _buffer.removeRange(0, 12 + dataLength);

//         if (_isJpeg(imageData) || _isPng(imageData)) {
//           _isSavingImage = true;
//           saveImage(imageData);
//         } else {
//           debugPrint('이미지 프레임 형식 확인 실패: ${imageData.take(8).toList()}');
//         }
//         continue;
//       }

//       // JSON 응답 / 비동기 통지: [4B length] + JSON payload
//       if (_buffer.length < 4 + firstLength) return;

//       final payload = _buffer.sublist(4, 4 + firstLength);
//       _buffer.removeRange(0, 4 + firstLength);

//       try {
//         final decoded = jsonDecode(utf8.decode(payload));
//         if (decoded is Map<String, dynamic>) {
//           _handleJsonMessage(decoded);
//         } else if (decoded is Map) {
//           _handleJsonMessage(Map<String, dynamic>.from(decoded));
//         }
//       } catch (e) {
//         debugPrint('JSON 프레임 파싱 실패: $e');
//       }
//     }
//   }

//   void _handleJsonMessage(Map<String, dynamic> message) {
//     final header = message['header']?.toString() ?? '';
//     final body = message['body'];
//     final cmd = body is Map ? body['CMD']?.toString() ?? '' : '';
//     final data = body is Map ? body['DATA'] : null;

//     debugPrint('RECV JSON -> header=$header cmd=$cmd data=$data');

//     if (header == 'ANALYSIS_DONE') {
//       _analysisResult = _normalizeAnalysisData(data);
//       _navigateIfReady(force: true);
//       return;
//     }

//     if (header == 'E001' && cmd == 'ANALYSIS_GET_LAST') {
//       _analysisResult = _normalizeAnalysisData(data);
//       _navigateIfReady(force: true);
//       return;
//     }

//     if (header == 'A001' && cmd == 'RUN') {
//       // ANALYSIS_DONE이 늦거나 분석 auto_run이 꺼진 환경을 위한 fallback.
//       _fallbackTimer ??= Timer(const Duration(seconds: 5), () async {
//         if (_hasNavigated || _analysisResult != null) return;
//         await _sendCommand(header: 'E001', cmd: 'ANALYSIS_GET_LAST', data: '');
//         Timer(const Duration(seconds: 2), () => _navigateIfReady(force: true));
//       });
//     }
//   }

//   Map<String, dynamic>? _normalizeAnalysisData(dynamic data) {
//     if (data == null) return null;
//     if (data is Map<String, dynamic>) return data;
//     if (data is Map) return Map<String, dynamic>.from(data);
//     if (data is String) {
//       if (data.startsWith('Error Fail:')) {
//         return {'status': 'error', 'reason': data};
//       }
//       try {
//         final decoded = jsonDecode(data);
//         if (decoded is Map<String, dynamic>) return decoded;
//         if (decoded is Map) return Map<String, dynamic>.from(decoded);
//       } catch (_) {
//         return {'status': 'unknown', 'raw': data};
//       }
//     }
//     return {'status': 'unknown', 'raw': data.toString()};
//   }

//   Future<void> saveImage(List<int> data) async {
//     if (_hasNavigated) return;
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final fileName = makeFileName("mark4", "capture");
//       final filePath = "${directory.path}/$fileName";

//       final file = File(filePath);
//       await file.writeAsBytes(data, flush: true);

//       _imagePath = filePath;
//       debugPrint("이미지 저장 완료: $filePath");
//       _navigateIfReady();
//     } catch (e) {
//       _isSavingImage = false;
//       debugPrint("이미지 저장 실패: $e");
//     }
//   }

//   void _navigateIfReady({bool force = false}) {
//     if (!mounted || _hasNavigated || _imagePath == null) return;
//     if (!force && _analysisResult == null) return;

//     _hasNavigated = true;
//     _fallbackTimer?.cancel();

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => ResultSingle(
//               shutterSpeed: widget.shutterSpeed,
//               userId: widget.userId,
//               gender: widget.gender,
//               sampleType: widget.sampleType,
//               selectedItem: widget.selectedItem,
//               age: widget.age,
//               imagePath: _imagePath!,
//               ip: widget.ip,
//               analysisResult: _analysisResult,
//             ),
//       ),
//     );
//   }
// }

// class RingPainter extends CustomPainter {
//   final double progress;

//   RingPainter(this.progress);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final strokeWidth = 18.0;
//     final rect = Offset.zero & size;

//     final bgPaint =
//         Paint()
//           ..color = const Color(0xFFE4EAF4)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = strokeWidth
//           ..strokeCap = StrokeCap.round;

//     final progressPaint =
//         Paint()
//           ..shader = const SweepGradient(
//             colors: [Color(0xFF3C66F4), Color(0xFF3C66F4)],
//           ).createShader(rect)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = strokeWidth
//           ..strokeCap = StrokeCap.round;

//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = (size.width - strokeWidth) / 2;

//     canvas.drawCircle(center, radius, bgPaint);
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -3.141592 * 0.5,
//       2 * 3.141592 * progress,
//       false,
//       progressPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant RingPainter oldDelegate) {
//     return oldDelegate.progress != progress;
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mark4/DB/run_test_json_store.dart';
import 'package:mark4/components/time_set.dart';
import 'package:mark4/single/result_single.dart';
import 'package:path_provider/path_provider.dart';

class ProgressPageSingle extends StatefulWidget {
  final String userId, sampleType, selectedItem, shutterSpeed, ip;

  const ProgressPageSingle({
    super.key,
    required this.userId,
    required this.shutterSpeed,
    required this.sampleType,
    required this.selectedItem,
    required this.ip,
  });

  @override
  State<ProgressPageSingle> createState() => _ProgressPageSingleState();
}

class _ProgressPageSingleState extends State<ProgressPageSingle>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> progress;

  Socket? socket;
  final List<int> _buffer = [];

  String? _imagePath;
  String? _analysisPlotPath;
  Map<String, dynamic>? _analysisResult;
  String _expectedBinaryKind = 'capture';
  bool _requestedAnalysisPlot = false;
  bool _runCompleted = false;
  bool _analysisPlotFinished = false;
  Timer? _analysisPlotTimeoutTimer;
  bool _isSavingImage = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  final store = RunTestJsonStore();
  bool _savedResult = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    progress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      captureImageFromIoT();
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _analysisPlotTimeoutTimer?.cancel();
    socket?.destroy();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(backgroundColor: const Color(0xFFEFF3F8)),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RingPainter(progress.value),
                    child: SizedBox(
                      width: 400,
                      height: 400,
                      child: Center(
                        child: Text(
                          "${(progress.value * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2A4A),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 35),
            const Text(
              "Reading..",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2850A7),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Do not Open the Tray",
              style: TextStyle(fontSize: 28, color: Color(0xFF2B478B)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCommand({
    required String header,
    required String cmd,
    required Object data,
  }) async {
    final currentSocket = socket;
    if (currentSocket == null) return;

    final requestData = jsonEncode({
      "header": header,
      "body": {"CMD": cmd, "DATA": data},
    });

    debugPrint("SEND -> $requestData");
    currentSocket.write('$requestData\n');
    await currentSocket.flush();
  }

  Future<void> captureImageFromIoT() async {
    try {
      socket = await Socket.connect(widget.ip, 9191);
      debugPrint("IoT 기기와 연결 성공: ${widget.ip}:9191");

      socket!.listen(
        (Uint8List data) {
          _buffer.addAll(data);
          processBuffer();
        },
        onError: (error) => debugPrint("Socket error: $error"),
        onDone: () => debugPrint("Socket closed"),
      );

      final shutter = int.tryParse(widget.shutterSpeed.trim());
      if (shutter != null && shutter > 0) {
        await _sendCommand(header: "C001", cmd: "SHUTTER", data: shutter);
        await Future.delayed(const Duration(milliseconds: 120));
      }

      // MARK-4 v1.3 기준 자동 시퀀스: BL ON → RAW10+JPEG 캡처 → BL OFF
      // → JPEG 전송 → Capture Complete JSON → ANALYSIS_DONE 비동기 통지.
      // 분석 PNG(frame_analysis.png)가 생성되어야 하므로 RUN 전에 plot 생성을 켠다.
      await _sendCommand(header: "E001", cmd: "ANALYSIS_SET_PLOT", data: 1);
      await Future.delayed(const Duration(milliseconds: 120));

      await _sendCommand(header: "A001", cmd: "RUN", data: 1);
    } catch (e) {
      debugPrint("IoT 기기 연결 실패: $e");
    }
  }

  bool _isJpeg(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[bytes.length - 2] == 0xFF &&
        bytes[bytes.length - 1] == 0xD9;
  }

  bool _isPng(List<int> bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  int _readUint32LE(int offset) {
    final bytes = Uint8List.fromList(_buffer.sublist(offset, offset + 4));
    return ByteData.sublistView(bytes).getUint32(0, Endian.little);
  }

  void processBuffer() {
    while (_buffer.length >= 4 && !_hasNavigated) {
      final firstLength = _readUint32LE(0);

      if (firstLength <= 0) {
        debugPrint('잘못된 length prefix: $firstLength');
        _buffer.clear();
        return;
      }

      // 이미지 응답은 2-Block: [4B + image_size(4B)] + [4B + Binary]
      if (firstLength == 4) {
        if (_buffer.length < 12) return;

        final imageSize = _readUint32LE(4);
        final dataLength = _readUint32LE(8);
        if (imageSize <= 0 || dataLength <= 0) {
          _buffer.removeRange(0, 4);
          continue;
        }

        if (_buffer.length < 12 + dataLength) return;

        final imageData = _buffer.sublist(12, 12 + dataLength);
        _buffer.removeRange(0, 12 + dataLength);

        _isSavingImage = true;
        saveBinaryFrame(imageData, _expectedBinaryKind);

        continue;
      }

      // JSON 응답 / 비동기 통지: [4B length] + JSON payload
      if (_buffer.length < 4 + firstLength) return;

      final payload = _buffer.sublist(4, 4 + firstLength);
      _buffer.removeRange(0, 4 + firstLength);

      try {
        final decoded = jsonDecode(utf8.decode(payload));
        if (decoded is Map<String, dynamic>) {
          _handleJsonMessage(decoded);
        } else if (decoded is Map) {
          _handleJsonMessage(Map<String, dynamic>.from(decoded));
        }
      } catch (e) {
        debugPrint('JSON 프레임 파싱 실패: $e');
      }
    }
  }

  void _handleJsonMessage(Map<String, dynamic> message) {
    final header = message['header']?.toString() ?? '';
    final body = message['body'];
    final cmd = body is Map ? body['CMD']?.toString() ?? '' : '';
    final data = body is Map ? body['DATA'] : null;

    debugPrint('RECV JSON -> header=$header cmd=$cmd data=$data');

    if (header == 'ANALYSIS_DONE') {
      _analysisResult = _normalizeAnalysisData(data);
      if (_runCompleted) {
        _requestAnalysisPlot();
      }
      _navigateIfReady();
      return;
    }

    if (header == 'E001' && cmd == 'ANALYSIS_GET_LAST') {
      _analysisResult = _normalizeAnalysisData(data);
      _navigateIfReady(force: true);
      return;
    }

    if (header == 'A001' && cmd == 'RUN') {
      _runCompleted = true;

      if (data.toString().contains('Capture Complete')) {
        _requestAnalysisPlot();
      }

      _fallbackTimer ??= Timer(const Duration(seconds: 5), () async {
        if (_hasNavigated || _analysisResult != null) return;
        await _sendCommand(header: 'E001', cmd: 'ANALYSIS_GET_LAST', data: '');
        Timer(const Duration(seconds: 2), () => _navigateIfReady(force: true));
      });
    }
  }

  Map<String, dynamic>? _normalizeAnalysisData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      if (data.startsWith('Error Fail:')) {
        return {'status': 'error', 'reason': data};
      }
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return {'status': 'unknown', 'raw': data};
      }
    }
    return {'status': 'unknown', 'raw': data.toString()};
  }

  Future<void> saveBinaryFrame(List<int> data, String kind) async {
    if (_hasNavigated) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll('-', '')
          .replaceAll(':', '')
          .replaceAll('.', '_');

      late final String filePath;

      if (kind == 'analysis_plot') {
        filePath = '${directory.path}/mark4_analysis_plot_$timestamp.png';
      } else {
        final fileName = makeFileName("mark4", "capture");
        filePath = "${directory.path}/$fileName";
      }

      final file = File(filePath);
      await file.writeAsBytes(data, flush: true);

      if (kind == 'analysis_plot') {
        _analysisPlotPath = filePath;
        _analysisPlotFinished = true;
        debugPrint('분석 PNG 저장 완료: $filePath (${data.length} bytes)');
        _navigateIfReady(force: true);
      } else {
        _imagePath = filePath;
        debugPrint("이미지 저장 완료: $filePath");
        _navigateIfReady();
      }
    } catch (e) {
      _isSavingImage = false;
      debugPrint("바이너리 저장 실패($kind): $e");
      if (kind == 'analysis_plot') {
        _analysisPlotFinished = true;
        _navigateIfReady(force: true);
      }
    }
  }

  Future<void> _requestAnalysisPlot() async {
    if (_requestedAnalysisPlot || _hasNavigated) return;
    _requestedAnalysisPlot = true;
    _expectedBinaryKind = 'analysis_plot';

    debugPrint('분석 PNG 요청 시작: IMG_TRANS_ANALYSIS_PLOT');
    await _sendCommand(header: 'B001', cmd: 'IMG_TRANS_ANALYSIS_PLOT', data: 1);

    _analysisPlotTimeoutTimer?.cancel();
    _analysisPlotTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (_hasNavigated || _analysisPlotPath != null) return;
      debugPrint('분석 PNG 수신 타임아웃. 캡처 이미지만 결과 화면으로 이동합니다.');
      _analysisPlotFinished = true;
      _navigateIfReady(force: true);
    });
  }

  Future<void> _navigateIfReady({bool force = false}) async {
    if (!mounted || _hasNavigated || _imagePath == null) return;
    if (!_runCompleted) return;
    if (_analysisResult == null) return;

    if (!_requestedAnalysisPlot) {
      _requestAnalysisPlot();
      return;
    }

    if (!_analysisPlotFinished) return;

    _hasNavigated = true;
    _fallbackTimer?.cancel();
    _analysisPlotTimeoutTimer?.cancel();

    await _saveResultOnce();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ResultSingle(
              shutterSpeed: widget.shutterSpeed,
              userId: widget.userId,
              sampleType: widget.sampleType,
              selectedItem: widget.selectedItem,
              imagePath: _imagePath!,
              analysisPlotPath: _analysisPlotPath,
              ip: widget.ip,
              analysisResult: _analysisResult,
            ),
      ),
    );
  }

  Future<void> _saveResultOnce() async {
    if (_savedResult || _imagePath == null) return;
    _savedResult = true;

    try {
      await store.save(
        shutterSpeed: widget.shutterSpeed,
        userId: widget.userId,
        item: widget.selectedItem,
        sampleType: widget.sampleType,
        imagePath: _imagePath!,
        analysisPlotPath: _analysisPlotPath,
        analysisResult: _analysisResult,
        result: _buildResultString(),
      );
    } catch (e) {
      debugPrint('결과 저장 실패: $e');
    }
  }

  // String _buildResultString() {
  //   final cIntensity = _readPathText(['control', 'intensity_fixed_scale']);
  //   final tIntensity = _readPathText(['test', 'intensity_fixed_scale']);

  //   return 'C: $cIntensity / T: $tIntensity';
  // }
  String _buildResultString() {
    final cIntensity = _readPathText(['raw_metrics', 'c_int_vs_lod']);
    final tIntensity = _readPathText(['raw_metrics', 't_int_vs_lod']);

    return 'C: $cIntensity / T: $tIntensity';
  }

  String _readPathText(List<String> path) {
    final value = _lookupPath(path);
    if (value == null) return '-';

    if (value is num) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }

    return value.toString();
  }

  dynamic _lookupPath(List<String> path) {
    dynamic node = _analysisResult;

    for (final key in path) {
      if (node is Map && node.containsKey(key)) {
        node = node[key];
      } else {
        return null;
      }
    }

    return node;
  }

  String _readDetected(List<String> path) {
    final value = _lookupPath(path);

    if (value == true) return 'Detected';
    if (value == false) return 'Not Detected';

    return '-';
  }
}

class RingPainter extends CustomPainter {
  final double progress;

  RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 18.0;
    final rect = Offset.zero & size;

    final bgPaint =
        Paint()
          ..color = const Color(0xFFE4EAF4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final progressPaint =
        Paint()
          ..shader = const SweepGradient(
            colors: [Color(0xFF3C66F4), Color(0xFF3C66F4)],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592 * 0.5,
      2 * 3.141592 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
