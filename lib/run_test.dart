import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mark4/components/current_time.dart';
import 'package:mark4/preparing.dart';

class RunTest extends StatefulWidget {
  const RunTest({super.key});

  @override
  State<RunTest> createState() => _RunTestState();
}

class _RunTestState extends State<RunTest> {
  bool showPopup = false;

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
                        Image.asset("images/kit1.png", scale: 8),
                        Image.asset("images/kit2.png", scale: 8),
                        Image.asset("images/kit3.png", scale: 8),
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
                  _bottomButtons(),
                ],
              ),
            ),
          ),

          // 팝업 + 블러
          if (showPopup) _popupOverlay(),
        ],
      ),
    );
  }

  // ========================== UI PARTS =============================

  Widget _bottomButtons() {
    return Container(
      height: 90,
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
          _bottomButton(
            "Holder\nIn/Out",
            Icons.import_export,
            const Color(0xFF6B6B6B),
            () {},
          ),
          _bottomButton("Stop", Icons.close, const Color(0xFFE83C3C), () {}),
          _bottomButton("Start", Icons.play_arrow, const Color(0xFF227BFF), () {
            setState(() => showPopup = true);
          }),
        ],
      ),
    );
  }

  Widget _bottomButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: color,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            child: Center(child: SingleChildScrollView(child: _popupContent())),
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

            // ===== 하단 버튼 영역 =====
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
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
                    Radio(
                      value: 0,
                      groupValue: gender[i],
                      onChanged: (v) => setState(() => gender[i] = v!),
                    ),
                    const Text("Male", style: TextStyle(fontSize: 10)),
                  ],
                ),
                Column(
                  children: [
                    Radio(
                      value: 1,
                      groupValue: gender[i],
                      onChanged: (v) => setState(() => gender[i] = v!),
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
}
