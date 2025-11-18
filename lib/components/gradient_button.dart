import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final List<Color> colors;
  final VoidCallback onTap;
  final Widget child;
  final double height;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.colors,
    required this.onTap,
    required this.child,
    this.height = 60,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
