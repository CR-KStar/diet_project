import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/icon_tile.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.action,
    this.onAction,
    this.subtitle,
  });

  final String emoji;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          IconTile(emoji, size: 26, fontSize: 13),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Text(title, style: t(AppFontSize.f15, w: FontWeight.w900)),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: t(AppFontSize.f12, c: AppColor.textFaint),
              ),
            ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpace.s5),
        Text(subtitle!, style: t(AppFontSize.f11, c: AppColor.textGhost)),
      ],
    ],
  );
}
