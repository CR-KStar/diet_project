import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';
import '../../home/widgets/nutrient_detail_page.dart';

/// 리포트 화면
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: TabHeader(emoji: '📊', title: '리포트'),
            ),
            Text(
              s.todayDateLabel,
              style: t(AppFontSize.f12, c: AppColor.textFaint),
            ),
          ],
        ),
        SegmentedRow(
          options: const ['오늘', '주간', '월간'],
          value: s.period,
          onChanged: s.setPeriod,
        ),
        if (s.period == '오늘')
          ...nutrientDetailCards(context)
        else ...[
          const _CalorieBarCard(),
          const _WeightChangeCard(),
          const _ExerciseAndDeltaRow(),
          const _GoalAndRecordDaysRow(),
          const _PatternCard(),
          const _RecommendCard(),
        ],
      ],
    );
  }
}

String _kcalTitle(AppState s) => switch (s.period) {
  '오늘' => '오늘 섭취 칼로리',
  '월간' => '이번 달 섭취 칼로리',
  _ => '이번 주 섭취 칼로리',
};

class _CalorieBarCard extends StatelessWidget {
  const _CalorieBarCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _kcalTitle(s),
                style: t(AppFontSize.f15, w: FontWeight.w800),
              ),
              Text(
                s.periodDelta,
                style: t(
                  AppFontSize.f12,
                  w: FontWeight.w700,
                  c: AppColor.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s18),
          BarChart(bars: s.kcalBars),
          const SizedBox(height: AppSpace.s16),
          RowBetween('평균 섭취', '${s.avgKcal} kcal / 일'),
        ],
      ),
    );
  }
}

