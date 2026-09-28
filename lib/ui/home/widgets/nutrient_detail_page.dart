// 영양소 상세 — 3대 영양소 비율 · 8종 카드 · 끼니별 분해

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

/// 목표 대비 퍼센트에 맞춰 짧은 안내 문구를 만든다 — 음식별 코멘트 대신,
/// 지금 실제로 계산되는 값만으로 말할 수 있는 정도로 단순하게 표현한다.
String _nutrientNote(NutrientStat n) {
  if (n.value <= 0) return '아직 기록된 식단이 없어요';
  if (n.pct >= 100) return '오늘 목표치를 채웠어요';
  if (n.isLow) return '목표보다 꽤 부족해요';
  return '목표에 가까워지고 있어요';
}

/// 부족한(80% 미만) 영양소 중 최대 2개를 골라 안내 문구를 만든다.
String _lowNutrientSummary(List<NutrientStat> stats) {
  final low = stats.where((n) => n.isLow).map((n) => n.name).take(2).toList();
  return low.isEmpty ? '오늘 영양소를 골고루 채웠어요' : '${low.join(' · ')}이 부족해요';
}

/// "3대 영양소 비율" 카드 + 8종 상세 카드 + 추천받기 버튼.
/// 영양소 상세 화면과 리포트(오늘) 탭에서 함께 씁니다.
List<Widget> nutrientDetailCards(BuildContext context) {
  final s = context.watch<AppState>();
  final macro = s.macroRatio;

  return [
    // 3대 영양소 비율
    AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3대 영양소 비율', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              Ring(
                size: 112,
                thickness: 14,
                segments: [
                  (value: macro.proteinPct / 100, color: AppColor.primary),
                  (value: macro.carbPct / 100, color: AppColor.warn),
                  (value: macro.fatPct / 100, color: AppColor.warnDeep),
                ],
                center: Container(
                  width: 74,
                  height: 74,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColor.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppState.comma(s.intakeKcal),
                        style: t(18, w: FontWeight.w900),
                      ),
                      Text('kcal', style: t(9, c: AppColor.textFaint)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    for (final r in [
                      ('단백질', '${macro.proteinPct}%', AppColor.primary),
                      ('탄수화물', '${macro.carbPct}%', AppColor.warn),
                      ('지방', '${macro.fatPct}%', AppColor.warnDeep),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: r.$3,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r.$1, style: t(12))),
                            Text(r.$2, style: t(12, w: FontWeight.w700)),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '권장 비율 25 : 50 : 25 에 근접해요',
                        style: t(10, c: AppColor.textGhost, h: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),

    // 8종 상세
    for (final n in s.todayNutrientStats)
      AppCard(
        padding: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(n.name, style: t(14, w: FontWeight.w700)),
                ),
                Text(
                  AppState.comma(n.value.round()),
                  style: t(
                    19,
                    w: FontWeight.w900,
                    c: n.isLow ? AppColor.alertText : AppColor.text,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${AppState.comma(n.target.round())} ${n.unit}',
                  style: t(11, c: AppColor.textFaint),
                ),
              ],
            ),
            const SizedBox(height: 11),
            ProgressBar(
              value: n.target > 0 ? n.value / n.target : 0,
              color: n.color,
              height: 8,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _nutrientNote(n),
                    style: t(11, c: AppColor.textMuted),
                  ),
                ),
                Pill(
                  n.isLow ? '부족' : '적정',
                  bg: n.isLow ? const Color(0xFFFFF3EF) : AppColor.primaryTint,
                  fg: n.isLow ? AppColor.alertText : AppColor.primaryDark,
                ),
              ],
            ),
            const SizedBox(height: 11),
            const Divider(height: 1),
            const SizedBox(height: 11),
            Row(
              children: [
                for (final m in [
                  ('아침', n.breakfast),
                  ('점심', n.lunch),
                  ('저녁', n.dinner),
                  ('간식', n.snack),
                ])
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.$1, style: t(9, c: AppColor.textGhost)),
                        const SizedBox(height: 3),
                        Text(
                          '${AppState.comma(m.$2.round())}${n.unit}',
                          style: t(11, w: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),

    GestureDetector(
      onTap: () => s.go('recommend'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadow.primaryButton,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '부족한 영양소로 식단 추천받기',
                    style: t(14, w: FontWeight.w900, c: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lowNutrientSummary(s.todayNutrientStats),
                    style: t(11, c: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            const Text(
              '→',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    ),
  ];
}

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    return ScreenScroll(
      children: [
        SubHeader(
          emoji: '🥗',
          title: '영양소 상세',
          onBack: () => s.go('home'),
          trailing: Text(s.todayDateLabel, style: t(12, c: AppColor.textFaint)),
        ),
        ...nutrientDetailCards(context),
      ],
    );
  }
}
