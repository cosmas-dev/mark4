import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mark4/class/run_test_data.dart';
import 'package:mark4/components/time_set.dart';
import 'package:mark4/result.dart';
import 'package:path_provider/path_provider.dart';

class ProgressPage extends StatefulWidget {
  final RunTestData runTestData;
  const ProgressPage({super.key, required this.runTestData});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> progress;

  String? imagePath;
  final String iotDeviceIp = "192.168.0.72";
  int lightNumber = 1;
  Socket? socket;
  List<int> _buffer = [];

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7), // 0~100%까지 걸리는 시간
    );

    progress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    controller.forward(); // 자동 시작

    // 사진 촬영 및 수신 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      captureImageFromIoT();
    });
  }

  @override
  void dispose() {
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
            // _topBar(),
            // const SizedBox(height: 40),

            // ---------- Animated Progress ----------
            Center(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RingPainter(progress.value),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Text(
                          "${(progress.value * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 32,
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
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2850A7),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Do not Open the Tray",
              style: TextStyle(fontSize: 14, color: Color(0xFF2B478B)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> captureImageFromIoT() async {
    try {
      socket = await Socket.connect(iotDeviceIp, 9191);
      print("✅ IoT 기기와 연결 성공");

      socket!.listen(
        (Uint8List data) {
          _buffer.addAll(data);
          processBuffer();
        },
        onError: (error) {
          print("Socket error: $error");
        },
        onDone: () {
          print("Socket closed");
        },
      );

      // SHUTTER 요청 전송 (셔터 속도 설정)
      var requestData = jsonEncode({
        "header": "C001",
        "body": {"CMD": "SHUTTER", "DATA": "20000"},
      });
      socket!.writeln(requestData);
      await socket!.flush();

      await Future.delayed(const Duration(milliseconds: 100));

      // CAM_CTRL 요청 전송 (촬영 시작)
      requestData = jsonEncode({
        "header": "F001",
        "body": {"CMD": "AD_LED_CTRL", "DATA": "80,100"},
      });
      socket!.writeln(requestData);
      await socket!.flush();

      await Future.delayed(const Duration(milliseconds: 100));

      requestData = jsonEncode({
        "header": "B001",
        "body": {"CMD": "CAM_CTRL", "DATA": "1"},
      });
      socket!.writeln(requestData);
      await socket!.flush();
      print("📡 CAM_CTRL 요청 전송");

      await Future.delayed(const Duration(seconds: 1));
      requestData = jsonEncode({
        "header": "B001",
        "body": {"CMD": "IMG_TRANS", "DATA": "1"},
      });
      socket!.writeln(requestData);
      await socket!.flush();
      print("📡 IMG_TRANS 요청 전송");
    } catch (e) {
      print("❌ IoT 기기 연결 실패: $e");
    }
  }

  void processBuffer() {
    const int headerSize = 8;

    while (true) {
      if (_buffer.length < headerSize) break;

      Uint8List headerBytes = Uint8List.fromList(
        _buffer.sublist(0, headerSize),
      );
      int frameSize = ByteData.sublistView(
        headerBytes,
      ).getUint64(0, Endian.little);

      if (_buffer.length < headerSize + frameSize) break;

      List<int> frameData = _buffer.sublist(headerSize, headerSize + frameSize);
      _buffer = _buffer.sublist(headerSize + frameSize);

      // ✅ JSON이면 패스
      try {
        utf8.decode(frameData);
        continue;
      } catch (_) {
        // ✅ 이미지 데이터 도착
        saveImage(frameData);
        break;
      }
    }
  }

  Future<void> saveImage(List<int> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // ⭐ 촬영 시점 파일명 생성
      final fileName = makeFileName("hi", "test");
      final filePath = "${directory.path}/$fileName";

      File file = File(filePath);
      await file.writeAsBytes(data);

      setState(() {
        imagePath = filePath;
      });

      // ✅ 갤러리에도 저장
      // final bytes = await file.readAsBytes();
      // await FlutterImageGallerySaver.saveImage(Uint8List.fromList(bytes));

      print("📁 이미지 영구 저장 완료: $filePath");

      await Future.delayed(const Duration(milliseconds: 500));
      // var requestData = jsonEncode({
      //   "header": "B001",
      //   "body": {"CMD": "BL_CTRL", "DATA": "0"},
      // });
      // socket!.writeln(requestData);
      // await socket!.flush();
      // print("📡 BL_CTRL 요청 전송");

      // if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  Result(runTestData: widget.runTestData, imagePath: filePath),
        ),
      );
    } catch (e) {
      print("이미지 저장 실패: $e");
    }
  }
}

// ---------- Custom Progress Ring Painter ----------
class RingPainter extends CustomPainter {
  final double progress;

  RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 18.0;
    final rect = Offset.zero & size;

    // Background ring
    final bgPaint =
        Paint()
          ..color = const Color(0xFFE4EAF4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Foreground progress ring
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

    // Draw background
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arc
    final sweepAngle = 2 * 3.141592 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592 * 0.5,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
