import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mark4/components/current_time.dart';
import 'package:mark4/run_test.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Socket? socket;
  final String iotDeviceIp = "192.168.0.72";

  bool hasMountedUsb() {
    final baseDirs = ['/media/cosmas', '/run/media/cosmas'];

    for (final base in baseDirs) {
      final dir = Directory(base);
      if (!dir.existsSync()) continue;

      final hasDir = dir.listSync().any((e) => e is Directory);

      if (hasDir) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F9FC), Color(0xFFE3EBF6)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getCurrentTime(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                getCurrentDate(),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            InkWell(
              onTap: () {
                _showPowerPopup(context);
              },
              child: Image.asset('images/powerButton.png', scale: 7),
            ),
            const SizedBox(width: 15),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ------------- RUN TEST + 하단 2개 버튼 -------------
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // RUN TEST (대형 버튼)
                      Container(
                        height: 210,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2F89FF), Color(0xFF1062F3)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RunTest(),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'images/run_test_icon.png',
                                  scale: 3,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "RUN TEST",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          // TEST RESULT
                          Expanded(
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF33D2C5),
                                    Color(0xFF28B6A7),
                                  ],
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    final connected = hasMountedUsb();

                                    if (connected) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('USB가 연결되어 있습니다'),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('USB를 연결해주세요')),
                                      );
                                    }
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'images/test_result_icon.png',
                                        scale: 5,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "TEST RESULT",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 20),

                          // SETTING
                          Expanded(
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF7D7D7D),
                                    Color(0xFF555555),
                                  ],
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {},
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'images/setting_icon.png',
                                        scale: 6,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "SETTING",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPowerPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "System Control",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2A4A),
                  ),
                ),
                const SizedBox(height: 20),

                // 종료 버튼
                _powerBtn(
                  text: "Shutdown",
                  color: const Color(0xFFE83C3C),
                  onTap: () {
                    powerOff();
                    Process.run('shutdown', ['-h', 'now']);
                  },
                ),
                const SizedBox(height: 12),

                // 재시작 버튼
                _powerBtn(
                  text: "Restart",
                  color: const Color(0xFF227BFF),
                  onTap: () {
                    Process.run('reboot', []);
                  },
                ),
                const SizedBox(height: 12),

                // 취소 버튼
                _powerBtn(
                  text: "Cancel",
                  color: const Color(0xFF6D6D6D),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _powerBtn({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> powerOff() async {
    try {
      // IoT 기기와 소켓 연결 (포트 9191)
      socket = await Socket.connect(iotDeviceIp, 9191);
      print("✅ IoT 기기와 연결 성공 (사진 촬영 요청)");

      // CAM_CTRL 요청 전송 (촬영 시작)
      var requestData = jsonEncode({
        "header": "F001",
        "body": {"CMD": "AD_PWR_OFF", "DATA": "1"},
      });
      socket!.writeln(requestData);
      await socket!.flush();
      print("📡 AD_PWR_OFF 요청 전송");
      await Future.delayed(const Duration(seconds: 3));
      socket?.close();
    } catch (e) {
      print("❌ IoT 기기 연결 실패: $e");
    }
  }
}
