// 오늘의 미션 — 홈의 서브 모드 (home_page.dart의 HomeScreen에서 전환)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/home/viewmodel/mission_view_model.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';
import 'package:diet_project/ui/core/ui/icons/app_icons.dart';

const _categories = ['전체', '식단', '운동', '생활', '꾸준함'];

/// 카테고리별 (아이콘, 바탕색, 아이콘색)
const _categoryMeta = {
  '식단': (AppIcons.meal, Color(0xFFF7F5F2), AppIconColors.meal),
  '생활': (AppIcons.water, Color(0xFFEAF1FE), AppIconColors.water),
  '운동': (AppIcons.exercise, Color(0xFFEFF7EF), AppIconColors.exercise),
  '꾸준함': (AppIcons.fire, Color(0xFFFFF3E6), AppColor.alert),
};

class TodayMissionScreen extends StatelessWidget {
  const TodayMissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mission = context.watch<MissionViewModel>();
    final s = context.watch<AppState>();
    final list = mission.missionFilterTab == '전체'
        ? mission.missions
        : mission.missions
              .where((m) => m.category == mission.missionFilterTab)
              .toList();

    return ScreenScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SubHeader(
                icon: AppIcons.target,
                title: '오늘의 미션',
                onBack: () => s.setSub(() => s.missionOpen = false),
              ),
            ),
            Text(
              s.todayDateLabel,
              style: t(AppFontSize.f12, c: AppColor.textFaint),
            ),
          ],
        ),
        const _AchievementCard(),
        FilterTabs(
          options: _categories,
          value: mission.missionFilterTab,
          onChanged: mission.setMissionFilterTab,
        ),
        for (final m in list) _MissionCard(m: m),
        const _RewardStructureCard(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
          child: Text(
            '미션은 하루 3~5개만 제시하고, 최근 기록과 부족한 영양소를 반영해 매일 새로 뽑아요.',
            textAlign: TextAlign.center,
            style: t(AppFontSize.f12, c: AppColor.textFaint, h: 1.5),
          ),
        ),
      ],
    );
  }
}

/// 오늘 달성 + 성장 단계
class _AchievementCard extends StatelessWidget {
  const _AchievementCard();

