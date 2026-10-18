import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

/// 확인 · 취소를 묻는 대화상자. 확인을 누르면 true, 그 밖(취소 · 바깥 터치)은 false.
/// [destructive]가 true면 확인 버튼을 경고 색으로 보여줍니다 (삭제처럼 되돌릴 수 없는 동작).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: t(AppFontSize.f16, w: FontWeight.w800)),
      content: Text(
        message,
        style: t(AppFontSize.f13, c: AppColor.textMuted, h: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('취소', style: t(AppFontSize.f14, c: AppColor.textFaint)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: t(
              AppFontSize.f14,
              w: FontWeight.w700,
              c: destructive ? AppColor.alertText : AppColor.primaryDark,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
