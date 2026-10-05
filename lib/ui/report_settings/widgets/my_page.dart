// 마이 — 프로필 카드 · 나의 식물 요약 · 메뉴(그릇 관리/알림 설정/데이터·개인정보) (+ 내 정보 수정 모드)
//
// SettingsScreen(알림 · 데이터/개인정보 탭)은 settings_page.dart로 분리했습니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';

const _plantStages = [
  ('🌰', '씨앗', 1),
  ('🌱', '새싹', 5),
  ('🪴', '어린잎', 10),
  ('🌿', '무성한잎', 15),
  ('🌸', '꽃', 20),
];

/// 마이 페이지 메인
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.screen == 'profile' || s.profileEdit) return const _ProfileEdit();

    return ScreenScroll(
      children: [
        const TabHeader(emoji: '👤', title: '마이'),
        _ProfileSummaryCard(s: s),
        _PlantSummaryCard(s: s),
        const SizedBox(height: AppSpace.s10),
        _MenuCard(s: s),
        TextLink(
          label: '온보딩 다시 보기',
          onTap: () => s.go('onboard'), // go('onboard')가 자동으로 step=2로 이동시킵니다.
        ),
        TextLink(
          label: '로그아웃',
          onTap: () async {
            final ok = await confirmDialog(
              context,
              title: '로그아웃할까요?',
              message: '다시 로그인하면 저장된 정보 그대로 이어서 쓸 수 있어요.',
              confirmLabel: '로그아웃',
            );
            if (ok) await s.signOut();
          },
        ),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => s.go('profile'),
    child: Row(
      children: [
        const IconTile('🌱', size: 56, radius: 28, fontSize: 22),
        const SizedBox(width: AppSpace.s14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.nickname,
                style: t(
                  AppFontSize.f16,
                  w: FontWeight.w900,
                  c: AppColor.textStrong,
                ),
              ),
              const SizedBox(height: AppSpace.s4),
              Text(
                '${s.heightCm.toStringAsFixed(0)}cm · ${s.weightKg.toStringAsFixed(1)}kg · 목표 ${s.goalWeight.toStringAsFixed(1)}kg',
                style: t(AppFontSize.f11, c: AppColor.textFaint),
              ),
            ],
          ),
        ),
        Text('수정 ›', style: t(AppFontSize.f12, c: AppColor.textFaint)),
      ],
    ),
  );
}

/// 나의 식물 요약
class _PlantSummaryCard extends StatelessWidget {
  const _PlantSummaryCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => s.go('plant'),
    child: Column(
      children: [
        Row(
          children: [
            Text('나의 식물', style: t(AppFontSize.f14, w: FontWeight.w700)),
            const Spacer(),
            Text(
              'Lv.${s.plantLevel} · ${s.plantStage.name} 단계 ›',
              style: t(AppFontSize.f11, c: AppColor.textFaint),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s14),
        Row(
          children: [
            for (final st in _plantStages) _PlantStageTile(s: s, st: st),
          ],
        ),
      ],
    ),
  );
}

class _PlantStageTile extends StatelessWidget {
  const _PlantStageTile({required this.s, required this.st});

  final AppState s;
  final (String, String, int) st;

  @override
  Widget build(BuildContext context) {
    final active = s.plantStage.name == st.$2;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
        decoration: BoxDecoration(
          color: active ? AppColor.primaryTint : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(st.$1, style: TextStyle(fontSize: active ? 26 : 22)),
            const SizedBox(height: AppSpace.s5),
            Text(
              '${st.$2} Lv.${st.$3}',
              style: t(
                AppFontSize.f10,
                w: active ? FontWeight.w700 : FontWeight.w400,
                c: active ? AppColor.primaryDark : AppColor.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 메뉴
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 0,
    child: Column(
      children: [
        _MenuRow(
          emoji: '🥣',
          title: '내 그릇 관리',
          desc: '${s.bowls.length}개 등록 · 기본 그릇 1개',
          onTap: () => s.go('bowls'),
        ),
        const Divider(height: AppSpace.s1, indent: 18, endIndent: 18),
        _MenuRow(
          emoji: '🔔',
          title: '알림 설정',
          desc: '식단 미기록, 물, 운동, 친구 응원',
          onTap: () {
            s.go('settings');
            s.setSetTab('알림');
          },
        ),
        const Divider(height: AppSpace.s1, indent: 18, endIndent: 18),
        _MenuRow(
          emoji: '🔒',
          title: '데이터 및 개인정보',
          desc: '공개 범위, 기록 삭제, 계정 삭제',
          onTap: () {
            s.go('settings');
            s.setSetTab('데이터 · 개인정보');
          },
        ),
      ],
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.emoji,
    required this.title,
    required this.desc,
    this.onTap,
  });

  final String emoji;
  final String title;
  final String desc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s18,
        vertical: AppSpace.s16,
      ),
      child: Row(
        children: [
          IconTile(emoji, size: 34, radius: 12, fontSize: 16),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t(AppFontSize.f14, w: FontWeight.w700)),
                const SizedBox(height: AppSpace.s3),
                Text(desc, style: t(AppFontSize.f11, c: AppColor.textFaint)),
              ],
            ),
          ),
          const Text(
            '›',
            style: TextStyle(fontSize: 16, color: AppColor.iconGhost),
          ),
        ],
      ),
    ),
  );
}

