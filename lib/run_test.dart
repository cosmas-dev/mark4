import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mark4/DB/database_helper.dart';
import 'package:mark4/components/current_time.dart';
import 'package:mark4/preparing.dart';

enum PopupType { channelMulti, channelSingle }

class RunTest extends StatefulWidget {
  const RunTest({super.key});

  @override
  State<RunTest> createState() => _RunTestState();
}

class _RunTestState extends State<RunTest> {
  int selectedChannel = 0;
  int openClose = 1;
  bool showPopup = false;
  PopupType? currentPopup;
  final List<String?> selectedItem = [null, null, null];

  Socket? socket;
  final String iotDeviceIp = "192.168.0.1";

  final List<TextEditingController> userIdController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<TextEditingController> ageController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<int?> gender = [null, null, null];

  final List<String> itemOptions = ['Flu', 'COVID19', 'RSV'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
          // 본 화면
          Scaffold(
            backgroundColor: const Color(0xFFEFF3F8),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                "     ${getCurrentTime()}     ${getCurrentDate()}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset('images/homeButton.png', scale: 8),
                ),
                const SizedBox(width: 15),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedChannel = 0;
                              currentPopup = PopupType.channelSingle;
                              showPopup = true;
                            });
                          },
                          child: Image.asset("images/kit1.png", scale: 8),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedChannel = 1;
                              currentPopup = PopupType.channelSingle;
                              showPopup = true;
                            });
                          },
                          child: Image.asset("images/kit2.png", scale: 8),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedChannel = 2;
                              currentPopup = PopupType.channelSingle;
                              showPopup = true;
                            });
                          },
                          child: Image.asset("images/kit3.png", scale: 8),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: Text(
                      "Idle",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A2A4A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _bottomButtons(),
          ),
          // 팝업 + 블러
          if (showPopup) _popupOverlay(),
        ],
      ),
    );
  }

  // ========================== UI PARTS =============================

  Widget _bottomButtons() {
    final Size size = MediaQuery.of(context).size;
    return Container(
      height: 100,
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
                      Image.asset("images/holder_icon.png", scale: 7),
                      const SizedBox(height: 4),
                      Text(
                        "Holder\nIn/Out",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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
              onTap: () {
                _popupContent();
              },
              child: Container(
                color: const Color(0xFF227BFF),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('images/start_icon.png', scale: 7),
                      const SizedBox(height: 10),
                      Text(
                        "Start",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
      socket = await Socket.connect(iotDeviceIp, 9191);
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

  // ===================== POPUP OVERLAY =====================

  Widget _popupOverlay() {
    return Positioned.fill(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 50),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom * 0.6,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withAlpha(64),
            child: Center(
              child: SingleChildScrollView(
                child:
                    currentPopup == PopupType.channelSingle
                        ? _popupContent1()
                        : _popupContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _popupContent() {
    return Material(
      color: Colors.transparent, // <- 주변에 하얀 테두리 생기지 않게
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== 상단 헤더 (그라데이션 바) =====
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
              child: const Text(
                "Channel Information",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // ===== 내용 부분 (흰색 바디) =====
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _popupRow(0),
                  const SizedBox(height: 10),
                  _popupRow(1),
                  const SizedBox(height: 10),
                  _popupRow(2),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_label("Item"), _dropdown()],
              ),
            ),

            // ===== 하단 버튼 영역 =====
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _popupBtn("Cancel", () {
                      setState(() => showPopup = false);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _popupBtn("Reset", () {
                      setState(() {
                        // UserID 초기화
                        for (var c in userIdController) {
                          c.clear();
                        }

                        // Age 초기화
                        for (var c in ageController) {
                          c.clear();
                        }

                        // Gender 초기화
                        gender = [null, null, null];
                      });
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _popupBtn("Next", () {
                      showPopup = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreparingPage(),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popupRow(int i) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (i == 0)
              const Text(
                "",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            const SizedBox(height: 23),
            Text("CH-${i + 1}"),
          ],
        ),
        const SizedBox(width: 10),
        // SizedBox(width: 50, child: Text("CH-${i + 1}")),

        // === User ID ===
        Expanded(
          child: Column(
            children: [
              if (i == 0)
                const Text(
                  "User ID*",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: userIdController[i],
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // === Age ===
        SizedBox(
          width: 50,
          child: Column(
            children: [
              if (i == 0)
                const Text(
                  "Age",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: ageController[i],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // === Gender ===
        Column(
          children: [
            if (i == 0)
              const Text(
                "Gender",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            Row(
              children: [
                Column(
                  children: [
                    Radio<int?>(
                      key: Key("gender_${i}_male"), // ★ 여기에 key 추가
                      value: 0,
                      groupValue: gender[i],
                      onChanged: (v) => setState(() => gender[i] = v),
                    ),
                    const Text("Male", style: TextStyle(fontSize: 10)),
                  ],
                ),
                Column(
                  children: [
                    Radio<int?>(
                      key: Key("gender_${i}_female"), // ★ 여기도 key 추가
                      value: 1,
                      groupValue: gender[i],
                      onChanged: (v) => setState(() => gender[i] = v),
                    ),
                    const Text("Female", style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _popupBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
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
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _popupContent1() {
    return Material(
      color: Colors.transparent,
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
                "CH-${selectedChannel + 1} information",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label("Item"),
                  _dropdown(),

                  _label("User ID *"),
                  _input(userIdController[selectedChannel]),

                  _label("Age"),
                  _input(ageController[selectedChannel], isNumber: true),

                  _label("Gender"),
                  Row(
                    children: [
                      _genderBtn("Male", 0),
                      const SizedBox(width: 12),
                      _genderBtn("Female", 1),
                    ],
                  ),
                ],
              ),
            ),

            // ===== Bottom Buttons =====
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _popupBtn("Apply", () async {
                      final db = DatabaseHelper();

                      await db.insertRunTest(
                        channel: selectedChannel + 1,
                        item: selectedItem[selectedChannel]!,
                        userId: userIdController[selectedChannel].text,
                        age: int.tryParse(ageController[selectedChannel].text),
                        gender:
                            gender[selectedChannel] == 0 ? 'Male' : 'Female',
                      );

                      setState(() => showPopup = false);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _popupBtn("Reset", () {
                      userIdController[selectedChannel].clear();
                      ageController[selectedChannel].clear();
                      setState(() => gender[selectedChannel] = null);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _popupBtn("Cancel", () {
                      setState(() => showPopup = false);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _input(TextEditingController c, {bool isNumber = false}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : null,
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  Widget _dropdown() {
    return SizedBox(
      height: 44,
      child: DropdownButtonFormField<String>(
        value: selectedItem[selectedChannel],
        items:
            itemOptions
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
        onChanged: (v) {
          setState(() {
            selectedItem[selectedChannel] = v;
          });
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Widget _genderBtn(String text, int value) {
    final selected = gender[selectedChannel] == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => gender[selectedChannel] = value),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? Colors.blue : Colors.black12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.blue : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