  @override
  Widget build(BuildContext context) {
    final mission = context.watch<MissionViewModel>();
    final s = context.watch<AppState>();
    final total = mission.missions.length;
    final ratio = total == 0 ? 0.0 : mission.missionDone / total;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘 달성', style: t(AppFontSize.f12, c: AppColor.textFaint)),
                const SizedBox(height: AppSpace.s8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${mission.missionDone}',
                      style: t(
                        AppFontSize.f28,
                        w: FontWeight.w900,
                        c: AppColor.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpace.s4),
                    Text(
                      '/ $total 미션',
                      style: t(AppFontSize.f13, c: AppColor.textFaint),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s10),
                ProgressBar(value: ratio, height: AppSpace.s8),
                const SizedBox(height: AppSpace.s10),
                Text(
                  mission.missionDone >= total
                      ? '오늘 미션을 모두 달성했어요!'
                      : '미션을 ${total - mission.missionDone}개 더 달성하면 다음 성장 단계로 넘어가요.',
                  style: t(AppFontSize.f12, c: AppColor.textMuted, h: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s14),
          GestureDetector(
            onTap: () => s.go('plant'),
            child: Container(
              width: AppSpace.s96,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpace.s14,
                horizontal: AppSpace.s10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F8F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSpace.s52,
                    height: AppSpace.s52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      AppIcons.plant,
                      size: 28,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    '성장 단계',
                    textAlign: TextAlign.center,
                    style: t(
                      AppFontSize.f11,
                      w: FontWeight.w700,
                      c: AppColor.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s10),
                  ProgressBar(
                    value: ratio,
                    height: AppSpace.s10,
                    color: const Color(0xFFE8B33C),
                    track: const Color(0xFFDCE6DD),
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

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.m});

  final Mission m;

  @override
  Widget build(BuildContext context) {
    final mission = context.watch<MissionViewModel>();
    final s = context.watch<AppState>();
    final done = mission.missionEffectivelyDone(m);
    final meta =
        _categoryMeta[m.category] ??
        (AppIcons.target, AppColor.surfaceSunken, AppColor.textMuted);

    return AppCard(
      border: done ? AppColor.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile.icon(
                meta.$1,
                size: 40,
                radius: 20,
                bg: meta.$2,
                color: meta.$3,
                iconSize: 22,
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.title,
                            style: t(AppFontSize.f15, w: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: AppSpace.s8),
                        if (m.special != null)
                          Pill(
                            m.special!,
                            bg: const Color(0xFFF1ECFF),
                            fg: const Color(0xFF6A54A8),
                            fontSize: 10,
                          )
                        else
                          Pill('성장 +${m.exp}', fontSize: 10),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      '${meta.$1} ${m.category} · ${done ? '달성 완료' : '${AppStateFormat.comma(m.current.round())} / ${AppStateFormat.comma(m.target.round())}${m.unit}'}',
                      style: t(AppFontSize.f11, c: AppColor.textFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              Expanded(
                child: ProgressBar(value: m.ratio, height: AppSize.barBase),
              ),
              const SizedBox(width: AppSpace.s10),
              Text(
                '${(m.ratio * 100).round()}%',
                style: t(
                  AppFontSize.f12,
                  w: FontWeight.w700,
                  c: done ? AppColor.primary : AppColor.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              _MissionActionButton(
                label: '기록 화면으로',
                onTap: () => s.go(m.route),
              ),
              const SizedBox(width: AppSpace.s9),
              if (done)
                const _MissionActionButton(label: '달성 완료')
              else
                _MissionActionButton(
                  label: '달성 처리',
                  active: true,
                  onTap: () {
                    mission.completeMissionManually(m);
                    toast(context, '“${m.title}” 완료 · +${m.exp} EXP');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionActionButton extends StatelessWidget {
  const _MissionActionButton({
    required this.label,
    this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s13),
        decoration: BoxDecoration(
          color: active ? AppColor.primary : AppColor.surfaceSunken,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: t(
            AppFontSize.f13,
            w: FontWeight.w700,
            c: active
                ? Colors.white
                : (onTap == null ? AppColor.textGhost : AppColor.textMuted),
          ),
        ),
      ),
    ),
  );
}

class _RewardStructureCard extends StatelessWidget {
  const _RewardStructureCard();

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('보상 구조', style: t(AppFontSize.f15, w: FontWeight.w800)),
        const SizedBox(height: AppSpace.s6),
        Text(
          '미션 난이도에 따라 성장 · 발견 · 변이로 이어져요',
          style: t(AppFontSize.f12, c: AppColor.textFaint),
        ),
        const SizedBox(height: AppSpace.s18),
        for (final row in const [
          ('일반', AppColor.text, AppIcons.plant, '식물 성장 게이지 +'),
          ('특정', AppColor.text, AppIcons.dex, '새로운 식물 발견 기회'),
          ('연속', Color(0xFFE8B33C), AppIcons.sparkle, '변이 발생 기회'),
          ('어려움', Color(0xFF5B8DEF), AppIcons.gem, '희귀 식물 · 희귀 변이'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s14),
            child: Row(
              children: [
                SizedBox(
                  width: AppSpace.s56,
                  child: Text(
                    row.$1,
                    style: t(AppFontSize.f13, w: FontWeight.w800, c: row.$2),
                  ),
                ),
                Icon(
                  row.$3,
                  size: 18,
                  color: row.$2 == AppColor.text ? AppColor.primary : row.$2,
                ),
                const SizedBox(width: AppSpace.s8),
                Text(row.$4, style: t(AppFontSize.f13, c: AppColor.textMuted)),
              ],
            ),
          ),
      ],
    ),
  );
}