class _WeightChangeCard extends StatelessWidget {
  const _WeightChangeCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final weights = s.weightSeries.map((w) => w.kg).toList();
    final highKg = weights.reduce((a, b) => a > b ? a : b);
    final lowKg = weights.reduce((a, b) => a < b ? a : b);
    final delta = s.weightKg - s.weightSeries.first.kg;
    final remainKg = (s.weightKg - s.goalWeight).abs();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '체중 변화',
                  style: t(AppFontSize.f15, w: FontWeight.w800),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '목표 ${s.goalWeight.toStringAsFixed(1)}kg',
                    style: t(AppFontSize.f11, c: AppColor.textFaint),
                  ),
                  const SizedBox(height: AppSpace.s2),
                  Text(
                    '남은 ${remainKg.toStringAsFixed(1)}kg',
                    style: t(AppFontSize.f11, c: AppColor.textFaint),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                s.weightKg.toStringAsFixed(1),
                style: t(
                  28,
                  w: FontWeight.w900,
                  c: AppColor.textStrong,
                  sp: -0.8,
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Text('kg', style: t(AppFontSize.f13, c: AppColor.textFaint)),
              const SizedBox(width: AppSpace.s8),
              Text(
                '${delta <= 0 ? '-' : '+'}${delta.abs().toStringAsFixed(1)}kg ${delta <= 0 ? '↓' : '↑'}',
                style: t(
                  13,
                  w: FontWeight.w700,
                  c: delta <= 0 ? AppColor.primaryDark : AppColor.alertText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          WeightLineChart(series: s.weightSeries, goal: s.goalWeight),
          const SizedBox(height: AppSpace.s18),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '최고',
                      style: t(AppFontSize.f11, c: AppColor.textFaint),
                    ),
                    const SizedBox(height: AppSpace.s6),
                    Text(
                      '${highKg.toStringAsFixed(1)} kg',
                      style: t(AppFontSize.f14, w: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '최저',
                      style: t(AppFontSize.f11, c: AppColor.textFaint),
                    ),
                    const SizedBox(height: AppSpace.s6),
                    Text(
                      '${lowKg.toStringAsFixed(1)} kg',
                      style: t(AppFontSize.f14, w: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => s.go('weight'),
                  child: Column(
                    children: [
                      Text(
                        '눈바디',
                        style: t(AppFontSize.f11, c: AppColor.textFaint),
                      ),
                      const SizedBox(height: AppSpace.s6),
                      Text(
                        '3장 ›',
                        style: t(
                          14,
                          w: FontWeight.w800,
                          c: AppColor.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 평균 운동 시간 · 체중 변화(주간 델타) 두 통계 카드
class _ExerciseAndDeltaRow extends StatelessWidget {
  const _ExerciseAndDeltaRow();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final delta = s.weightKg - s.weightSeries.first.kg;
    final remainKg = (s.weightKg - s.goalWeight).abs();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '평균 운동 시간',
                    style: t(AppFontSize.f12, c: AppColor.textFaint),
                  ),
                  const SizedBox(height: AppSpace.s10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${s.avgExerciseMin}',
                        style: t(
                          24,
                          w: FontWeight.w900,
                          c: AppColor.textStrong,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s2),
                      Text(
                        '분',
                        style: t(AppFontSize.f12, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s6),
                  Text(
                    s.exerciseMinDelta == 0
                        ? (s.period == '주간' ? '지난주와 비슷해요' : '지난달과 비슷해요')
                        : '${s.exerciseMinDelta > 0 ? '+' : '-'}'
                              '${s.exerciseMinDelta.abs()}분 '
                              '${s.exerciseMinDelta > 0 ? '↑' : '↓'}',
                    style: t(
                      12,
                      w: FontWeight.w700,
                      c: s.exerciseMinDelta >= 0
                          ? AppColor.primaryDark
                          : AppColor.alertText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '체중 변화',
                    style: t(AppFontSize.f12, c: AppColor.textFaint),
                  ),
                  const SizedBox(height: AppSpace.s10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${delta <= 0 ? '-' : '+'}${delta.abs().toStringAsFixed(1)}',
                        style: t(
                          24,
                          w: FontWeight.w900,
                          c: AppColor.textStrong,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s2),
                      Text(
                        'kg',
                        style: t(AppFontSize.f12, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s6),
                  Text(
                    '목표까지 ${remainKg.toStringAsFixed(1)}kg',
                    style: t(AppFontSize.f12, c: AppColor.textFaint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 목표 달성률 · 기록 일수 두 통계 카드
class _GoalAndRecordDaysRow extends StatelessWidget {
  const _GoalAndRecordDaysRow();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '목표 달성률',
                    style: t(AppFontSize.f12, c: AppColor.textFaint),
                  ),
                  const SizedBox(height: AppSpace.s10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${s.achieveRate}',
                        style: t(
                          24,
                          w: FontWeight.w900,
                          c: AppColor.textStrong,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s2),
                      Text(
                        '%',
                        style: t(AppFontSize.f12, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s10),
                  ProgressBar(value: s.achieveRate / 100),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기록 일수',
                    style: t(AppFontSize.f12, c: AppColor.textFaint),
                  ),
                  const SizedBox(height: AppSpace.s10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${s.recordDays}',
                        style: t(
                          24,
                          w: FontWeight.w900,
                          c: AppColor.textStrong,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s2),
                      Text(
                        '일',
                        style: t(AppFontSize.f12, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s6),
                  Text(
                    '목표 ${s.recordGoalDays}일 달성',
                    style: t(
                      AppFontSize.f12,
                      w: FontWeight.w700,
                      c: AppColor.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('패턴 분석', style: t(AppFontSize.f15, w: FontWeight.w800)),
          const SizedBox(height: AppSpace.s6),
          RowBetween('가장 많이 먹은 음식', s.mostEatenFood),
          RowBetween('자주 쓴 그릇', s.mostUsedBowl),
          RowBetween('자주 쓴 소스', s.mostUsedSauce),
          RowBetween(
            '부족한 영양소',
            s.lackingNutrient,
            valueColor: AppColor.alertText,
          ),
        ],
      ),
    );
  }
}

class _RecommendCard extends StatelessWidget {
  const _RecommendCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      color: AppColor.primaryTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천 식단',
            style: t(
              AppFontSize.f15,
              w: FontWeight.w800,
              c: AppColor.primaryDark,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            s.recommendedMeal,
            style: t(AppFontSize.f13, c: AppColor.primaryDark, h: 1.5),
          ),
        ],
      ),
    );
  }
}
