// 마이 — 프로필 카드 · 나의 식물 요약 · 메뉴(그릇 관리/알림 설정/데이터·개인정보) (+ 내 정보 수정 모드)
//
// SettingsScreen(알림 · 데이터/개인정보 탭)은 settings_page.dart로 분리했습니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';

/// 마이 페이지 메인
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.screen == 'profile' || s.profileEdit) return const _ProfileEdit();

    return ScreenScroll(children: [
      const TabHeader(emoji: '👤', title: '마이'),

      AppCard(
        onTap: () => s.go('profile'),
        child: Row(children: [
          const IconTile('🌱', size: 56, radius: 28, fontSize: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.nickname, style: t(16, w: FontWeight.w900, c: AppColor.textStrong)),
              const SizedBox(height: 4),
              Text(
                '${s.heightCm.toStringAsFixed(0)}cm · ${s.weightKg.toStringAsFixed(1)}kg · 목표 ${s.goalWeight.toStringAsFixed(1)}kg',
                style: t(11, c: AppColor.textFaint),
              ),
            ]),
          ),
          Text('수정 ›', style: t(12, c: AppColor.textFaint)),
        ]),
      ),

      // 나의 식물 요약
      AppCard(
        onTap: () => s.go('plant'),
        child: Column(children: [
          Row(children: [
            Text('나의 식물', style: t(14, w: FontWeight.w700)),
            const Spacer(),
            Text('Lv.${s.plantLevel} · ${s.plantStage.name} 단계 ›',
                style: t(11, c: AppColor.textFaint)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            for (final st in const [
              ('🌰', '씨앗', 1), ('🌱', '새싹', 5), ('🪴', '어린잎', 10),
              ('🌿', '무성한잎', 15), ('🌸', '꽃', 20),
            ])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: s.plantStage.name == st.$2 ? AppColor.primaryTint : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    Text(st.$1,
                        style: TextStyle(fontSize: s.plantStage.name == st.$2 ? 26 : 22)),
                    const SizedBox(height: 5),
                    Text('${st.$2} Lv.${st.$3}',
                        style: t(10,
                            w: s.plantStage.name == st.$2 ? FontWeight.w700 : FontWeight.w400,
                            c: s.plantStage.name == st.$2
                                ? AppColor.primaryDark
                                : AppColor.textFaint)),
                  ]),
                ),
              ),
          ]),
        ]),
      ),

      const SizedBox(height: 10),

      // 메뉴
      AppCard(
        padding: 0,
        child: Column(children: [
          _MenuRow(
            emoji: '🥣',
            title: '내 그릇 관리',
            desc: '${s.bowls.length}개 등록 · 기본 그릇 1개',
            onTap: () => s.go('bowls'),
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          _MenuRow(
            emoji: '🔔',
            title: '알림 설정',
            desc: '식단 미기록, 물, 운동, 친구 응원',
            onTap: () {
              s.go('settings');
              s.setSetTab('알림');
            },
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          _MenuRow(
            emoji: '🔒',
            title: '데이터 및 개인정보',
            desc: '공개 범위, 기록 삭제, 계정 삭제',
            onTap: () {
              s.go('settings');
              s.setSetTab('데이터 · 개인정보');
            },
          ),
        ]),
      ),

      TextLink(
        label: '온보딩 다시 보기',
        onTap: () => s.go('onboard'), // go('onboard')가 자동으로 step=2로 이동시킵니다.
      ),
    ]);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.emoji, required this.title, required this.desc, this.onTap});

  final String emoji;
  final String title;
  final String desc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(children: [
        IconTile(emoji, size: 34, radius: 12, fontSize: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: t(14, w: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(desc, style: t(11, c: AppColor.textFaint)),
          ]),
        ),
        const Text('›', style: TextStyle(fontSize: 16, color: AppColor.iconGhost)),
      ]),
    ),
  );
}

