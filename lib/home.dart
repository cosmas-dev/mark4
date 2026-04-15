import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mark4/components/current_time.dart';
import 'package:mark4/components/window_listener.dart';
import 'package:mark4/run_test_list_page.dart';
import 'package:mark4/single/run_test_single.dart';
import 'package:window_manager/window_manager.dart';

class Home extends StatefulWidget {
  final String ip;
  const Home({super.key, required this.ip});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final MyWindowListener _windowListener;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  static const int _requiredTaps = 7;
  static const Duration _tapTimeout = Duration(seconds: 2);

  Socket? socket;
  // final String iotDeviceIp = widget.ip;
  int shutterValue = 100000;
  static const int shutterStep = 10000;
  static const int shutterMin = 10000;
  static const int shutterMax = 1000000;

  List<int> _buffer = [];
  bool isLoadingShutter = false;
  bool isSendingShutter = false;

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
  void initState() {
    super.initState();
    _windowListener = MyWindowListener();
    windowManager.addListener(_windowListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchCurrentShutterValue();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(_windowListener);
    super.dispose();
  }

  Future<void> _ensureSocketConnected() async {
    if (socket != null) return;
    socket = await Socket.connect(widget.ip, 9191);

    socket!.listen(
      (data) {
        _buffer.addAll(data);
        _processBuffer();
      },
      onError: (error) {
        print("❌ Socket error: $error");
        socket?.destroy();
        socket = null;
      },
      onDone: () {
        print("🔌 Socket closed");
        socket = null;
      },
    );
  }

  Future<void> _sendCommand({
    required String header,
    required String cmd,
    required String data,
  }) async {
    await _ensureSocketConnected();

    final requestData = jsonEncode({
      "header": header,
      "body": {"CMD": cmd, "DATA": data},
    });

    print("📤 SEND -> $requestData");
    socket!.writeln(requestData);
    await socket!.flush();
  }

  void _processBuffer() {
    const int headerSize = 8;

    while (true) {
      if (_buffer.length < headerSize) break;

      final headerBytes = _buffer.sublist(0, headerSize);
      final frameSize = ByteData.sublistView(
        Uint8List.fromList(headerBytes),
      ).getUint64(0, Endian.little);

      if (_buffer.length < headerSize + frameSize) break;

      final frameData = _buffer.sublist(headerSize, headerSize + frameSize);
      _buffer = _buffer.sublist(headerSize + frameSize);

      try {
        final text = utf8.decode(frameData).trim();
        print("📩 RECV -> $text");

        final decoded = jsonDecode(text);
        _handleDeviceResponse(decoded);
      } catch (_) {
        print("🖼️ 이미지/비JSON 데이터 수신");
      }
    }
  }

  void _handleDeviceResponse(dynamic decoded) {
    try {
      final header = decoded["header"]?.toString();
      final body = decoded["body"];
      final cmd = body["CMD"]?.toString();
      final data = body["DATA"];

      print("📦 header=$header, cmd=$cmd, data=$data");

      if (header == "A001" && cmd == "CFG_INFO") {
        if (!mounted) return;

        int? parsedValue;

        // DATA가 Map으로 오는 경우
        if (data is Map<String, dynamic>) {
          final value = data["value"];
          if (value is int) {
            parsedValue = value;
          } else if (value != null) {
            parsedValue = int.tryParse(value.toString());
          }
        }
        // 혹시 숫자 하나만 오는 경우도 대비
        else if (data is int) {
          parsedValue = data;
        } else if (data != null) {
          parsedValue = int.tryParse(data.toString());
        }

        setState(() {
          isLoadingShutter = false;
          if (parsedValue != null) {
            shutterValue = parsedValue;
          }
        });

        print("📷 현재 셔터값 반영: $parsedValue");
        return;
      }

      if (header == "C001" && cmd == "SHUTTER") {
        if (!mounted) return;

        int? parsedValue;

        if (data is int) {
          parsedValue = data;
        } else if (data is Map<String, dynamic>) {
          final value = data["value"];
          if (value is int) {
            parsedValue = value;
          } else if (value != null) {
            parsedValue = int.tryParse(value.toString());
          }
        } else if (data != null) {
          parsedValue = int.tryParse(data.toString());
        }

        setState(() {
          isSendingShutter = false;
          if (parsedValue != null) {
            shutterValue = parsedValue;
          }
        });

        print("✅ SHUTTER 설정 응답: $data");
        return;
      }
    } catch (e) {
      print("❌ 응답 파싱 실패: $e");
      if (!mounted) return;
      setState(() {
        isLoadingShutter = false;
        isSendingShutter = false;
      });
    }
  }

  Future<void> fetchCurrentShutterValue() async {
    try {
      setState(() {
        isLoadingShutter = true;
      });

      await _sendCommand(header: "A001", cmd: "CFG_INFO", data: "6");

      // 3초 안에 응답 없으면 로딩 해제
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (isLoadingShutter) {
          setState(() {
            isLoadingShutter = false;
          });
          print("⚠️ 셔터 조회 응답 타임아웃");
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingShutter = false;
        });
      }
      print("❌ 셔터 조회 실패: $e");
    }
  }

  Future<void> setShutterValue(int value) async {
    final clamped = value.clamp(shutterMin, shutterMax);

    try {
      setState(() {
        isSendingShutter = true;
      });

      await _sendCommand(
        header: "C001",
        cmd: "SHUTTER",
        data: clamped.toString(),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (isSendingShutter) {
          setState(() {
            isSendingShutter = false;
          });
          print("⚠️ SHUTTER 설정 응답 타임아웃");
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSendingShutter = false;
      });
      print("❌ 셔터 설정 실패: $e");
    }
  }

  void decreaseShutter() {
    final nextValue = (shutterValue - shutterStep).clamp(
      shutterMin,
      shutterMax,
    );
    if (nextValue != shutterValue) {
      setState(() {
        shutterValue = nextValue;
      });
    }
  }

  void increaseShutter() {
    final nextValue = (shutterValue + shutterStep).clamp(
      shutterMin,
      shutterMax,
    );
    if (nextValue != shutterValue) {
      setState(() {
        shutterValue = nextValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final now = DateTime.now();

        if (_lastTapTime == null ||
            now.difference(_lastTapTime!) > _tapTimeout) {
          // 시간 초과 → 카운트 초기화
          _tapCount = 1;
        } else {
          _tapCount++;
        }

        _lastTapTime = now;

        if (_tapCount >= _requiredTaps) {
          _tapCount = 0;
          await _exitFullscreenByTap();
        }
      },
      child: Container(
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
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  getCurrentDate(),
                  style: const TextStyle(fontSize: 20, color: Colors.black54),
                ),
              ],
            ),
            actions: [
              InkWell(
                onTap: () {
                  _showPowerPopup(context);
                },
                child: Image.asset('images/powerButton.png', scale: 3),
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
                        Text(
                          "IP: ${widget.ip}",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        _buildShutterControlCard(),
                        const SizedBox(height: 24),
                        // RUN TEST (대형 버튼)
                        Container(
                          height: 310,
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
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => RunTest(),
                                //   ),
                                // );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => RunTestSingle(
                                          shutterSpeed: shutterValue.toString(),
                                          ip: widget.ip,
                                        ),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'images/run_test_icon.png',
                                    scale: 2,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "RUN TEST",
                                    style: TextStyle(
                                      fontSize: 40,
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
                                height: 200,
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
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => RunTestListPage(),
                                          ),
                                        );
                                      } else {
                                        // ScaffoldMessenger.of(
                                        //   context,
                                        // ).showSnackBar(
                                        //   SnackBar(
                                        //     content: Text('USB Not Found'),
                                        //   ),
                                        // );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => RunTestListPage(),
                                          ),
                                        );
                                      }
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'images/test_result_icon.png',
                                          scale: 3,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "TEST RESULT",
                                          style: TextStyle(
                                            fontSize: 26,
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
                                height: 200,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'images/setting_icon.png',
                                          scale: 4,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "SETTING",
                                          style: TextStyle(
                                            fontSize: 26,
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
      socket = await Socket.connect(widget.ip, 9191);
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

  Future<void> _exitFullscreenByTap() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      await windowManager.setFullScreen(false);
    }
  }

  Widget _buildShutterControlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SHUTTER SPEED",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2A4A),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Text(
                "Current Value",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const Spacer(),
              if (isLoadingShutter)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Text(
                  "$shutterValue",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1062F3),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isSendingShutter ? null : decreaseShutter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9EEF7),
                    foregroundColor: const Color(0xFF1A2A4A),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "-10000",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSendingShutter ? null : increaseShutter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9EEF7),
                    foregroundColor: const Color(0xFF1A2A4A),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "+10000",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      isSendingShutter
                          ? null
                          : () async {
                            await setShutterValue(shutterValue);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1062F3),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      isSendingShutter
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "APPLY",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isLoadingShutter ? null : fetchCurrentShutterValue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33D2C5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "REFRESH",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "Step: $shutterStep   Min: $shutterMin   Max: $shutterMax",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
