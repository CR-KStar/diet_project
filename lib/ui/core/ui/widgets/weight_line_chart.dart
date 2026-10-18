import 'dart:math' as math;
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

/// 체중 라인 그래프 (목표선 점선 + 영역 채우기)
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({
    super.key,
    required this.series,
    required this.goal,
    this.height = 128,
  });

  final List<({String label, double kg})> series;
  final double goal;
  final double height;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(series: series, goal: goal),
        ),
      ),
      const SizedBox(height: AppSpace.s10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: series
            .map(
              (s) => Text(
                s.label,
                style: t(AppFontSize.f10, c: AppColor.textGhost),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.series, required this.goal});

  final List<({String label, double kg})> series;
  final double goal;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final values = series.map((s) => s.kg).toList();
    final lo = math.min(values.reduce(math.min), goal) - 0.4;
    final hi = values.reduce(math.max) + 0.4;

    double y(double v) => 12 + (hi - v) / (hi - lo) * (size.height - 24);
    double x(int i) => 6 + i * ((size.width - 12) / (series.length - 1));

    // 가이드 라인
    final guide = Paint()
      ..color = AppColor.divider
      ..strokeWidth = 1;
    for (final gy in [12.0, size.height / 2, size.height - 12]) {
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), guide);
    }

    // 목표선 (점선)
    final gp = Paint()
      ..color = AppColor.secondary
      ..strokeWidth = 1.5;
    final gyGoal = y(goal);
    for (double dx = 0; dx < size.width; dx += 10) {
      canvas.drawLine(Offset(dx, gyGoal), Offset(dx + 5, gyGoal), gp);
    }

    // 영역 + 선
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    final area = Path.from(path)
      ..lineTo(x(values.length - 1), size.height)
      ..lineTo(x(0), size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColor.primary.withValues(alpha: 0.10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColor.primary,
    );

    // 마지막 점
    final last = Offset(x(values.length - 1), y(values.last));
    canvas.drawCircle(last, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      last,
      4.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColor.primary,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}
