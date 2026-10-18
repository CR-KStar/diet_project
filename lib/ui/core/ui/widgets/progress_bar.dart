import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColor.primary,
    this.height = AppSize.barBase,
    this.track = AppColor.divider,
    this.gradient,
  });

  final double value; // 0..1
  final Color color;
  final double height;
  final Color track;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: Container(
      height: height,
      color: track,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    ),
  );
}
