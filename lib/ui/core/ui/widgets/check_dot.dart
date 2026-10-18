import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';

class CheckDot extends StatelessWidget {
  const CheckDot({super.key, required this.on, this.size = 20, this.radius});

  final bool on;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: on ? AppColor.primary : const Color(0xFFEDEFF1),
      borderRadius: BorderRadius.circular(radius ?? size / 2),
    ),
    child: Icon(
      Icons.check_rounded,
      size: size * 0.66,
      color: on ? Colors.white : AppColor.iconGhost,
    ),
  );
}
