import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: AppSize.buttonPad,
      decoration: AppDeco.primaryButton(enabled: enabled),
      child: Text(
        label,
        style: t(
          AppFontSize.f15,
          w: FontWeight.w700,
          c: enabled ? Colors.white : AppColor.textGhost,
        ),
      ),
    ),
  );
}
