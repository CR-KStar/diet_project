import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';
import 'package:diet_project/ui/core/ui/icons/app_icons.dart';

/// 바텀 시트용 커스텀 스캐폴드
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onClose,
    this.leading,
    this.trailing,
    this.padding = 20,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onClose;

  /// 제목 왼쪽 아이콘 (예: 물방울 아이콘)
  final Widget? leading;

  /// 오른쪽 끝에 표시할 위젯 — 지정하면 닫기(✕) 버튼 대신 이걸 보여줍니다.
  final Widget? trailing;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColor.surface,
      borderRadius: AppRadius.sheetR,
    ),
    padding: EdgeInsets.fromLTRB(
      padding,
      14,
      padding,
      padding + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: AppSpace.s38,
            height: AppSpace.s4,
            margin: const EdgeInsets.only(bottom: AppSpace.s16),
            decoration: BoxDecoration(
              color: AppColor.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpace.s12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t(AppFontSize.f18, w: FontWeight.w900)),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      subtitle!,
                      style: t(AppFontSize.f12, c: AppColor.textFaint),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: AppSpace.s32,
                  height: AppSpace.s32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColor.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.close,
                    size: 18,
                    color: AppColor.textGhost,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s24),
        child,
      ],
    ),
  );
}
