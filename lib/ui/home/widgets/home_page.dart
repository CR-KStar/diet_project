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

    return Stack(children: [
      // 상단 그라데이션 오버레이
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 290,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColor.heroGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
        ),
      ),
      ScreenScroll(children: [
        const _Greeting(),
        const _CalorieRing(),
        const _NutritionCard(),
        const _TodayCards(),
        const _PlantCard(),
        const _MissionCard(),
        AppCard(
          color: const Color(0xFFFFFCF3),
          radius: 22,
          child: Row(children: [
            const Text('🌤️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('저녁까지 350kcal 남았어요. 가볍게 마무리해요!',
                  style: t(12, c: const Color(0xFF8A6B12), h: 1.5)),
            ),
          ]),
        ),
      ]),
    ]);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    Widget circle(String emoji, VoidCallback onTap, {int badge = 0}) => GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 34,
          height: 34,
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.alert,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$badge', style: t(9, w: FontWeight.w700, c: Colors.white)),
            ),
          ),
      ]),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconTile('🌱', size: 44, radius: 16, bg: AppColor.surface, fontSize: 20, shadow: true),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.nickname}님, 오늘도 잘하고 있어요',
                style: t(19, w: FontWeight.w900, c: AppColor.textStrong, sp: -0.4)),
            const SizedBox(height: 4),
            Text('8월 19일 화요일 · ${s.streakDays}일 연속 기록 🔥',
                style: t(12, c: const Color(0xFF7E9080))),
          ]),
        ),
        circle('🔔', () => s.go('notif'), badge: s.unread),
        const SizedBox(width: 8),
        circle('🗓️', () => s.go('records')),
      ]),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return AppCard(
      padding: 20,
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          Ring(
            size: 134,
            thickness: 11,
            segments: [(value: s.intakeRatio, color: AppColor.primary)],
            center: Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColor.surface, shape: BoxShape.circle),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🍽️', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 2),
                Text(AppState.comma(s.intakeKcal),
                    style: t(24, w: FontWeight.w900, c: AppColor.textStrong, sp: -0.8)),
                Text('/ ${AppState.comma(s.dailyTarget)} kcal',
                    style: t(10, c: AppColor.textFaint)),
              ]),
            ),
          ),
          Positioned(
            right: 2,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Text('${(s.intakeRatio * 100).round()}%',
                  style: t(11, w: FontWeight.w900, c: Colors.white)),
            ),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pill('남은 칼로리', fontSize: 11),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('${s.remainKcal}',
                  style: t(27, w: FontWeight.w900, c: AppColor.primary, sp: -0.6)),
              const SizedBox(width: 4),
              Text('kcal', style: t(13, w: FontWeight.w500, c: AppColor.primary)),
            ]),
            const SizedBox(height: 6),
            Text('사과 두 개 정도 남았어요 🍎', style: t(11, c: AppColor.textFaint)),
            const SizedBox(height: 12),
            SunkenBox(
              padding: 11,
              radius: 14,
              color: const Color(0xFFF8FAF8),
              child: Column(children: [
                RowBetween('권장 칼로리', '${AppState.comma(s.dailyTarget)} kcal'),
                RowBetween('기초대사량', '${AppState.comma(s.bmr.round())} kcal'),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard();

  static const rows = [
    ('🍗', '단백질', 78, 100, 'g', AppColor.primary),
    ('🍚', '탄수화물', 160, 220, 'g', AppColor.warn),
    ('🧈', '지방', 45, 60, 'g', AppColor.warnDeep),
    ('🥬', '식이섬유', 18, 25, 'g', AppColor.teal),
    ('🧂', '나트륨', 1450, 2000, 'mg', AppColor.alert),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    return AppCard(
      child: Column(children: [
        CardHeader(
          emoji: '🥗',
          title: '영양소 섭취 현황',
          action: '자세히 ›',
          onAction: () => s.go('nutrition'),
        ),
        const SizedBox(height: 14),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(width: 19, child: Text(r.$1, style: const TextStyle(fontSize: 13))),
              SizedBox(width: 52, child: Text(r.$2, style: t(12, w: FontWeight.w500))),
              Expanded(child: ProgressBar(value: r.$3 / r.$4, color: r.$6, height: AppSize.barThick)),
              const SizedBox(width: 8),
              SizedBox(
                width: 76,
                child: Text('${AppState.comma(r.$3)} / ${AppState.comma(r.$4)}${r.$5}',
                    textAlign: TextAlign.right, style: t(11, c: AppColor.textMuted)),
              ),
              SizedBox(
                width: 34,
                child: Text('${(r.$3 / r.$4 * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: t(11, w: FontWeight.w700, c: r.$6)),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _TodayCards extends StatelessWidget {
  const _TodayCards();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    final cards = [
      (icon: '💧', label: '물 섭취량', value: AppState.comma(s.waterTotal), unit: 'ml', sub: '/ 2,000 ml', subColor: AppColor.textGhost, pct: s.waterTotal / 2000, tint: AppColor.tintWater, color: AppColor.info, sheet: true, route: 'water'),
      (icon: '🏃', label: '운동 시간', value: '30', unit: '분', sub: '/ 60 분', subColor: AppColor.textGhost, pct: 0.5, tint: AppColor.tintExercise, color: AppColor.primary, sheet: false, route: 'exercise'),
      (icon: '⚖️', label: '체중', value: '56.7', unit: 'kg', sub: '어제보다 0.2kg ↓', subColor: AppColor.primary, pct: 0.62, tint: AppColor.tintWeight, color: AppColor.teal, sheet: false, route: 'weight'),
      (icon: '🍽️', label: '식단', value: '3', unit: '끼', sub: '1,450 kcal 기록', subColor: AppColor.textGhost, pct: 0.75, tint: AppColor.tintMeal, color: AppColor.warnDeep, sheet: false, route: 'capture'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 11),
        child: Row(children: [
          Text('오늘의 기록', style: t(15, w: FontWeight.w900, c: AppColor.textStrong)),
          const SizedBox(width: 8),
          Pill('눌러서 기록', bg: AppColor.surface, fg: AppColor.textFaint, fontSize: 10),
          const Spacer(),
          GestureDetector(
            onTap: () => s.go('records'),
            child: Text('전체 ›', style: t(12, c: AppColor.textFaint)),
          ),
        ]),
      ),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.24,
        children: cards
            .map((c) => GestureDetector(
          onTap: () => c.sheet ? s.setSub(() => s.waterSheet = true) : s.go(c.route),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: c.tint,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconTile(c.icon, size: 36, radius: 18, bg: AppColor.surface, fontSize: 16),
                const Spacer(),
                Text('›', style: TextStyle(fontSize: 13, color: AppColor.iconGhost)),
              ]),
              const Spacer(),
              Text(c.label, style: t(11, w: FontWeight.w500, c: AppColor.textMuted)),
              const SizedBox(height: 3),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(c.value, style: t(21, w: FontWeight.w900, c: AppColor.textStrong, sp: -0.4)),
                const SizedBox(width: 3),
                Text(c.unit, style: t(11, c: AppColor.textFaint)),
              ]),
              Text(c.sub, style: t(10, c: c.subColor)),
              const SizedBox(height: 8),
              ProgressBar(value: c.pct, color: c.color, height: AppSize.barThin, track: Colors.white),
            ]),
          ),
        ))
            .toList(),
      ),
    ]);
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final stage = s.plantStage;

    const careMeta = {
      '물 주기': ('💧', Color(0xFF4CAF50)),
      '햇빛 받기': ('☀️', Color(0xFFE0A21A)),
      '영양 주기': ('🧺', Color(0xFFFF8A65)),
    };

    return AppCard(
      gradient: AppColor.plantGradient,
      radius: 26,
      onTap: () => s.go('plant'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('나의 식물', style: t(15, w: FontWeight.w900, c: AppColor.textStrong)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text('Lv.${s.plantLevel}', style: t(10, w: FontWeight.w700, c: AppColor.primaryDark)),
          ),
          const Spacer(),
          Text('자세히 ›', style: t(12, c: const Color(0xFF7E9080))),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 92,
            height: 104,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Text('🪴', style: TextStyle(fontSize: 46)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${stage.name} 단계', style: t(17, w: FontWeight.w900, c: AppColor.textStrong)),
              const SizedBox(height: 9),
              ProgressBar(
                value: (s.plantExp % 100) / 100,
                height: AppSize.barThick,
                track: Colors.white,
                gradient: const LinearGradient(colors: [Color(0xFF7BD37F), AppColor.primary]),
              ),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${s.plantExp} EXP', style: t(11, c: const Color(0xFF7E9080))),
                Text(s.plantExpLeft, style: t(11, w: FontWeight.w700, c: AppColor.primaryDark)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                for (final c in s.cares.entries) ...[
                  if (c.key != s.cares.keys.first) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        Text(careMeta[c.key]!.$1, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 3),
                        Text('${c.value}/3', style: t(10, w: FontWeight.w700, c: careMeta[c.key]!.$2)),
                      ]),
                    ),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return AppCard(
      child: Column(children: [
        Row(children: [
          IconTile('🎯', size: 26, fontSize: 13),
          const SizedBox(width: 8),
          Text('오늘의 미션', style: t(15, w: FontWeight.w900)),
          const SizedBox(width: 8),
          Pill('${s.missionDone} / ${s.missions.length}', fontSize: 10),
          const Spacer(),
          GestureDetector(
            onTap: () => s.setSub(() => s.missionOpen = true),
            child: Text('전체 ›', style: t(12, c: AppColor.textFaint)),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: s.missions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = s.missions[i];
              return GestureDetector(
                onTap: () => s.go(m.route),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceSunken,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(12, w: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${AppState.comma(m.current.round())} / ${AppState.comma(m.target.round())}${m.unit}',
                        style: t(11, c: AppColor.textFaint)),
                    const Spacer(),
                    Row(children: [
                      Expanded(child: ProgressBar(value: m.ratio, height: AppSize.barThin, track: Colors.white)),
                      const SizedBox(width: 7),
                      Text('${(m.ratio * 100).round()}%', style: t(10, w: FontWeight.w700, c: AppColor.primary)),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
