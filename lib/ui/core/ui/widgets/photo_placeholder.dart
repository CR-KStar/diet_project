import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 사진 플레이스홀더 — 대각선 스트라이프
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    required this.height,
    this.label,
    this.radius = 20,
    this.child,
  });

  final double height;
  final String? label;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5F6),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: CustomPaint(
      painter: _StripePainter(),
      child: Center(
        child:
            child ??
            (label == null
                ? null
                : Text(
                    label!,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      color: AppColor.textFaint,
                      letterSpacing: 0.5,
                    ),
                  )),
      ),
    ),
  );
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE9EDEF)
      ..strokeWidth = 10;
    for (double x = -size.height; x < size.width + size.height; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}
