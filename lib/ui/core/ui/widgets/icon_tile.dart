import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';

/// 둥근 사각형 바탕 위의 작은 그림.
///
/// 화면이 정해 둔 자리의 아이콘은 [IconTile.icon]으로 Flutter 아이콘을, 식물 · 음식 · 사용자가
/// 고른 그릇처럼 "내용"인 그림은 기본 생성자로 이모지를 보여준다.
class IconTile extends StatelessWidget {
  /// 이모지로 보여준다 — 내용 자체가 그림일 때(식물, 음식, 그릇 …).
  const IconTile(
    this.emoji, {
    super.key,
    this.size = 28,
    this.radius = 10,
    this.bg = AppColor.primaryTint,
    this.fontSize = 14,
    this.shadow = false,
  }) : icon = null,
       color = AppColor.primary,
       iconSize = null;

  /// Flutter 아이콘으로 보여준다 — 메뉴 · 제목 · 버튼처럼 화면이 정해 둔 자리.
  const IconTile.icon(
    IconData this.icon, {
    super.key,
    this.size = 28,
    this.radius = 10,
    this.bg = AppColor.primaryTint,
    this.color = AppColor.primary,
    this.iconSize,
    this.shadow = false,
  }) : emoji = null,
       fontSize = 14;

  final String? emoji;
  final IconData? icon;
  final double size;
  final double radius;
  final Color bg;
  final Color color;

  /// 아이콘 크기 — 정하지 않으면 타일 크기의 절반 남짓.
  final double? iconSize;
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
    child: icon != null
        ? Icon(icon, size: iconSize ?? size * 0.56, color: color)
        : Text(emoji!, style: TextStyle(fontSize: fontSize)),
  );
}
