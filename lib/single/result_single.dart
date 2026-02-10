import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mark4/DB/run_test_json_store.dart';
import 'package:mark4/class/run_test_data.dart';

class ResultSingle extends StatefulWidget {
  final String userName, age, gender, sampleType, selectedItem, imagePath;
  const ResultSingle({
    super.key,
    required this.userName,
    required this.gender,
    required this.sampleType,
    required this.selectedItem,
    required this.age,
    required this.imagePath,
  });

  @override
  State<ResultSingle> createState() => _ResultSingleState();
}

class _ResultSingleState extends State<ResultSingle> {
  final store = RunTestJsonStore();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveResultOnce();
  }

  Future<void> _saveResultOnce() async {
    if (_saved) return;
    _saved = true;

    await store.save(
      name: widget.userName,
      age: widget.age,
      gender: widget.gender,
      item: widget.selectedItem,
      sampleType: widget.sampleType,
      imagePath: widget.imagePath,
      result: _buildResultString(), // 예: "RSV 0.7 ng/mL"
    );
  }

  String _buildResultString() {
    // 👉 네 실제 결과 계산 로직에 맞게 수정
    return "0.7 ng/mL";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.contain,
          // height: 220, // ⬅️ 첫 번째 스샷 느낌
          width: double.infinity,
        ),
      ),
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
