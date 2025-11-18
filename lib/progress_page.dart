import 'package:flutter/material.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> progress;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7), // 0~100%까지 걸리는 시간
    );

    progress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    controller.forward(); // 자동 시작
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(backgroundColor: const Color(0xFFEFF3F8)),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // _topBar(),
            // const SizedBox(height: 40),

            // ---------- Animated Progress ----------
            Center(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RingPainter(progress.value),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Text(
                          "${(progress.value * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2A4A),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 35),
            const Text(
              "Reading..",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2850A7),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Do not Open the Tray",
              style: TextStyle(fontSize: 14, color: Color(0xFF2B478B)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Custom Progress Ring Painter ----------
class RingPainter extends CustomPainter {
  final double progress;

  RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 18.0;
    final rect = Offset.zero & size;

    // Background ring
    final bgPaint =
        Paint()
          ..color = const Color(0xFFE4EAF4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Foreground progress ring
    final progressPaint =
        Paint()
          ..shader = const SweepGradient(
            colors: [Color(0xFF3C66F4), Color(0xFF3C66F4)],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arc
    final sweepAngle = 2 * 3.141592 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592 * 0.5,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
