// 홈 — 칼로리 링 · 영양소 · 오늘의 기록 · 나의 식물 · 오늘의 미션 미리보기

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

import 'today_mission_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.missionOpen) return const TodayMissionScreen();

    return Stack(
      children: [
        // 상단 그라데이션 오버레이
        Positioned(
          top: AppSpace.s0,
          left: AppSpace.s0,
          right: AppSpace.s0,
          height: AppSpace.s290,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColor.heroGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
          ),
        ),
        ScreenScroll(
          children: [
            const _Greeting(),
            const _CalorieRing(),
            const _NutritionCard(),
            const _TodayCards(),
            const _PlantCard(),
            const _MissionCard(),
            AppCard(
              color: const Color(0xFFFFFCF3),
              radius: 22,
              child: Row(
                children: [
                  const Text('🌤️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Text(
                      '저녁까지 350kcal 남았어요. 가볍게 마무리해요!',
                      style: t(
                        AppFontSize.f12,
                        c: const Color(0xFF8A6B12),
                        h: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpace.s4,
        right: AppSpace.s4,
        top: AppSpace.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            '🌱',
            size: 44,
            radius: 16,
            bg: AppColor.surface,
            fontSize: 20,
            shadow: true,
          ),
          const SizedBox(width: AppSpace.s11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.nickname}님, 오늘도 잘하고 있어요',
                  style: t(
                    19,
                    w: FontWeight.w900,
                    c: AppColor.textStrong,
                    sp: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  s.streakDays > 0
                      ? '${s.todayLabel} · ${s.streakDays}일 연속 기록 🔥'
                      : s.todayLabel,
                  style: t(AppFontSize.f12, c: const Color(0xFF7E9080)),
                ),
              ],
            ),
          ),
          _GreetingIconButton(
            emoji: '🔔',
            onTap: () => s.go('notif'),
            badge: s.unread,
          ),
          const SizedBox(width: AppSpace.s8),
          _GreetingIconButton(emoji: '🗓️', onTap: () => s.go('records')),
        ],
      ),
    );
  }
}

class _GreetingIconButton extends StatelessWidget {
  const _GreetingIconButton({
    required this.emoji,
    required this.onTap,
    this.badge = 0,
  });

