import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 카드 안 옅은 서브 블록
class SunkenBox extends StatelessWidget {
  const SunkenBox({
    super.key,
    required this.child,
    this.padding = 13,
    this.radius = 18,
    this.color = AppColor.surfaceSunken,
  });

  final Widget child;
  final double padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}
