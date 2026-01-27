import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mark4/class/run_test_data.dart';
import 'package:mark4/components/current_time.dart';
import 'package:mark4/home.dart';
import 'package:mark4/progress_page.dart';

class PreparingPage extends StatefulWidget {
  final RunTestData runTestData;
  const PreparingPage({super.key, required this.runTestData});

  @override
  State<PreparingPage> createState() => _PreparingPageState();
}

class _PreparingPageState extends State<PreparingPage> {
  Timer? slideTimer;
  int currentPage = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();

    slideTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted) return;

      int nextPage = currentPage + 1;

      // 마지막 페이지면 첫 페이지로
      if (nextPage > 2) nextPage = 0;

      pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    slideTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "     ${getCurrentTime()}     ${getCurrentDate()}",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Home()),
                (route) => false,
              );
            },
            child: Image.asset('images/homeButton.png', scale: 8),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  padding: const EdgeInsets.symmetric(
                    vertical: 25,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        // color: Colors.black.withOpacity(0.08),
                        color: Colors.black.withAlpha(20),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: // ---------- 슬라이드 카드 영역 ----------
                      SizedBox(
                    height: 480,
                    child: Column(
                      children: [
                        // -------- PageView --------
                        Expanded(
                          child: PageView(
                            controller: pageController,
                            onPageChanged: (i) {
                              setState(() => currentPage = i);
                            },
                            children: [
                              _imageGridPage1(),
                              _imageGridPage2(),
                              _imageGridPage3(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // -------- Indicator --------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(active: currentPage == 0),
                            const SizedBox(width: 8),
                            _dot(active: currentPage == 1),
                            const SizedBox(width: 8),
                            _dot(active: currentPage == 2),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomButtons(),
    );
  }

  // ====================== IMAGE GRID ======================
  Widget _imageGridPage1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Preparing",
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF1A2A4A),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),

        const Text(
          "1. With a saliva collector\n   saliva as shown in the picture below",
          style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF1A2A4A)),
        ),
        const SizedBox(height: 25),
        // Row(
        //   children: [
        //     Expanded(child: _imgBox(number: "①")),
        //     const SizedBox(width: 12),
        //     Expanded(child: _imgBox(number: "②")),
        //   ],
        // ),
        // const SizedBox(height: 12),
        // Row(
        //   children: [
        //     Expanded(child: _imgBox(number: "③")),
        //     const SizedBox(width: 12),
        //     Expanded(child: _imgBox(number: "④")),
        //   ],
        // ),
        Image.asset("images/2.png"),
      ],
    );
  }

  Widget _imageGridPage2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Preparing",
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF1A2A4A),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),

        const Text(
          "2. Press the collector into the\n   multi-diagnosiskit Please add \"saliva\"",
          style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF1A2A4A)),
        ),
        const SizedBox(height: 25),
        Image.asset('images/4.png'),
      ],
    );
  }

  Widget _imageGridPage3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Preparing",
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF1A2A4A),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),

        const Text(
          "3. Please select Lorem Ipsum",
          style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF1A2A4A)),
        ),
        const SizedBox(height: 25),
        const Text("• If the test is completed from outside, press"),
        const SizedBox(height: 12),
        const Text(
          "• If you want the test time to be completed\n  within the Reader, press",
        ),
      ],
    );
  }

  Widget _imgBox({required String number}) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3F0)),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF1A2A4A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 이미지자리
          const Center(
            child: Text("Image", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _dot({required bool active}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1A2A4A) : Colors.grey[400],
        shape: BoxShape.circle,
      ),
    );
  }

  // ======================= BOTTOM BUTTONS =======================
  Widget _bottomButtons() {
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ProgressPage(runTestData: widget.runTestData),
                  ),
                );
              },
              child: Container(
                color: const Color(0xFF227BFF),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 28),
                      SizedBox(height: 4),
                      Text(
                        "Run",
                        style: TextStyle(color: Colors.white, fontSize: 14),
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
                  colors: [Color(0xFF1FD2C8), Color(0xFF2AF598)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Center(
                child: Text(
                  "Auto Contdown",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
