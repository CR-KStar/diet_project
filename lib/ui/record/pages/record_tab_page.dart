// 기록 탭 — 달력 · 월 이동 · 빠른 기록 4카드 · 날짜별 기록 목록

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/onboarding/viewmodel/profile_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/water_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/today_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/records_view_model.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';
import 'package:diet_project/ui/core/ui/icons/app_icons.dart';

const _quickActions = [
  (
    label: '식단',
    icon: AppIcons.meal,
    color: AppIconColors.meal,
    route: 'capture',
    sheet: false,
  ),
  (
    label: '운동',
    icon: AppIcons.exercise,
    color: AppIconColors.exercise,
    route: 'exercise',
    sheet: false,
  ),
  (
    label: '체중',
    icon: AppIcons.weight,
    color: AppIconColors.weight,
    route: 'weight',
    sheet: false,
  ),
  (
    label: '물',
    icon: AppIcons.water,
    color: AppIconColors.water,
    route: 'water',
    sheet: true,
  ),
];

const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>();
    final records = context.watch<RecordsViewModel>();

    return ScreenScroll(
      children: [
        TabHeader(
          icon: AppIcons.records,
          title: '기록',
          trailing: _MonthNavRow(),
        ),
        _QuickRecordCard(),
        _CalendarCard(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
          child: Row(
            children: [
              Text(
                '${records.month}월 ${records.day}일 기록',
                style: t(AppFontSize.f15, w: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${AppStateFormat.comma(records.selectedDayKcal)} / ${AppStateFormat.comma(profile.dailyTarget)} kcal',
                style: t(
                  AppFontSize.f12,
                  w: FontWeight.w700,
                  c: AppColor.primary,
                ),
              ),
            ],
          ),
        ),
        for (final m in records.meals) _MealCard(m: m),
        _DaySummaryCard(),
      ],
    );
  }
}

class _MonthNavRow extends StatelessWidget {
  const _MonthNavRow();

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordsViewModel>();
    return Row(
      children: [
        _MonthButton(icon: '‹', onTap: records.prevMonth),
        const SizedBox(width: AppSpace.s10),
        SizedBox(
          width: AppSpace.s78,
          child: Text(
            '${records.year}. ${records.month.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: t(AppFontSize.f14, w: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpace.s10),
        _MonthButton(
          icon: '›',
          enabled: records.canGoNextMonth,
          onTap: () {
            if (!records.nextMonth()) toast(context, '오늘 이후의 기록은 만들 수 없어요');
          },
        ),
      ],
    );
  }
}

/// 빠른 기록 — 눌러서 각 입력 화면으로
class _QuickRecordCard extends StatelessWidget {
  const _QuickRecordCard();

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordsViewModel>();
    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${records.month}월 ${records.day}일에 기록 추가',
            style: t(AppFontSize.f13, w: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [for (final q in _quickActions) _QuickRecordButton(q: q)],
          ),
        ],
      ),
    );
  }
}

class _QuickRecordButton extends StatelessWidget {
  const _QuickRecordButton({required this.q});

