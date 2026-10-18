import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: AppSize.chipPad,
      decoration: AppDeco.chip(selected: selected),
      child: Text(
        label,
        style: t(
          AppFontSize.f12,
          w: selected ? FontWeight.w700 : FontWeight.w500,
          c: selected ? AppColor.primaryDark : AppColor.textMuted,
        ),
      ),
    ),
  );
}
