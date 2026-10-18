import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

/// 균등 분할 세그먼트 (전체/반절/1/3 등)
class SegmentedRow extends StatelessWidget {
  const SegmentedRow({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: options.map((o) {
      final on = o == value;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: o == options.last ? 0 : 8),
          child: GestureDetector(
            onTap: () => onChanged(o),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
              decoration: BoxDecoration(
                color: on ? AppColor.primaryTint : AppColor.surfaceSunken,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: on ? AppColor.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                o,
                style: t(
                  AppFontSize.f13,
                  w: on ? FontWeight.w700 : FontWeight.w500,
                  c: on ? AppColor.primaryDark : AppColor.textFaint,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}