  final String emoji;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: AppSpace.s34,
          height: AppSpace.s34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadow.card,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        if (badge > 0)
          Positioned(
            right: -4,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s4,
                vertical: AppSpace.s1,
              ),
              constraints: const BoxConstraints(minWidth: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.alert,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$badge',
                style: t(AppFontSize.f9, w: FontWeight.w700, c: Colors.white),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return AppCard(
      padding: 20,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Ring(
                size: 134,
                thickness: 11,
                segments: [(value: s.intakeRatio, color: AppColor.primary)],
                center: Container(
                  width: AppSpace.s112,
                  height: AppSpace.s112,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColor.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🍽️', style: TextStyle(fontSize: 15)),
                      const SizedBox(height: AppSpace.s2),
                      Text(
                        AppState.comma(s.intakeKcal),
                        style: t(
                          AppFontSize.f24,
                          w: FontWeight.w900,
                          c: AppColor.textStrong,
                          sp: -0.8,
                        ),
                      ),
                      Text(
                        '/ ${AppState.comma(s.dailyTarget)} kcal',
                        style: t(AppFontSize.f10, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: AppSpace.s2,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s9,
                    vertical: AppSpace.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Text(
                    '${(s.intakeRatio * 100).round()}%',
                    style: t(
                      AppFontSize.f11,
                      w: FontWeight.w900,
                      c: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpace.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill('남은 칼로리', fontSize: 11),
                const SizedBox(height: AppSpace.s8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${s.remainKcal}',
                      style: t(
                        27,
                        w: FontWeight.w900,
                        c: AppColor.primary,
                        sp: -0.6,
                      ),
                    ),
                    const SizedBox(width: AppSpace.s4),
                    Text(
                      'kcal',
                      style: t(
                        AppFontSize.f13,
                        w: FontWeight.w500,
                        c: AppColor.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s6),
                Text(
                  '사과 두 개 정도 남았어요 🍎',
                  style: t(AppFontSize.f11, c: AppColor.textFaint),
                ),
                const SizedBox(height: AppSpace.s12),
                SunkenBox(
                  padding: 11,
                  radius: 14,
                  color: const Color(0xFFF8FAF8),
                  child: Column(
                    children: [
                      RowBetween(
                        '권장 칼로리',
                        '${AppState.comma(s.dailyTarget)} kcal',
                      ),
                      RowBetween(
                        '기초대사량',
                        '${AppState.comma(s.bmr.round())} kcal',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard();

  static const _emoji = {
    '단백질': '🍗',
    '탄수화물': '🍚',
    '지방': '🧈',
    '식이섬유': '🥬',
    '나트륨': '🧂',
  };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // 홈 카드에는 상위 5종(3대 영양소 + 식이섬유 + 나트륨)만 보여준다.
    final rows = s.todayNutrientStats.take(5);

    return AppCard(
      child: Column(
        children: [
          CardHeader(
            emoji: '🥗',
            title: '영양소 섭취 현황',
            action: '자세히 ›',
            onAction: () => s.go('nutrition'),
          ),
          const SizedBox(height: AppSpace.s14),
          for (final r in rows) _NutritionRow(stat: r, emoji: _emoji[r.name]!),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.stat, required this.emoji});

  final NutrientStat stat;
  final String emoji;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s12),
    child: Row(
      children: [
        SizedBox(
          width: AppSpace.s19,
          child: Text(emoji, style: const TextStyle(fontSize: 13)),
        ),
        SizedBox(
          width: AppSpace.s52,
          child: Text(
            stat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t(AppFontSize.f12, w: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ProgressBar(
            value: stat.target > 0 ? stat.value / stat.target : 0,
            color: stat.color,
            height: AppSize.barThick,
          ),
        ),
        const SizedBox(width: AppSpace.s8),
        SizedBox(
          width: AppSpace.s76,
          child: Text(
            '${AppState.comma(stat.value.round())} / '
            '${AppState.comma(stat.target.round())}${stat.unit}',
            textAlign: TextAlign.right,
            style: t(AppFontSize.f11, c: AppColor.textMuted),
          ),
        ),
        SizedBox(
          width: AppSpace.s34,
          child: Text(
            '${stat.pct}%',
            textAlign: TextAlign.right,
            style: t(AppFontSize.f11, w: FontWeight.w700, c: stat.color),
          ),
        ),
      ],
    ),
  );
}

typedef _TodayCardData = ({
  String icon,
  String label,
  String value,
  String unit,
  String sub,
  Color subColor,
  double pct,
  Color tint,
  Color color,
  bool sheet,
  String route,
});

class _TodayCards extends StatelessWidget {
  const _TodayCards();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    final cards = <_TodayCardData>[
      (
        icon: '💧',
        label: '물 섭취량',
        value: AppState.comma(s.waterTotal),
        unit: 'ml',
        sub: '/ 2,000 ml',
        subColor: AppColor.textGhost,
        pct: s.waterTotal / 2000,
        tint: AppColor.tintWater,
        color: AppColor.info,
        sheet: true,
        route: 'water',
      ),
      (
        icon: '🏃',
        label: '운동 시간',
        value: '${s.todayExerciseMinutes}',
        unit: '분',
        sub: '/ 60 분',
        subColor: AppColor.textGhost,
        pct: (s.todayExerciseMinutes / 60).clamp(0.0, 1.0),
        tint: AppColor.tintExercise,
        color: AppColor.primary,
        sheet: false,
        route: 'exercise',
      ),
      (
        icon: '⚖️',
        label: '체중',
        value: s.latestWeightKg.toStringAsFixed(1),
        unit: 'kg',
        sub: s.profile.goalDelta,
        subColor: AppColor.primary,
        pct: s.profile.goalWeight <= 0
            ? 0.0
            : (s.profile.goalWeight / s.latestWeightKg).clamp(0.0, 1.0),
        tint: AppColor.tintWeight,
        color: AppColor.teal,
        sheet: false,
        route: 'weight',
      ),
      (
        icon: '🍽️',
        label: '식단',
        value: '${s.todayMeals.length}',
        unit: '끼',
        sub: '${AppState.comma(s.intakeKcal)} kcal 기록',
        subColor: AppColor.textGhost,
        pct: s.intakeRatio,
        tint: AppColor.tintMeal,
        color: AppColor.warnDeep,
        sheet: false,
        route: 'capture',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpace.s6,
            bottom: AppSpace.s11,
          ),
          child: Row(
            children: [
              Text(
                '오늘의 기록',
                style: t(
                  AppFontSize.f15,
                  w: FontWeight.w900,
                  c: AppColor.textStrong,
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Pill(
                '눌러서 기록',
                bg: AppColor.surface,
                fg: AppColor.textFaint,
                fontSize: 10,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => s.go('records'),
                child: Text(
                  '전체 ›',
                  style: t(AppFontSize.f12, c: AppColor.textFaint),
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.08,
          children: cards.map((c) => _TodayCardTile(s: s, c: c)).toList(),
        ),
      ],
    );
  }
}

class _TodayCardTile extends StatelessWidget {
  const _TodayCardTile({required this.s, required this.c});

  final AppState s;
  final _TodayCardData c;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => c.sheet ? s.setSub(() => s.waterSheet = true) : s.go(c.route),
    child: Container(
      padding: const EdgeInsets.all(AppSpace.s15),
      decoration: BoxDecoration(
        color: c.tint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                c.icon,
                size: 36,
                radius: 18,
                bg: AppColor.surface,
                fontSize: 16,
              ),
              const Spacer(),
              Text(
                '›',
                style: TextStyle(fontSize: 13, color: AppColor.iconGhost),
              ),
            ],
          ),
          const Spacer(),
          Text(
            c.label,
            style: t(
              AppFontSize.f11,
              w: FontWeight.w500,
              c: AppColor.textMuted,
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                c.value,
                style: t(
                  21,
                  w: FontWeight.w900,
                  c: AppColor.textStrong,
                  sp: -0.4,
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Text(c.unit, style: t(AppFontSize.f11, c: AppColor.textFaint)),
            ],
          ),
          Text(c.sub, style: t(AppFontSize.f10, c: c.subColor)),
          const SizedBox(height: AppSpace.s8),
          ProgressBar(
            value: c.pct,
            color: c.color,
            height: AppSize.barThin,
            track: Colors.white,
          ),
        ],
      ),
    ),
  );
}

const _plantCareMeta = {
  '물 주기': ('💧', Color(0xFF4CAF50)),
  '햇빛 받기': ('☀️', Color(0xFFE0A21A)),
  '영양 주기': ('🧺', Color(0xFFFF8A65)),
};

class _PlantCard extends StatelessWidget {
  const _PlantCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final stage = s.plantStage;

    return AppCard(
      gradient: AppColor.plantGradient,
      radius: 26,
      onTap: () => s.go('plant'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '나의 식물',
                style: t(
                  AppFontSize.f15,
                  w: FontWeight.w900,
                  c: AppColor.textStrong,
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s8,
                  vertical: AppSpace.s3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv.${s.plantLevel}',
                  style: t(
                    AppFontSize.f10,
                    w: FontWeight.w700,
                    c: AppColor.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '자세히 ›',
                style: t(AppFontSize.f12, c: const Color(0xFF7E9080)),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpace.s92,
                height: AppSpace.s104,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Text('🪴', style: TextStyle(fontSize: 46)),
              ),
              const SizedBox(width: AppSpace.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stage.name} 단계',
                      style: t(
                        AppFontSize.f17,
                        w: FontWeight.w900,
                        c: AppColor.textStrong,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s9),
                    ProgressBar(
                      value: (s.plantExp % 100) / 100,
                      height: AppSize.barThick,
                      track: Colors.white,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7BD37F), AppColor.primary],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${s.plantExp} EXP',
                          style: t(AppFontSize.f11, c: const Color(0xFF7E9080)),
                        ),
                        Text(
                          s.plantExpLeft,
                          style: t(
                            AppFontSize.f11,
                            w: FontWeight.w700,
                            c: AppColor.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s12),
                    Row(
                      children: [
                        for (final c in s.cares.entries) ...[
                          if (c.key != s.cares.keys.first)
                            const SizedBox(width: AppSpace.s6),
                          _PlantCareTile(c: c),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlantCareTile extends StatelessWidget {
  const _PlantCareTile({required this.c});

  final MapEntry<String, int> c;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(_plantCareMeta[c.key]!.$1, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: AppSpace.s3),
          Text(
            '${c.value}/3',
            style: t(
              AppFontSize.f10,
              w: FontWeight.w700,
              c: _plantCareMeta[c.key]!.$2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              IconTile('🎯', size: 26, fontSize: 13),
              const SizedBox(width: AppSpace.s8),
              Text('오늘의 미션', style: t(AppFontSize.f15, w: FontWeight.w900)),
              const SizedBox(width: AppSpace.s8),
              Pill('${s.missionDone} / ${s.missions.length}', fontSize: 10),
              const Spacer(),
              GestureDetector(
                onTap: () => s.setSub(() => s.missionOpen = true),
                child: Text(
                  '전체 ›',
                  style: t(AppFontSize.f12, c: AppColor.textFaint),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s14),
          SizedBox(
            height: AppSpace.s92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.missions.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s10),
              itemBuilder: (_, i) => _MissionMiniCard(s: s, m: s.missions[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionMiniCard extends StatelessWidget {
  const _MissionMiniCard({required this.s, required this.m});

  final AppState s;
  final Mission m;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => s.go(m.route),
    child: Container(
      width: AppSpace.s150,
      padding: const EdgeInsets.all(AppSpace.s13),
      decoration: BoxDecoration(
        color: AppColor.surfaceSunken,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t(AppFontSize.f12, w: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.s6),
          Text(
            '${AppState.comma(m.current.round())} / ${AppState.comma(m.target.round())}${m.unit}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t(AppFontSize.f11, c: AppColor.textFaint),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ProgressBar(
                  value: m.ratio,
                  height: AppSize.barThin,
                  track: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpace.s7),
              Text(
                '${(m.ratio * 100).round()}%',
                style: t(
                  AppFontSize.f10,
                  w: FontWeight.w700,
                  c: AppColor.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