/// 내 정보 수정 — 키·체중·나이·성별·목표·활동량 수정 후 BMI·기초대사량·권장 칼로리 재계산
class _ProfileEdit extends StatelessWidget {
  const _ProfileEdit();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      children: [
        SubHeader(emoji: '✏️', title: '내 정보 수정', onBack: () => s.go('my')),
        _BasicInfoCard(s: s),
        _GoalWeightCard(s: s),
        _GoalActivityCard(s: s),
        _RecalculatedCard(s: s),
        PrimaryButton(
          label: '수정 저장',
          onTap: () async {
            final saved = await s.saveProfile();
            if (!context.mounted) return;
            if (saved) s.go('my');
            toast(
              context,
              saved
                  ? '내 정보를 수정했어요 · 목표가 다시 계산됐어요'
                  : (s.authError ?? '저장하지 못했어요'),
            );
          },
        ),
      ],
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '닉네임',
          style: t(AppFontSize.f12, w: FontWeight.w500, c: AppColor.textFaint),
        ),
        const SizedBox(height: AppSpace.s8),
        AppTextField(
          value: s.nickname,
          fontSize: 15,
          onChanged: (v) => s.setSub(() => s.nickname = v),
        ),
        const SizedBox(height: AppSpace.s16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '키',
                    style: t(
                      AppFontSize.f12,
                      w: FontWeight.w500,
                      c: AppColor.textFaint,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  NumberField(
                    value: s.heightCm,
                    unit: 'cm',
                    fontSize: 18,
                    color: AppColor.text,
                    decimal: true,
                    max: 250,
                    onChanged: (v) => s.setSub(() => s.heightCm = v.toDouble()),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 체중',
                    style: t(
                      AppFontSize.f12,
                      w: FontWeight.w500,
                      c: AppColor.textFaint,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  NumberField(
                    value: s.weightKg,
                    unit: 'kg',
                    fontSize: 18,
                    color: AppColor.text,
                    decimal: true,
                    max: 300,
                    onChanged: (v) => s.setSub(() => s.weightKg = v.toDouble()),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '나이',
                    style: t(
                      AppFontSize.f12,
                      w: FontWeight.w500,
                      c: AppColor.textFaint,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  NumberField(
                    value: s.age,
                    unit: '세',
                    fontSize: 18,
                    color: AppColor.text,
                    max: 120,
                    onChanged: (v) => s.setSub(() => s.age = v.toInt()),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '성별',
                    style: t(
                      AppFontSize.f12,
                      w: FontWeight.w500,
                      c: AppColor.textFaint,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  SegmentedRow(
                    options: const ['여성', '남성'],
                    value: s.gender,
                    onChanged: (v) => s.setSub(() => s.gender = v),
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

class _GoalWeightCard extends StatelessWidget {
  const _GoalWeightCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('목표 체중', style: t(AppFontSize.f13, w: FontWeight.w700)),
            Text(
              '${s.goalWeight.toStringAsFixed(1)} kg',
              style: t(
                AppFontSize.f20,
                w: FontWeight.w900,
                c: AppColor.primary,
              ),
            ),
          ],
        ),
        DragSlider(
          value: s.goalWeight,
          min: 45,
          max: 70,
          onChanged: (v) => s.setSub(() => s.goalWeight = v),
        ),
        const SizedBox(height: AppSpace.s6),
        RowBetween('감량 목표', s.goalDelta),
      ],
    ),
  );
}

class _GoalActivityCard extends StatelessWidget {
  const _GoalActivityCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('목표 · 활동량', style: t(AppFontSize.f13, w: FontWeight.w700)),
        const SizedBox(height: AppSpace.s11),
        SegmentedRow(
          options: const ['체중 감량', '체중 유지', '근육 증가'],
          value: s.goal,
          onChanged: (v) => s.setSub(() => s.goal = v),
        ),
        const SizedBox(height: AppSpace.s10),
        SegmentedRow(
          options: const ['적음', '보통', '많음'],
          value: s.activity,
          onChanged: (v) => s.setSub(() => s.activity = v),
        ),
      ],
    ),
  );
}

/// 재계산 결과
class _RecalculatedCard extends StatelessWidget {
  const _RecalculatedCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColor.primaryTint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다시 계산된 목표',
          style: t(
            AppFontSize.f13,
            w: FontWeight.w700,
            c: AppColor.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        Row(
          children: [
            for (final r in [
              ('BMI', s.bmi.toStringAsFixed(1)),
              ('기초대사량', AppState.comma(s.bmr.round())),
              ('일일 권장', AppState.comma(s.dailyTarget)),
            ])
              _RecalcTile(r: r),
          ],
        ),
        const SizedBox(height: AppSpace.s10),
        Text(
          '모든 영양 정보는 참고용이며 의료 진단이 아닙니다.',
          style: t(AppFontSize.f11, c: const Color(0xFF4A7A4E), h: 1.5),
        ),
      ],
    ),
  );
}

class _RecalcTile extends StatelessWidget {
  const _RecalcTile({required this.r});

  final (String, String) r;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(r.$1, style: t(AppFontSize.f11, c: const Color(0xFF4A7A4E))),
        const SizedBox(height: AppSpace.s4),
        Text(
          r.$2,
          style: t(
            19,
            w: FontWeight.w900,
            c: const Color(0xFF2F7A34),
            sp: -0.5,
          ),
        ),
      ],
    ),
  );
}
