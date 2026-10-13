import 'package:flutter/material.dart';
import 'package:mark4/components/current_time.dart';
import 'package:mark4/single/run_test_single.dart';

class StripSelectPage extends StatelessWidget {
  final String shutterSpeed, ip;

  const StripSelectPage({
    super.key,
    required this.shutterSpeed,
    required this.ip,
  });

  void _selectSingle(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => RunTestSingle(shutterSpeed: shutterSpeed, ip: ip),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              "Dual Strip",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            content: const Text("준비 중입니다.", style: TextStyle(fontSize: 30)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(fontSize: 30)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "     ${getCurrentTime()}     ${getCurrentDate()}",
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Image.asset('images/homeButton.png', scale: 4),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Select Strip Type",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2A4A),
                ),
              ),
              const SizedBox(height: 40),
              _stripButton(
                label: "Single Strip",
                colors: const [Color(0xFF2F89FF), Color(0xFF1062F3)],
                onTap: () => _selectSingle(context),
              ),
              const SizedBox(height: 24),
              _stripButton(
                label: "Dual Strip",
                colors: const [Color(0xFF33D2C5), Color(0xFF28B6A7)],
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stripButton({
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
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
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
