import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mark4/class/run_test_data.dart';

class Result extends StatefulWidget {
  final RunTestData runTestData;
  // final String imagePath;
  const Result({super.key, required this.runTestData});

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      body: SafeArea(
        child: Column(
          children: [
            /// ✅ 1. 상단 이미지 영역
            _capturedImage(),

            const SizedBox(height: 12),

            /// ✅ 2. 기존 결과 UI
            Expanded(child: _resultContent()),
          ],
        ),
      ),
    );
  }

  Widget _capturedImage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(child: Text("test")),
      // ClipRRect(
      //   borderRadius: BorderRadius.circular(14),
      //   child: Image.file(
      //     File(widget.imagePath),
      //     fit: BoxFit.contain,
      //     height: 220, // ⬅️ 첫 번째 스샷 느낌
      //     width: double.infinity,
      //   ),
      // ),
    );
  }

  Widget _resultContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 🔽 지금 쓰고 있는 결과 UI 전체를 여기로 이동
          // 예: CH-1 / CH-2 / CH-3 카드
          // completed 텍스트
          // 하단 버튼들
        ],
      ),
    );
  }
}
