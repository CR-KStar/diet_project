import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/icon_tile.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

/// 하단 탭 루트 화면의 제목 행
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.icon,
    this.iconColor = AppColor.primary,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: AppSpace.s4,
      right: AppSpace.s4,
      bottom: AppSpace.s2,
    ),
    child: Row(
      children: [
        IconTile.icon(icon, size: 30, radius: 11, color: iconColor),
        const SizedBox(width: AppSpace.s9),
        Text(
          title,
          style: t(
            AppFontSize.f20,
            w: FontWeight.w900,
            c: AppColor.textStrong,
            sp: -0.3,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    ),
  );
}
