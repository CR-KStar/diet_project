import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg = AppColor.primaryTint,
    this.fg = AppColor.primaryDark,
  });

  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s13,
        vertical: AppSpace.s9,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: t(AppFontSize.f11, w: FontWeight.w700, c: fg),
      ),
    ),
  );
}
