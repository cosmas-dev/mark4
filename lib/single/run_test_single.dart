import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:mark4/components/current_time.dart';
import 'package:mark4/components/select_field.dart';
import 'package:mark4/single/preparing_single.dart';

class RunTestSingle extends StatefulWidget {
  final String shutterSpeed, ip;
  final bool dual;
  const RunTestSingle({
    super.key,
    required this.shutterSpeed,
    required this.ip,
    this.dual = false,
  });

  @override
  State<RunTestSingle> createState() => _RunTestSingleState();
}

class _RunTestSingleState extends State<RunTestSingle> {
  final _formKey = GlobalKey<FormState>();
  int openClose = 1;

  Socket? socket;
  // final String iotDeviceIp = "192.168.0.39";

  final TextEditingController userIdController = TextEditingController();
  final FocusNode _userIdFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _userIdFocus.addListener(_onUserIdFocusChanged);
  }

  @override
  void dispose() {
    _userIdFocus.dispose();
    _hideLinuxKeyboard();
    super.dispose();
  }

  void _onUserIdFocusChanged() {
    if (_userIdFocus.hasFocus) {
      _showLinuxKeyboard(restart: true);
    } else {
      _hideLinuxKeyboard();
    }
  }

  String? selectedItem;
  String? sampleType;
  final List<String> itemOptions = ['Flu', 'COVID19', 'RSV'];
  final List<String> sampleTypeOptions = ['Blood', 'Saliva', 'Nasal'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF3F8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "     ${getCurrentTime()}     ${getCurrentDate()}",
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          actions: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Image.asset('images/homeButton.png', scale: 4),
            ),
            const SizedBox(width: 20),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _infoForm(),
            ),
          ),
        ),
        bottomNavigationBar: _bottomButtons(),
      ),
    );
  }

  // ========================== UI PARTS =============================

  Widget _bottomButtons() {
    final Size size = MediaQuery.of(context).size;
    return Container(
      height: 200,
      width: size.width,
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
            flex: 1,
            child: InkWell(
              onTap: () {
                editIoTSettings();
              },
              child: Container(
                color: const Color(0xFF6B6B6B),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("images/holder_icon.png", scale: 3),
                      const SizedBox(height: 4),
                      Text(
                        "Holder\nIn/Out",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // _bottomButton("Stop", Icons.close, const Color(0xFFE83C3C), () {}),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                if (!_formKey.currentState!.validate()) return;
                await _hideLinuxKeyboard();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PreparingPageSingle(
                          shutterSpeed: widget.shutterSpeed,
                          userId: userIdController.text,
                          sampleType: sampleType!,
                          selectedItem: selectedItem ?? '',
                          ip: widget.ip,
                          dual: widget.dual,
                        ),
                  ),
                );
              },
              child: Container(
                color: const Color(0xFF227BFF),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('images/start_icon.png', scale: 3),
                      const SizedBox(height: 10),
                      Text(
                        "Start",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Future<void> editIoTSettings() async {
    try {
      // IoT 기기와 소켓 연결 (포트 9191)
      socket = await Socket.connect(widget.ip, 9191);
      print("✅ IoT 기기와 연결 성공 (사진 촬영 요청)");

      // CAM_CTRL 요청 전송 (촬영 시작)
      var requestData = jsonEncode({
        "header": "F001",
        "body": {"CMD": "AD_DR_CTRL", "DATA": "$openClose"},
      });
      socket!.writeln(requestData);
      await socket!.flush();
      print("📡 AD_DR_CTRL 요청 전송");
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        openClose = openClose == 1 ? 2 : 1;
      });
      // socket?.close();
    } catch (e) {
      print("❌ IoT 기기 연결 실패: $e");
    }
  }

  Widget _formBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6D6D6D), Color(0xFF464646)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoForm() {
    return Material(
      color: Colors.transparent,
      child: Form(
        key: _formKey,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== Header =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF777777), Color(0xFF555555)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Text(
                  widget.dual ? "Dual Strip information" : "CH-1 information",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Sample type *"),
                    SelectField(
                      options: sampleTypeOptions,
                      value: sampleType,
                      validator: (v) {
                        if (v == null) return "Sample Type을 선택해주세요";
                        return null;
                      },
                      onChanged: (v) => setState(() => sampleType = v),
                    ),
                    if (!widget.dual) ...[_label("Item"), _dropdown()],

                    _label("User ID *"),
                    _input(userIdController),
                  ],
                ),
              ),

              // ===== Bottom Buttons =====
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _formBtn("Reset", () async {
                        await _hideLinuxKeyboard();
                        setState(() {
                          userIdController.clear();
                          selectedItem = null;
                          sampleType = null;
                        });
                        // 값이 비워진 뒤에 폼을 리셋해야 선택 필드가 초기값(null)으로 돌아감
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _formKey.currentState?.reset(),
                        );

                        // (선택) 키보드 내리기
                        FocusScope.of(context).unfocus();
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text(text, style: const TextStyle(fontSize: 30)),
    );
  }

  Widget _input(TextEditingController c, {bool isNumber = false}) {
    return TextFormField(
      controller: c,
      focusNode: _userIdFocus,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textInputAction: TextInputAction.done,
      onTap: () async {
        await _showLinuxKeyboard();
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return "User ID를 입력해주세요";
        }
        return null;
      },
      style: const TextStyle(fontSize: 35, height: 1.2),
      strutStyle: const StrutStyle(
        fontSize: 35,
        height: 1.2,
        forceStrutHeight: true,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // 화면 키보드(squeekboard)는 포커스를 얻을 때 새로 띄우고, 포커스를 잃거나 화면을 나갈 때 종료한다.
  Future<void> _showLinuxKeyboard({bool restart = false}) async {
    if (!Platform.isLinux) return;
    try {
      if (restart) {
        await _hideLinuxKeyboard();
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        final running = await Process.run('pgrep', ['-x', 'squeekboard']);
        if (running.exitCode == 0) return;
      }
      await Process.start('squeekboard', [], mode: ProcessStartMode.detached);
    } catch (e) {
      debugPrint('squeekboard 실행 실패: $e');
    }
  }

  Future<void> _hideLinuxKeyboard() async {
    if (!Platform.isLinux) return;
    for (final name in ['onboard', 'matchbox-keyboard', 'squeekboard']) {
      try {
        await Process.run('pkill', [name]);
      } catch (_) {}
    }
  }

  Widget _dropdown() {
    return SelectField(
      options: itemOptions,
      value: selectedItem,
      validator: (v) {
        if (v == null) return "Item을 선택해주세요";
        return null;
      },
      onChanged: (v) => setState(() => selectedItem = v),
    );
  }

  // Widget _genderBtn(String text) {
  //   final selected = gender == text;
  //   return Expanded(
  //     child: InkWell(
  //       onTap: () => setState(() => gender = text),

  //       child: Container(
  //         height: 80,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: selected ? Colors.blue : Colors.black12),
  //         ),
  //         child: Center(
  //           child: Text(
  //             text,
  //             style: TextStyle(
  //               fontWeight: FontWeight.w600,
  //               color: selected ? Colors.blue : Colors.black,
  //               fontSize: 35,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
