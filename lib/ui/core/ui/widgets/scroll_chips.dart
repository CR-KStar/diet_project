import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

/// 가로 스크롤 칩 (알림 시간 선택 등)
class ScrollChips extends StatelessWidget {
  const ScrollChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSpace.s46,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s7),
      itemBuilder: (_, i) {
        final o = options[i];
        final on = o == value;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s14),
            decoration: BoxDecoration(
              color: on ? AppColor.primary : AppColor.surfaceSunken,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              o,
              style: t(
                AppFontSize.f13,
                w: on ? FontWeight.w900 : FontWeight.w500,
                c: on ? Colors.white : AppColor.textMuted,
              ),
            ),
          ),
        );
      },
    ),
  );
}
