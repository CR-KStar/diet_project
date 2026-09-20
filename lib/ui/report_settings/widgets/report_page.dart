import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';
import '../../home/widgets/nutrient_detail_pgae.dart';

/// 리포트 화면
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    final weights = s.weightSeries.map((w) => w.kg).toList();
    final highKg = weights.reduce((a, b) => a > b ? a : b);
    final lowKg = weights.reduce((a, b) => a < b ? a : b);
    final delta = s.weightKg - s.weightSeries.first.kg;
    final remainKg = (s.weightKg - s.goalWeight).abs();

    final kcalTitle = switch (s.period) {
      '오늘' => '오늘 섭취 칼로리',
      '월간' => '이번 달 섭취 칼로리',
      _ => '이번 주 섭취 칼로리',
    };

    return ScreenScroll(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(child: TabHeader(emoji: '📊', title: '리포트')),
          Text('8월 19일', style: t(12, c: AppColor.textFaint)),
        ],
      ),

      SegmentedRow(
        options: const ['오늘', '주간', '월간'],
        value: s.period,
        onChanged: s.setPeriod,
      ),

      if (s.period == '오늘') ...nutrientDetailCards(context) else ...[
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(kcalTitle, style: t(15, w: FontWeight.w800)),
              Text(s.periodDelta, style: t(12, w: FontWeight.w700, c: AppColor.primaryDark)),
            ]),
            const SizedBox(height: 18),
            BarChart(bars: s.kcalBars),
            const SizedBox(height: 16),
            RowBetween('평균 섭취', '${s.avgKcal} kcal / 일'),
          ]),
        ),

        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text('체중 변화', style: t(15, w: FontWeight.w800))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('목표 ${s.goalWeight.toStringAsFixed(1)}kg', style: t(11, c: AppColor.textFaint)),
                const SizedBox(height: 2),
                Text('남은 ${remainKg.toStringAsFixed(1)}kg', style: t(11, c: AppColor.textFaint)),
              ]),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(s.weightKg.toStringAsFixed(1), style: t(28, w: FontWeight.w900, c: AppColor.textStrong, sp: -0.8)),
              const SizedBox(width: 3),
              Text('kg', style: t(13, c: AppColor.textFaint)),
              const SizedBox(width: 8),
              Text(
                '${delta <= 0 ? '-' : '+'}${delta.abs().toStringAsFixed(1)}kg ${delta <= 0 ? '↓' : '↑'}',
                style: t(13, w: FontWeight.w700, c: delta <= 0 ? AppColor.primaryDark : AppColor.alertText),
              ),
            ]),
            const SizedBox(height: 16),
            WeightLineChart(series: s.weightSeries, goal: s.goalWeight),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Column(children: [
                  Text('최고', style: t(11, c: AppColor.textFaint)),
                  const SizedBox(height: 6),
                  Text('${highKg.toStringAsFixed(1)} kg', style: t(14, w: FontWeight.w800)),
                ]),
              ),
              Expanded(
                child: Column(children: [
                  Text('최저', style: t(11, c: AppColor.textFaint)),
                  const SizedBox(height: 6),
                  Text('${lowKg.toStringAsFixed(1)} kg', style: t(14, w: FontWeight.w800)),
                ]),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => s.go('weight'),
                  child: Column(children: [
                    Text('눈바디', style: t(11, c: AppColor.textFaint)),
                    const SizedBox(height: 6),
                    Text('3장 ›', style: t(14, w: FontWeight.w800, c: AppColor.primaryDark)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),

        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('평균 운동 시간', style: t(12, c: AppColor.textFaint)),
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('${s.avgExerciseMin}', style: t(24, w: FontWeight.w900, c: AppColor.textStrong)),
                    const SizedBox(width: 2),
                    Text('분', style: t(12, c: AppColor.textFaint)),
                  ]),
                  const SizedBox(height: 6),
                  Text('+${s.exerciseMinDelta}분 ↑', style: t(12, w: FontWeight.w700, c: AppColor.primaryDark)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('체중 변화', style: t(12, c: AppColor.textFaint)),
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text(
                      '${delta <= 0 ? '-' : '+'}${delta.abs().toStringAsFixed(1)}',
                      style: t(24, w: FontWeight.w900, c: AppColor.textStrong),
                    ),
                    const SizedBox(width: 2),
                    Text('kg', style: t(12, c: AppColor.textFaint)),
                  ]),
                  const SizedBox(height: 6),
                  Text('목표까지 ${remainKg.toStringAsFixed(1)}kg', style: t(12, c: AppColor.textFaint)),
                ]),
              ),
            ),
          ]),
        ),

        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('목표 달성률', style: t(12, c: AppColor.textFaint)),
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('${s.achieveRate}', style: t(24, w: FontWeight.w900, c: AppColor.textStrong)),
                    const SizedBox(width: 2),
                    Text('%', style: t(12, c: AppColor.textFaint)),
                  ]),
                  const SizedBox(height: 10),
                  ProgressBar(value: s.achieveRate / 100),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('기록 일수', style: t(12, c: AppColor.textFaint)),
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('${s.recordDays}', style: t(24, w: FontWeight.w900, c: AppColor.textStrong)),
                    const SizedBox(width: 2),
                    Text('일', style: t(12, c: AppColor.textFaint)),
                  ]),
                  const SizedBox(height: 6),
                  Text('목표 ${s.recordGoalDays}일 달성', style: t(12, w: FontWeight.w700, c: AppColor.primaryDark)),
                ]),
              ),
            ),
          ]),
        ),

        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('패턴 분석', style: t(15, w: FontWeight.w800)),
            const SizedBox(height: 6),
            RowBetween('가장 많이 먹은 음식', s.mostEatenFood),
            RowBetween('자주 쓴 그릇', s.mostUsedBowl),
            RowBetween('자주 쓴 소스', s.mostUsedSauce),
            RowBetween('부족한 영양소', s.lackingNutrient, valueColor: AppColor.alertText),
          ]),
        ),

        AppCard(
          color: AppColor.primaryTint,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('추천 식단', style: t(15, w: FontWeight.w800, c: AppColor.primaryDark)),
            const SizedBox(height: 8),
            Text(s.recommendedMeal, style: t(13, c: AppColor.primaryDark, h: 1.5)),
          ]),
        ),
      ],
    ]);
  }
}
