// 식단 추천 — 부족 영양소 · 끼니 · 선호 · 칼로리 상한 조건으로 추천

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

class RecommendScreen extends StatelessWidget {
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final recs = s.recommendations;

    return ScreenScroll(
      children: [
        SubHeader(emoji: '✨', title: '식단 추천', onBack: () => s.go('nutrition')),
        const _RemainingAllowanceCard(),
        const _NeedsCard(),
        const _ConditionsCard(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
          child: Row(
            children: [
              Text(
                '추천 ${recs.length}개',
                style: t(AppFontSize.f15, w: FontWeight.w700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: s.loadingRecommendations
                    ? null
                    : () async {
                        if (await ensureAiConsent(context, s)) {
                          await s.fetchAiRecommendations();
                        }
                      },
                child: Text(
                  s.loadingRecommendations ? 'AI 추천 새로고침 중...' : 'AI 추천 새로고침',
                  style: t(
                    AppFontSize.f11,
                    c: AppColor.primary,
                    w: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
          child: Text(
            '${s.recMeal} · ${AppState.comma(s.recMaxKcal)}kcal 이하',
            style: t(AppFontSize.f11, c: AppColor.textFaint),
          ),
        ),
        if (s.loadingRecommendations && recs.isEmpty)
          const AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.s24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpace.s12),
                    Text('AI가 조건에 맞는 식단을 찾고 있어요...'),
                  ],
                ),
              ),
            ),
          )
        else if (s.recommendationError != null)
          AppCard(
            child: Text(
              s.recommendationError!,
              style: t(AppFontSize.f12, c: AppColor.alertText, h: 1.6),
            ),
          )
        else if (recs.isEmpty)
          AppCard(
            child: Text(
              '조건에 맞는 식단이 없어요. 칼로리 상한을 올리거나 선호를 줄여보세요.',
              style: t(AppFontSize.f12, c: AppColor.textFaint, h: 1.6),
            ),
          ),
        for (final r in recs) _RecommendationCard(r: r, s: s),
        const _ComboCard(),
      ],
    );
  }
}

class _RemainingAllowanceCard extends StatelessWidget {
  const _RemainingAllowanceCard();

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColor.primaryTint,
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘 남은 여유',
          style: t(
            AppFontSize.f13,
            w: FontWeight.w700,
            c: AppColor.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Row(
          children: [
            for (final r in const [
              ('칼로리', '350'),
              ('단백질', '22g'),
              ('식이섬유', '7g'),
            ])
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.$1,
                      style: t(AppFontSize.f11, c: AppColor.textFaint),
                    ),
                    const SizedBox(height: AppSpace.s6),
                    Text(
                      r.$2,
                      style: t(
                        AppFontSize.f20,
                        w: FontWeight.w800,
                        c: AppColor.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s14),
        Text(
          '식이섬유 · 칼슘을 채우는 저녁 메뉴를 5개 골랐어요.',
          style: t(AppFontSize.f12, c: AppColor.primaryDark, h: 1.5),
        ),
      ],
    ),
  );
}

class _NeedsCard extends StatelessWidget {
  const _NeedsCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('보충할 영양소', style: t(AppFontSize.f13, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s5),
          Text(
            '부족한 항목은 미리 선택돼 있어요',
            style: t(AppFontSize.f11, c: AppColor.textGhost),
          ),
          const SizedBox(height: AppSpace.s12),
          ChipWrap(
            options: AppState.needOptions,
            isSelected: s.needs.contains,
            onPick: s.toggleNeed,
          ),
        ],
      ),
    );
  }
}