  final ({String label, IconData icon, Color color, String route, bool sheet})
  q;

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordsViewModel>();
    final s = context.watch<AppState>();
    final done = records.logged[q.label] ?? false;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: q.label == '물' ? 0 : 8),
        child: GestureDetector(
          onTap: () =>
              q.sheet ? s.setSub(() => s.waterSheet = true) : s.go(q.route),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpace.s13,
              horizontal: AppSpace.s6,
            ),
            decoration: AppDeco.selectableCard(selected: done),
            child: Column(
              children: [
                Icon(q.icon, size: 24, color: q.color),
                const SizedBox(height: AppSpace.s6),
                Text(q.label, style: t(AppFontSize.f11, w: FontWeight.w700)),
                const SizedBox(height: AppSpace.s4),
                Text(
                  done ? '기록됨' : '기록하기',
                  style: t(
                    AppFontSize.f9,
                    c: done ? AppColor.primary : AppColor.textGhost,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 달력
class _CalendarCard extends StatelessWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordsViewModel>();
    final offset =
        DateTime(records.year, records.month, 1).weekday % 7; // 일요일 시작
    final total = DateTime(records.year, records.month + 1, 0).day;
    final cells = ((offset + total) / 7).ceil() * 7;

    return AppCard(
      padding: 16,
      child: Column(
        children: [
          Row(
            children: [
              for (final (i, d) in _weekdayLabels.indexed)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: t(
                      AppFontSize.f11,
                      w: FontWeight.w700,
                      c: i == 0
                          ? AppColor.alert
                          : i == 6
                          ? AppColor.info
                          : AppColor.textFaint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: [
              for (var i = 0; i < cells; i++)
                _CalendarDayCell(i: i, offset: offset, total: total),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.i,
    required this.offset,
    required this.total,
  });

  final int i;
  final int offset;
  final int total;

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordsViewModel>();
    final n = i - offset + 1;
    final valid = n >= 1 && n <= total;
    final sel = valid && n == records.day;
    final future = valid && records.isFutureDay(n);
    final hasLog =
        valid &&
        !future &&
        records.hasRecordOn(DateTime(records.year, records.month, n));
    return GestureDetector(
      onTap: valid && !future ? () => records.selectDay(n) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.all(AppSpace.s1),
        decoration: BoxDecoration(
          color: sel ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valid ? '$n' : '',
              style: t(
                AppFontSize.f12,
                w: sel ? FontWeight.w700 : FontWeight.w500,
                c: sel
                    ? Colors.white
                    : (future ? AppColor.textGhost : AppColor.text),
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            Container(
              width: AppSpace.s4,
              height: AppSpace.s4,
              decoration: BoxDecoration(
                color: hasLog
                    ? (sel ? Colors.white : AppColor.primary)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 끼니 목록 — 탭하면 상세로
class _MealCard extends StatelessWidget {
  const _MealCard({required this.m});

  final MealLog m;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      padding: 13,
      onTap: () => s.openMeal(m),
      child: Row(
        children: [
          const SizedBox(
            width: AppSpace.s58,
            height: AppSpace.s58,
            child: PhotoPlaceholder(height: AppSpace.s58, radius: 18),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.type,
                      style: t(
                        AppFontSize.f11,
                        w: FontWeight.w700,
                        c: AppColor.textFaint,
                      ),
                    ),
                    if (m.needsReview) ...[
                      const SizedBox(width: AppSpace.s7),
                      Pill(
                        '확인 필요',
                        bg: const Color(0xFFFFF3EF),
                        fg: AppColor.alertText,
                        fontSize: 9,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  m.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t(AppFontSize.f14, w: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.s3),
                Text(
                  m.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t(AppFontSize.f11, c: AppColor.textGhost),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${m.kcal}', style: t(AppFontSize.f15, w: FontWeight.w900)),
              Text('kcal', style: t(AppFontSize.f10, c: AppColor.textGhost)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard();

  @override
  Widget build(BuildContext context) {
    final today = context.watch<TodayViewModel>();
    final water = context.watch<WaterViewModel>();
    return AppCard(
      padding: 16,
      child: Row(
        children: [
          for (final r in [
            ('물', '${AppStateFormat.comma(water.waterTotal)}ml'),
            ('운동', '${today.todayExerciseMinutes}분'),
            ('체중', '${today.latestWeightKg.toStringAsFixed(1)}kg'),
          ]) ...[
            Expanded(
              child: Column(
                children: [
                  Text(r.$1, style: t(AppFontSize.f11, c: AppColor.textFaint)),
                  const SizedBox(height: AppSpace.s5),
                  Text(r.$2, style: t(AppFontSize.f14, w: FontWeight.w700)),
                ],
              ),
            ),
            if (r.$1 != '체중')
              Container(
                width: AppSpace.s1,
                height: AppSpace.s30,
                color: AppColor.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.icon, this.onTap, this.enabled = true});

  final String icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: AppSpace.s28,
      height: AppSpace.s28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadow.card,
      ),
      child: Text(
        icon,
        style: TextStyle(
          fontSize: 15,
          color: enabled ? AppColor.textMuted : const Color(0xFFD5DADD),
        ),
      ),
    ),
  );
}

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordsVm = context.watch<RecordsViewModel>();
    final s = context.watch<AppState>();
    final m = recordsVm.detailMeal;
    return ScreenScroll(
      children: [
        SubHeader(
          icon: AppIcons.meal,
          title: '식단 상세',
          onBack: () => s.go('records'),
        ),
        if (m == null)
          const AppCard(child: Text('식단 정보를 찾을 수 없어요.'))
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.type,
                      style: t(
                        AppFontSize.f11,
                        w: FontWeight.w700,
                        c: AppColor.textFaint,
                      ),
                    ),
                    if (m.needsReview) ...[
                      const SizedBox(width: AppSpace.s7),
                      Pill(
                        '확인 필요',
                        bg: const Color(0xFFFFF3EF),
                        fg: AppColor.alertText,
                        fontSize: 9,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.s6),
                Text(m.name, style: t(AppFontSize.f18, w: FontWeight.w900)),
                const SizedBox(height: AppSpace.s4),
                Text(m.meta, style: t(AppFontSize.f12, c: AppColor.textGhost)),
                const SizedBox(height: AppSpace.s14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${m.kcal}',
                      style: t(
                        AppFontSize.f24,
                        w: FontWeight.w900,
                        c: AppColor.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpace.s4),
                    Text(
                      'kcal',
                      style: t(AppFontSize.f12, c: AppColor.textFaint),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
