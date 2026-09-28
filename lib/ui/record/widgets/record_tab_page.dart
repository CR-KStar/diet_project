// 기록 탭 — 달력 · 월 이동 · 빠른 기록 4카드 · 날짜별 기록 목록

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

const _quickActions = [
  (label: '식단', icon: '🍽️', route: 'capture', sheet: false),
  (label: '운동', icon: '🏃', route: 'exercise', sheet: false),
  (label: '체중', icon: '⚖️', route: 'weight', sheet: false),
  (label: '물', icon: '💧', route: 'water', sheet: true),
];

const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      children: [
        TabHeader(
          emoji: '📋',
          title: '기록',
          trailing: _MonthNavRow(s: s),
        ),
        _QuickRecordCard(s: s),
        _CalendarCard(s: s),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                '${s.month}월 ${s.day}일 기록',
                style: t(15, w: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${AppState.comma(s.selectedDayKcal)} / ${AppState.comma(s.dailyTarget)} kcal',
                style: t(12, w: FontWeight.w700, c: AppColor.primary),
              ),
            ],
          ),
        ),
        for (final m in s.meals) _MealCard(m: m, s: s),
        _DaySummaryCard(s: s),
      ],
    );
  }
}

class _MonthNavRow extends StatelessWidget {
  const _MonthNavRow({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _MonthButton(icon: '‹', onTap: s.prevMonth),
      const SizedBox(width: 10),
      SizedBox(
        width: 78,
        child: Text(
          '${s.year}. ${s.month.toString().padLeft(2, '0')}',
          textAlign: TextAlign.center,
          style: t(14, w: FontWeight.w700),
        ),
      ),
      const SizedBox(width: 10),
      _MonthButton(
        icon: '›',
        enabled: s.canGoNextMonth,
        onTap: () {
          if (!s.nextMonth()) toast(context, '오늘 이후의 기록은 만들 수 없어요');
        },
      ),
    ],
  );
}

/// 빠른 기록 — 눌러서 각 입력 화면으로
class _QuickRecordCard extends StatelessWidget {
  const _QuickRecordCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.month}월 ${s.day}일에 기록 추가', style: t(13, w: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final q in _quickActions) _QuickRecordButton(q: q, s: s),
          ],
        ),
      ],
    ),
  );
}

class _QuickRecordButton extends StatelessWidget {
  const _QuickRecordButton({required this.q, required this.s});

  final ({String label, String icon, String route, bool sheet}) q;
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final done = s.logged[q.label] ?? false;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: q.label == '물' ? 0 : 8),
        child: GestureDetector(
          onTap: () =>
              q.sheet ? s.setSub(() => s.waterSheet = true) : s.go(q.route),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
            decoration: AppDeco.selectableCard(selected: done),
            child: Column(
              children: [
                Text(q.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                Text(q.label, style: t(11, w: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  done ? '기록됨' : '기록하기',
                  style: t(9, c: done ? AppColor.primary : AppColor.textGhost),
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
  const _CalendarCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) {
    final offset = DateTime(s.year, s.month, 1).weekday % 7; // 일요일 시작
    final total = DateTime(s.year, s.month + 1, 0).day;
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
                      11,
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
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: [
              for (var i = 0; i < cells; i++)
                _CalendarDayCell(s: s, i: i, offset: offset, total: total),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.s,
    required this.i,
    required this.offset,
    required this.total,
  });

  final AppState s;
  final int i;
  final int offset;
  final int total;

  @override
  Widget build(BuildContext context) {
    final n = i - offset + 1;
    final valid = n >= 1 && n <= total;
    final sel = valid && n == s.day;
    final future = valid && s.isFutureDay(n);
    final hasLog =
        valid && !future && s.hasRecordOn(DateTime(s.year, s.month, n));
    return GestureDetector(
      onTap: valid && !future ? () => s.selectDay(n) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.all(1),
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
                12,
                w: sel ? FontWeight.w700 : FontWeight.w500,
                c: sel
                    ? Colors.white
                    : (future ? AppColor.textGhost : AppColor.text),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
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
  const _MealCard({required this.m, required this.s});

  final MealLog m;
  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 13,
    onTap: () => s.openMeal(m),
    child: Row(
      children: [
        const SizedBox(
          width: 58,
          height: 58,
          child: PhotoPlaceholder(height: 58, radius: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    m.type,
                    style: t(11, w: FontWeight.w700, c: AppColor.textFaint),
                  ),
                  if (m.needsReview) ...[
                    const SizedBox(width: 7),
                    Pill(
                      '확인 필요',
                      bg: const Color(0xFFFFF3EF),
                      fg: AppColor.alertText,
                      fontSize: 9,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(m.name, style: t(14, w: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(m.meta, style: t(11, c: AppColor.textGhost)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${m.kcal}', style: t(15, w: FontWeight.w900)),
            Text('kcal', style: t(10, c: AppColor.textGhost)),
          ],
        ),
      ],
    ),
  );
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 16,
    child: Row(
      children: [
        for (final r in [
          ('물', '${AppState.comma(s.waterTotal)}ml'),
          ('운동', '${s.todayExerciseMinutes}분'),
          ('체중', '${s.latestWeightKg.toStringAsFixed(1)}kg'),
        ]) ...[
          Expanded(
            child: Column(
              children: [
                Text(r.$1, style: t(11, c: AppColor.textFaint)),
                const SizedBox(height: 5),
                Text(r.$2, style: t(14, w: FontWeight.w700)),
              ],
            ),
          ),
          if (r.$1 != '체중')
            Container(width: 1, height: 30, color: AppColor.divider),
        ],
      ],
    ),
  );
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
      width: 28,
      height: 28,
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
    final s = context.watch<AppState>();
    final m = s.detailMeal;
    return ScreenScroll(
      children: [
        SubHeader(emoji: '🍱', title: '식단 상세', onBack: () => s.go('records')),
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
                      style: t(11, w: FontWeight.w700, c: AppColor.textFaint),
                    ),
                    if (m.needsReview) ...[
                      const SizedBox(width: 7),
                      Pill(
                        '확인 필요',
                        bg: const Color(0xFFFFF3EF),
                        fg: AppColor.alertText,
                        fontSize: 9,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(m.name, style: t(18, w: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(m.meta, style: t(12, c: AppColor.textGhost)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${m.kcal}',
                      style: t(24, w: FontWeight.w900, c: AppColor.primary),
                    ),
                    const SizedBox(width: 4),
                    Text('kcal', style: t(12, c: AppColor.textFaint)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
