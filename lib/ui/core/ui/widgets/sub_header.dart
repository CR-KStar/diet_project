import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/icon_tile.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

/// 서브 화면의 뒤로 + 제목 행
class SubHeader extends StatelessWidget {
  const SubHeader({
    super.key,
    required this.icon,
    this.iconColor = AppColor.primary,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onBack;
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
        if (onBack != null)
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: AppSpace.s26,
              height: AppSize.minTapTarget,
              alignment: Alignment.centerLeft,
              child: Text('‹', style: t(AppFontSize.f20, c: AppColor.text)),
            ),
          ),
        IconTile.icon(icon, color: iconColor),
        const SizedBox(width: AppSpace.s8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t(
              AppFontSize.f17,
              w: FontWeight.w900,
              c: AppColor.textStrong,
            ),
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    ),
  );
}
