import 'package:flutter/material.dart';

class InputTestInfo extends StatefulWidget {
  final VoidCallback onClose;

  const InputTestInfo({super.key, required this.onClose});

  @override
  State<InputTestInfo> createState() => _InputTestInfoState();
}

class _InputTestInfoState extends State<InputTestInfo> {
  final userId = ["kim", "ju", "sw"];
  final age = ["30", "30", "30"];
  final gender = [1, 1, 1]; // 0 male, 1 female

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------------- Header ----------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF777777), Color(0xFF555555)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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

          // ------------- Content -------------
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildHeaderRow(),
                const SizedBox(height: 10),
                _buildRow(0),
                const SizedBox(height: 10),
                _buildRow(1),
                const SizedBox(height: 10),
                _buildRow(2),
              ],
            ),
          ),

          // ------------- Buttons -------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(child: _actionBtn("Cancel", widget.onClose)),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn("Reset", () {})),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn("Next", () {})),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: const [
        SizedBox(width: 60),
        Expanded(
          child: Text(
            "User ID*",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text("Age", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 20),
        Text("Gender", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRow(int i) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text("CH-${i + 1}")),

        // ID 입력
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: TextField(
              controller: TextEditingController(text: userId[i]),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // AGE 입력
        SizedBox(
          width: 50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: TextField(
              controller: TextEditingController(text: age[i]),
              decoration: const InputDecoration(border: InputBorder.none),
              keyboardType: TextInputType.number,
            ),
          ),
        ),

        const SizedBox(width: 18),

        // Gender
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
    );
  }

  Widget _actionBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6D6D6D), Color(0xFF464646)],
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