class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('조건', style: t(AppFontSize.f13, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s12),
          SegmentedRow(
            options: const ['아침', '점심', '저녁', '간식'],
            value: s.recMeal,
            onChanged: s.setRecMeal,
          ),
          const SizedBox(height: AppSpace.s12),
          ChipWrap(
            options: const ['채식 위주', '고단백', '저나트륨', '간편식', '외식 가능'],
            isSelected: s.recPrefs.contains,
            onPick: s.togglePref,
          ),
          const SizedBox(height: AppSpace.s16),
          Row(
            children: [
              Text('칼로리 상한', style: t(AppFontSize.f12, c: AppColor.textFaint)),
              const Spacer(),
              Text(
                '${AppState.comma(s.recMaxKcal)} kcal',
                style: t(
                  AppFontSize.f13,
                  w: FontWeight.w900,
                  c: AppColor.primary,
                ),
              ),
            ],
          ),
          DragSlider(
            value: s.recMaxKcal.toDouble(),
            min: 200,
            max: 800,
            step: 20,
            onChanged: (v) => s.setRecMaxKcal(v.round()),
          ),
          const SizedBox(height: AppSpace.s6),
          SegmentedRow(
            options: const ['추천순', '칼로리 낮은 순'],
            value: s.recSort,
            onChanged: s.setRecSort,
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.r, required this.s});

  final ({MealSuggestion meal, int score, bool offMeal}) r;
  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 15,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(
              r.meal.emoji,
              size: 56,
              radius: 18,
              bg: AppColor.surfaceSunken,
              fontSize: 26,
            ),
            const SizedBox(width: AppSpace.s13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.meal.name,
                          style: t(AppFontSize.f14, w: FontWeight.w700),
                        ),
                      ),
                      Pill('${r.score}%', fontSize: 10),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s5),
                  Text(
                    r.meal.meta,
                    style: t(AppFontSize.f11, c: AppColor.textFaint, h: 1.45),
                  ),
                  const SizedBox(height: AppSpace.s6),
                  Row(
                    children: [
                      Pill(
                        r.meal.tag,
                        bg: AppColor.surfaceSunken,
                        fg: AppColor.textMuted,
                        fontSize: 10,
                      ),
                      const Spacer(),
                      Text(
                        '${r.meal.kcal} kcal',
                        style: t(AppFontSize.f13, w: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s11),
        SunkenBox(
          padding: 11,
          radius: 14,
          child: Text(
            r.offMeal
                ? '${r.meal.why} (${r.meal.meals.join('·')} 메뉴예요)'
                : r.meal.why,
            style: t(AppFontSize.f11, c: AppColor.textMuted, h: 1.55),
          ),
        ),
        const SizedBox(height: AppSpace.s11),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: r.meal.covers
              .map(
                (c) => Pill(
                  '+$c',
                  bg: s.needs.contains(c)
                      ? AppColor.primaryTint
                      : AppColor.surfaceSunken,
                  fg: s.needs.contains(c)
                      ? AppColor.primaryDark
                      : AppColor.textFaint,
                  fontSize: 10,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpace.s12),
        GestureDetector(
          onTap: () {
            s.go('capture');
            s.setSub(() => s.extraOpen = true);
            toast(context, '“${r.meal.name}”을 ${s.recMeal} 기록으로 불러왔어요');
          },
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
            decoration: BoxDecoration(
              color: AppColor.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColor.primary, width: 1.5),
            ),
            child: Text(
              '이 식단으로 기록하기',
              style: t(
                AppFontSize.f12,
                w: FontWeight.w700,
                c: AppColor.primaryDark,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ComboCard extends StatelessWidget {
  const _ComboCard();

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이런 조합도 좋아요', style: t(AppFontSize.f15, w: FontWeight.w800)),
        const SizedBox(height: AppSpace.s4),
        Text(
          '최근 기록에서 자주 먹은 음식에 하나만 더하기',
          style: t(AppFontSize.f11, c: AppColor.textFaint),
        ),
        const SizedBox(height: AppSpace.s14),
        for (final combo in const [
          ('🥦', '브로콜리 한 컵', '식이섬유 +5g · 35kcal', false),
          ('🧀', '코티지 치즈 100g', '칼슘 +90mg · 단백질 11g · 98kcal', false),
          ('🥜', '아몬드 15알', '비타민E · 식이섬유 +2g · 105kcal', true),
        ])
          _ComboRow(combo: combo),
      ],
    ),
  );
}

class _ComboRow extends StatelessWidget {
  const _ComboRow({required this.combo});

  final (String, String, String, bool) combo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: combo.$4 ? 0 : 10),
    child: SunkenBox(
      padding: 12,
      radius: 14,
      child: Row(
        children: [
          IconTile(
            combo.$1,
            size: 40,
            radius: 14,
            bg: AppColor.surface,
            fontSize: 18,
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(combo.$2, style: t(AppFontSize.f13, w: FontWeight.w700)),
                const SizedBox(height: AppSpace.s3),
                Text(
                  combo.$3,
                  style: t(AppFontSize.f11, c: AppColor.textFaint),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => toast(context, '“${combo.$2}”을 담았어요'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s16,
                vertical: AppSpace.s10,
              ),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadow.card,
              ),
              child: Text(
                '담기',
                style: t(AppFontSize.f12, w: FontWeight.w700, c: AppColor.text),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
