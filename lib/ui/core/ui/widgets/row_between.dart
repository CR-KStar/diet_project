import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

class RowBetween extends StatelessWidget {
  const RowBetween(
    this.label,
    this.value, {
    super.key,
    this.valueColor = AppColor.text,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.s5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: t(AppFontSize.f12, c: AppColor.textFaint)),
        Text(
          value,
          style: t(AppFontSize.f12, w: FontWeight.w700, c: valueColor),
        ),
      ],
    ),
  );
}
