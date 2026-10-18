import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

/// 화면 상단 알약 탭 (식물/도감, 활동/챌린지/친구 추가, 알림/개인정보)
/// 카테고리 필터 — 글자 크기만큼만 차지하는 알약 버튼(전체 너비를 채우지 않음).
/// 알림/오늘의 미션처럼 항목 수가 가변적인 필터에 씁니다. 가로로 넘치면 스크롤돼요.
class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final o in options) ...[
          GestureDetector(
            onTap: () => onChanged(o),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s16,
                vertical: AppSpace.s9,
              ),
              decoration: BoxDecoration(
                color: o == value ? AppColor.primary : AppColor.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: o == value ? null : AppShadow.card,
              ),
              child: Text(
                o,
                style: t(
                  AppFontSize.f12,
                  w: o == value ? FontWeight.w700 : FontWeight.w500,
                  c: o == value ? Colors.white : AppColor.textFaint,
                ),
              ),
            ),
          ),
          if (o != options.last) const SizedBox(width: AppSpace.s8),
        ],
      ],
    ),
  );
}
