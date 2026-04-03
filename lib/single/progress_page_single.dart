import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mark4/components/time_set.dart';
import 'package:mark4/single/result_single.dart';
import 'package:path_provider/path_provider.dart';

class ProgressPageSingle extends StatefulWidget {
  final String userName, age, gender, sampleType, selectedItem;
  const ProgressPageSingle({
    super.key,
    required this.userName,
    required this.gender,
    required this.sampleType,
    required this.selectedItem,
    required this.age,
  });

  @override
  State<ProgressPageSingle> createState() => _ProgressPageSingleState();
}

class _ProgressPageSingleState extends State<ProgressPageSingle>
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
    required String data,
  }) async {
    if (socket == null) return;

    final requestData = jsonEncode({
      "header": header,
      "body": {"CMD": cmd, "DATA": data},
    });

    print("📤 SEND -> $requestData");
    socket!.writeln(requestData);
    await socket!.flush();
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
          print("❌ Socket error: $error");
        },
        onDone: () {
          print("🔌 Socket closed");
        },
      );

      const shutterValue = "225000";

      // 1. 셔터 속도 설정
      var requestData = jsonEncode({
        "header": "C001",
        "body": {"CMD": "SHUTTER", "DATA": shutterValue},
      });
      print("📷 Flutter에서 설정한 SHUTTER 값: $shutterValue");
      socket!.writeln(requestData);
      await socket!.flush();

      await Future.delayed(const Duration(milliseconds: 150));

      // 2. 현재 셔터 설정값 조회
      requestData = jsonEncode({
        "header": "A001",
        "body": {"CMD": "CFG_INFO", "DATA": "6"},
      });
      print("📡 SHUTTER 현재값 조회 요청 전송");
      socket!.writeln(requestData);
      await socket!.flush();

      await Future.delayed(const Duration(milliseconds: 150));

      // 3. LED 설정
      requestData = jsonEncode({
        "header": "F001",
        "body": {"CMD": "AD_LED_CTRL", "DATA": "80,100"},
      });
      socket!.writeln(requestData);
      await socket!.flush();

      await Future.delayed(const Duration(milliseconds: 100));

      // 4. 촬영 시작
      requestData = jsonEncode({
        "header": "B001",
        "body": {"CMD": "CAM_CTRL", "DATA": "1"},
      });
      socket!.writeln(requestData);
      await socket!.flush();
      print("📡 CAM_CTRL 요청 전송");

      await Future.delayed(const Duration(seconds: 1));

      // 5. 이미지 전송 요청
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

      // 먼저 텍스트/JSON인지 확인
      try {
        final text = utf8.decode(frameData).trim();
        print("📩 수신 텍스트: $text");

        final decoded = jsonDecode(text);
        _handleDeviceResponse(decoded);

        continue;
      } catch (_) {
        // JSON 아니면 이미지로 처리
        print("🖼️ 이미지 데이터 수신");
        saveImage(frameData);
        break;
      }
    }
  }

  void _handleDeviceResponse(dynamic decoded) {
    try {
      final header = decoded["header"];
      final body = decoded["body"];
      final cmd = body["CMD"];
      final data = body["DATA"];

      print("📦 header=$header, cmd=$cmd, data=$data");

      // 셔터 설정 응답
      if (header == "C001" && cmd == "SHUTTER") {
        print("📷 장비 응답 SHUTTER 값: $data");
      }

      // 현재 설정값 조회 응답
      if (header == "A001" && cmd == "CFG_INFO") {
        print("📷 현재 조회된 SHUTTER 설정값: $data");
      }
    } catch (e) {
      print("❌ 응답 파싱 실패: $e");
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
              (context) => ResultSingle(
                userName: widget.userName,
                gender: widget.gender,
                sampleType: widget.sampleType,
                selectedItem: widget.selectedItem,
                age: widget.age,
                imagePath: filePath,
              ),
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
