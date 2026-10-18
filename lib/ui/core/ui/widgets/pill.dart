import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.bg = AppColor.primaryTint,
    this.fg = AppColor.primaryDark,
    this.fontSize = 10,
  });

  final String text;
  final Color bg;
  final Color fg;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.s9,
      vertical: AppSpace.s4,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: t(fontSize, w: FontWeight.w700, c: fg),
    ),
  );
}
