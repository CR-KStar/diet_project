import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

/// 보조 액션 — 버튼 대신 조용한 텍스트 링크 (높이 46)
class TextLink extends StatelessWidget {
  const TextLink({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColor.textFaint,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      height: AppSize.textLinkHeight,
      child: Center(
        child: Text(label, style: t(AppFontSize.f12, c: color)),
      ),
    ),
  );
}
