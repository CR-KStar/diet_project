import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IconTile extends StatelessWidget {
  const IconTile(
    this.emoji, {
    super.key,
    this.size = 28,
    this.radius = 10,
    this.bg = AppColor.primaryTint,
    this.fontSize = 14,
    this.shadow = false,
  });

  final String emoji;
  final double size;
  final double radius;
  final Color bg;
  final double fontSize;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow ? AppShadow.tile : null,
    ),
    child: Text(emoji, style: TextStyle(fontSize: fontSize)),
  );
}
