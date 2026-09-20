// 영양소 상세 — 3대 영양소 비율 · 8종 카드 · 끼니별 분해

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

const _nutrientDetail = [
  (name: '단백질', val: 78, target: '100 g', pct: 78, color: AppColor.primary, note: '근육 유지에 충분한 수준', badge: '적정', b: '18g', l: '22g', d: '30g', sn: '8g'),
  (name: '탄수화물', val: 160, target: '220 g', pct: 73, color: AppColor.warn, note: '저녁에 현미로 보충 가능', badge: '적정', b: '52g', l: '58g', d: '42g', sn: '8g'),
  (name: '지방', val: 45, target: '60 g', pct: 75, color: AppColor.warnDeep, note: '견과류 섭취량 주의', badge: '적정', b: '9g', l: '16g', d: '16g', sn: '4g'),
  (name: '식이섬유', val: 18, target: '25 g', pct: 72, color: AppColor.teal, note: '채소 1접시 더 필요', badge: '부족', b: '4g', l: '5g', d: '7g', sn: '2g'),
  (name: '나트륨', val: 1450, target: '2,000 mg', pct: 73, color: AppColor.alert, note: '국물 음식 섭취 시 주의', badge: '적정', b: '210mg', l: '840mg', d: '350mg', sn: '50mg'),
  (name: '당류', val: 34, target: '50 g', pct: 68, color: Color(0xFFF48FB1), note: '간식 요거트가 대부분', badge: '적정', b: '6g', l: '4g', d: '8g', sn: '16g'),
  (name: '칼슘', val: 480, target: '700 mg', pct: 68, color: Color(0xFF90A4EE), note: '유제품 1회 더 권장', badge: '부족', b: '210mg', l: '60mg', d: '90mg', sn: '120mg'),
  (name: '철분', val: 11, target: '14 mg', pct: 79, color: Color(0xFFB08BE0), note: '붉은 고기로 충족', badge: '적정', b: '2mg', l: '4mg', d: '4mg', sn: '1mg'),
];

/// "3대 영양소 비율" 카드 + 8종 상세 카드 + 추천받기 버튼.
/// 영양소 상세 화면과 리포트(오늘) 탭에서 함께 씁니다.
List<Widget> nutrientDetailCards(BuildContext context) {
  final s = context.read<AppState>();

  return [
    // 3대 영양소 비율
    AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('3대 영양소 비율', style: t(14, w: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(children: [
          Ring(
            size: 112,
            thickness: 14,
            segments: const [
              (value: 0.26, color: AppColor.primary),
              (value: 0.48, color: AppColor.warn),
              (value: 0.26, color: AppColor.warnDeep),
            ],
            center: Container(
              width: 74,
              height: 74,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColor.surface, shape: BoxShape.circle),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('1,450', style: t(18, w: FontWeight.w900)),
                Text('kcal', style: t(9, c: AppColor.textFaint)),
              ]),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(children: [
              for (final r in const [
                ('단백질', '26%', AppColor.primary),
                ('탄수화물', '48%', AppColor.warn),
                ('지방', '26%', AppColor.warnDeep),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
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
                  ]),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('권장 비율 25 : 50 : 25 에 근접해요',
                    style: t(10, c: AppColor.textGhost, h: 1.5)),
              ),
            ]),
          ),
        ]),
      ]),
    ),

    // 8종 상세
    for (final n in _nutrientDetail)
      AppCard(
        padding: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(n.name, style: t(14, w: FontWeight.w700))),
            Text(AppState.comma(n.val),
                style: t(19,
                    w: FontWeight.w900,
                    c: n.badge == '부족' ? AppColor.alertText : AppColor.text)),
            const SizedBox(width: 4),
            Text('/ ${n.target}', style: t(11, c: AppColor.textFaint)),
          ]),
          const SizedBox(height: 11),
          ProgressBar(value: n.pct / 100, color: n.color, height: 8),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(n.note, style: t(11, c: AppColor.textMuted))),
            Pill(n.badge,
                bg: n.badge == '부족' ? const Color(0xFFFFF3EF) : AppColor.primaryTint,
                fg: n.badge == '부족' ? AppColor.alertText : AppColor.primaryDark),
          ]),
          const SizedBox(height: 11),
          const Divider(height: 1),
          const SizedBox(height: 11),
          Row(children: [
            for (final m in [('아침', n.b), ('점심', n.l), ('저녁', n.d), ('간식', n.sn)])
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.$1, style: t(9, c: AppColor.textGhost)),
                  const SizedBox(height: 3),
                  Text(m.$2, style: t(11, w: FontWeight.w700)),
                ]),
              ),
          ]),
        ]),
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
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('부족한 영양소로 식단 추천받기',
                  style: t(14, w: FontWeight.w900, c: Colors.white)),
              const SizedBox(height: 4),
              Text('식이섬유 · 칼슘이 부족해요',
                  style: t(11, c: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
          const Text('→', style: TextStyle(fontSize: 18, color: Colors.white)),
        ]),
      ),
    ),
  ];
}

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    return ScreenScroll(children: [
      SubHeader(
        emoji: '🥗',
        title: '영양소 상세',
        onBack: () => s.go('home'),
        trailing: Text('8월 19일', style: t(12, c: AppColor.textFaint)),
      ),
      ...nutrientDetailCards(context),
    ]);
  }
}
