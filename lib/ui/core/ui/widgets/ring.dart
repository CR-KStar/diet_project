import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 도넛 링 — 홈 칼로리, 영양소 비율, 식물 축
class Ring extends StatelessWidget {
  const Ring({
    super.key,
    required this.size,
    required this.segments,
    this.thickness = 11,
    this.track = const Color(0xFFE9F0EA),
    this.center,
  });

  final double size;

  /// (비율 0..1, 색) 목록 — 순서대로 이어 그립니다.
  final List<({double value, Color color})> segments;
  final double thickness;
  final Color track;
  final Widget? center;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _RingPainter(
        segments: segments,
        thickness: thickness,
        track: track,
      ),
      child: center == null ? null : Center(child: center),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.segments,
    required this.thickness,
    required this.track,
  });

  final List<({double value, Color color})> segments;
  final double thickness;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = math.pi * 2 * s.value.clamp(0, 1);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = s.color;
      canvas.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}
