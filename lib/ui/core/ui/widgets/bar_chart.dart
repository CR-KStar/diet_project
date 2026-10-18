import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';
import 'package:diet_project/utils/app_state_format.dart';

/// 막대그래프
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.bars,
    this.height = 132,
    this.showValue = true,
  });

  final List<({String label, int value, int pct})> bars;
  final double height;
  final bool showValue;

  Color _color(int pct) => pct >= 85
      ? AppColor.alert
      : pct >= 70
      ? AppColor.primary
      : AppColor.secondary;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((b) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showValue)
                  Text(
                    AppStateFormat.comma(b.value),
                    style: t(AppFontSize.f9, c: AppColor.textGhost),
                  ),
                const SizedBox(height: AppSpace.s6),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: (b.pct / 100).clamp(0.02, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _color(b.pct),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7),
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s7),
                Text(b.label, style: t(AppFontSize.f10, c: AppColor.textFaint)),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}
