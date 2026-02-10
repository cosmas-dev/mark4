import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:mark4/components/current_time.dart';
import 'package:mark4/single/preparing_single.dart';

class RunTestSingle extends StatefulWidget {
  const RunTestSingle({super.key});

  @override
  State<RunTestSingle> createState() => _RunTestSingleState();
}

class _RunTestSingleState extends State<RunTestSingle> {
  final FocusNode _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  int openClose = 1;
  bool showPopup = false;

  Socket? socket;
  final String iotDeviceIp = "192.168.0.72";

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? gender;
  String? selectedItem;
  String? sampleType;
  final List<String> itemOptions = ['Flu', 'COVID19', 'RSV'];
  final List<String> sampleTypeOptions = ['Blood', 'Saliva', 'Nasal'];

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
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          showPopup = true;
                        });
                      },
                      child: Image.asset("images/kit1.png", scale: 4),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: Text(
                      "Idle",
                      style: TextStyle(
                        fontSize: 25,
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
              onTap: () {
                setState(() {
                  // showPopup = true;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PreparingPageSingle(
                            userName: userNameController.text,
                            age: ageController.text,
                            gender: gender!,
                            sampleType: sampleType!,
                            selectedItem: selectedItem!,
                          ),
                    ),
                  );
                });
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
              child: SingleChildScrollView(child: _popupContent1()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _popupBtn(String text, VoidCallback onTap) {
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

  Widget _popupContent1() {
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
                  "CH-1 information",
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Sample type *"),
                        DropdownButtonFormField<String>(
                          value:
                              sampleTypeOptions.contains(sampleType)
                                  ? sampleType
                                  : null,
                          hint: Text(
                            "Select",
                            style: const TextStyle(fontSize: 20),
                          ),
                          validator: (v) {
                            if (v == null) return "Sample Type을 선택해주세요";
                            return null;
                          },
                          // 🔥 선택된 값 표시용
                          selectedItemBuilder: (context) {
                            return itemOptions.map((e) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    height: 0.5, // 👈 중요
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          items:
                              sampleTypeOptions
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            setState(() {
                              sampleType = v;
                            });
                          },
                          decoration: _dropdownDecoration().copyWith(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _label("Item"),
                    _dropdown(),

                    _label("User Name *"),
                    _input(userNameController),

                    _label("Age"),
                    _input(ageController, isNumber: true),

                    _label("Gender"),
                    FormField<int>(
                      validator: (_) {
                        if (gender == null) {
                          return "Gender를 선택해주세요";
                        }
                        return null;
                      },
                      builder: (state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _genderBtn("Male"),
                                const SizedBox(width: 12),
                                _genderBtn("Female"),
                              ],
                            ),
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  state.errorText!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
                        if (!_formKey.currentState!.validate()) {
                          return; // 🔥 여기서 끝
                        }
                        setState(() => showPopup = false);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _popupBtn("Reset", () {
                        setState(() {
                          // Form 에러/상태 초기화
                          _formKey.currentState?.reset();

                          // 현재 채널 값 초기화
                          userNameController.clear();
                          ageController.clear();
                          gender = null;
                          selectedItem = null;
                          sampleType = null;
                        });

                        // (선택) 키보드 내리기
                        FocusScope.of(context).unfocus();
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
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
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
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text(text, style: const TextStyle(fontSize: 30)),
    );
  }

  Widget _input(TextEditingController c, {bool isNumber = false}) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : null,
        decoration: const InputDecoration(border: InputBorder.none),
        style: const TextStyle(fontSize: 35),
      ),
    );
  }

  Widget _dropdown() {
    return DropdownButtonFormField<String>(
      value: selectedItem,
      validator: (v) {
        if (v == null) return "Item을 선택해주세요";
        return null;
      },
      // 🔥 선택된 값 표시용
      selectedItemBuilder: (context) {
        return itemOptions.map((e) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              e,
              style: const TextStyle(
                fontSize: 40,
                height: 0.5, // 👈 중요
              ),
            ),
          );
        }).toList();
      },
      items:
          itemOptions
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 40)),
                ),
              )
              .toList(),
      onChanged: (v) {
        setState(() {
          selectedItem = v;
        });
      },
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 12,
        ),
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
    );
  }

  Widget _genderBtn(String text) {
    final selected = gender == text;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => gender = text),

        child: Container(
          height: 80,
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
                fontSize: 35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