/// 내 정보 수정 — 키·체중·나이·성별·목표·활동량 수정 후 BMI·기초대사량·권장 칼로리 재계산
class _ProfileEdit extends StatelessWidget {
  const _ProfileEdit();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(children: [
      SubHeader(emoji: '✏️', title: '내 정보 수정', onBack: () => s.go('my')),

      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('닉네임', style: t(12, w: FontWeight.w500, c: AppColor.textFaint)),
          const SizedBox(height: 8),
          AppTextField(
            value: s.nickname,
            fontSize: 15,
            onChanged: (v) => s.setSub(() => s.nickname = v),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('키', style: t(12, w: FontWeight.w500, c: AppColor.textFaint)),
                const SizedBox(height: 8),
                NumberField(
                  value: s.heightCm,
                  unit: 'cm',
                  fontSize: 18,
                  color: AppColor.text,
                  decimal: true,
                  max: 250,
                  onChanged: (v) => s.setSub(() => s.heightCm = v.toDouble()),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('현재 체중', style: t(12, w: FontWeight.w500, c: AppColor.textFaint)),
                const SizedBox(height: 8),
                NumberField(
                  value: s.weightKg,
                  unit: 'kg',
                  fontSize: 18,
                  color: AppColor.text,
                  decimal: true,
                  max: 300,
                  onChanged: (v) => s.setSub(() => s.weightKg = v.toDouble()),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('나이', style: t(12, w: FontWeight.w500, c: AppColor.textFaint)),
                const SizedBox(height: 8),
                NumberField(
                  value: s.age,
                  unit: '세',
                  fontSize: 18,
                  color: AppColor.text,
                  max: 120,
                  onChanged: (v) => s.setSub(() => s.age = v.toInt()),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('성별', style: t(12, w: FontWeight.w500, c: AppColor.textFaint)),
                const SizedBox(height: 8),
                SegmentedRow(
                  options: const ['여성', '남성'],
                  value: s.gender,
                  onChanged: (v) => s.setSub(() => s.gender = v),
                ),
              ]),
            ),
          ]),
        ]),
      ),

      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('목표 체중', style: t(13, w: FontWeight.w700)),
            Text('${s.goalWeight.toStringAsFixed(1)} kg',
                style: t(20, w: FontWeight.w900, c: AppColor.primary)),
          ]),
          DragSlider(
            value: s.goalWeight,
            min: 45,
            max: 70,
            onChanged: (v) => s.setSub(() => s.goalWeight = v),
          ),
          const SizedBox(height: 6),
          RowBetween('감량 목표', s.goalDelta),
        ]),
      ),

      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('목표 · 활동량', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          SegmentedRow(
            options: const ['체중 감량', '체중 유지', '근육 증가'],
            value: s.goal,
            onChanged: (v) => s.setSub(() => s.goal = v),
          ),
          const SizedBox(height: 10),
          SegmentedRow(
            options: const ['적음', '보통', '많음'],
            value: s.activity,
            onChanged: (v) => s.setSub(() => s.activity = v),
          ),
        ]),
      ),

      // 재계산 결과
      AppCard(
        color: AppColor.primaryTint,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('다시 계산된 목표',
              style: t(13, w: FontWeight.w700, c: AppColor.primaryDark)),
          const SizedBox(height: 12),
          Row(children: [
            for (final r in [
              ('BMI', s.bmi.toStringAsFixed(1)),
              ('기초대사량', AppState.comma(s.bmr.round())),
              ('일일 권장', AppState.comma(s.dailyTarget)),
            ])
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$1, style: t(11, c: const Color(0xFF4A7A4E))),
                  const SizedBox(height: 4),
                  Text(r.$2,
                      style: t(19, w: FontWeight.w900, c: const Color(0xFF2F7A34), sp: -0.5)),
                ]),
              ),
          ]),
          const SizedBox(height: 10),
          Text('모든 영양 정보는 참고용이며 의료 진단이 아닙니다.',
              style: t(11, c: const Color(0xFF4A7A4E), h: 1.5)),
        ]),
      ),

      PrimaryButton(
        label: '수정 저장',
        onTap: () {
          s.go('my');
          toast(context, '내 정보를 수정했어요 · 목표가 다시 계산됐어요');
        },
      ),
    ]);
  }
}
