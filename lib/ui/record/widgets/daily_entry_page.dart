// 매일 입력하는 나머지 기록 — 운동(+루틴) · 체중 · 물 시트 · 그릇 관리

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';
import '../viewmodel/water_view_model.dart';
import '../viewmodel/weight_view_model.dart';

// 운동 기록 (루틴 통합)

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SubHeader(
                emoji: '🏃',
                title: '운동 기록',
                onBack: () => s.go('records'),
              ),
            ),
            Text(
              s.todayDateLabel,
              style: t(AppFontSize.f12, c: AppColor.textFaint),
            ),
          ],
        ),
        const _ExerciseTypeCard(),
        const _ExerciseDurationCard(),
        const _ExerciseBurnCard(),
        const _RoutinesCard(),
        PrimaryButton(
          label: '운동 저장',
          onTap: () {
            s.logExercise();
            s.go('home');
            toast(context, '운동 ${s.exMinutes}분 기록 저장 · 홈에 반영됐어요');
          },
        ),
        TextLink(
          label: '지금 입력한 내용을 루틴으로 저장',
          onTap: () {
            s.saveCurrentAsRoutine();
            toast(context, '현재 입력 내용을 루틴으로 저장했어요');
          },
        ),
      ],
    );
  }
}

class _ExerciseTypeCard extends StatelessWidget {
  const _ExerciseTypeCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('운동 종류', style: t(AppFontSize.f13, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s11),
          AppTextField(
            value: s.exType,
            hint: '예: 달리기',
            fontSize: 15,
            onChanged: (v) => s.setSub(() => s.exType = v),
          ),
          const SizedBox(height: AppSpace.s10),
          Text(
            '직접 입력하거나 아래에서 골라 넣으세요',
            style: t(AppFontSize.f11, c: AppColor.textGhost),
          ),
          const SizedBox(height: AppSpace.s10),
          ChipWrap(
            options: DietRules.exerciseTypeFactor.keys.toList(),
            isSelected: (o) => s.exType == o,
            onPick: (o) => s.setSub(() => s.exType = o),
          ),
        ],
      ),
    );
  }
}

class _ExerciseDurationCard extends StatelessWidget {
  const _ExerciseDurationCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('운동 시간', style: t(AppFontSize.f13, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s11),
          NumberField(
            value: s.exMinutes,
            unit: '분',
            fontSize: 26,
            max: 600,
            onChanged: (v) => s.setSub(() => s.exMinutes = v.toInt()),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('강도', style: t(AppFontSize.f13, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s11),
          SegmentedRow(
            options: const ['낮음', '보통', '높음'],
            value: s.exIntensity,
            onChanged: (v) => s.setSub(() => s.exIntensity = v),
          ),
        ],
      ),
    );
  }
}

class _ExerciseBurnCard extends StatelessWidget {
  const _ExerciseBurnCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      color: AppColor.primaryTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '예상 소모 칼로리',
                style: t(
                  AppFontSize.f13,
                  w: FontWeight.w700,
                  c: AppColor.primaryDark,
                ),
              ),
              const Spacer(),
              Text(
                '${s.exKcal}',
                style: t(
                  AppFontSize.f24,
                  w: FontWeight.w900,
                  c: AppColor.primaryDark,
                  sp: -0.6,
                ),
              ),
              const SizedBox(width: AppSpace.s4),
              Text(
                'kcal',
                style: t(AppFontSize.f12, c: const Color(0xFF4A7A4E)),
              ),
            ],
          ),
          if (!s.exTypeKnown) ...[
            const SizedBox(height: AppSpace.s7),
            Text(
              '등록되지 않은 종류라 기본 계수로 추정했어요',
              style: t(AppFontSize.f11, c: const Color(0xFF4A7A4E), h: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// 내 루틴 — 불러오기 + 추가·삭제 + 이번 주 수행 현황
class _RoutinesCard extends StatelessWidget {
  const _RoutinesCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '내 루틴 ${s.routines.length}개',
                style: t(AppFontSize.f14, w: FontWeight.w700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: s.toggleRoutineEditMode,
                child: Text(
                  s.routineEditMode ? '완료' : '추가・삭제',
                  style: t(
                    AppFontSize.f12,
                    w: FontWeight.w700,
                    c: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Text(
            '루틴을 누르면 위 입력값이 자동으로 채워져요',
            style: t(AppFontSize.f11, c: AppColor.textGhost),
          ),
          const SizedBox(height: AppSpace.s14),
          for (final r in s.routines) _RoutineRow(r: r, s: s),
          const SizedBox(height: AppSpace.s6),
          const Divider(height: AppSpace.s1),
          const SizedBox(height: AppSpace.s16),
          Text('이번 주 루틴 수행', style: t(AppFontSize.f14, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s12),
          for (final r in s.routines) _RoutineWeeklyRow(r: r, s: s),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.r, required this.s});

  final Routine r;
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final loaded =
        s.exType == r.type &&
        s.exMinutes == r.minutes &&
        s.exIntensity == r.intensity.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s10),
      child: GestureDetector(
        onTap: s.routineEditMode
            ? null
            : () {
                s.loadRoutine(r);
                toast(context, '“${r.name}” 루틴을 불러왔어요');
              },
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s14),
          decoration: AppDeco.selectableCard(selected: loaded),
          child: Row(
            children: [
              IconTile(
                r.icon,
                size: 44,
                radius: 22,
                bg: AppColor.surfaceSunken,
                fontSize: 20,
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: t(AppFontSize.f15, w: FontWeight.w700)),
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      '${r.meta} · 이번 달 ${r.used}회',
                      style: t(AppFontSize.f12, c: AppColor.textFaint),
                    ),
                  ],
                ),
              ),
              if (s.routineEditMode)
                GestureDetector(
                  onTap: () {
                    s.removeRoutine(r);
                    toast(context, '루틴을 삭제했어요');
                  },
                  child: Container(
                    width: AppSpace.s24,
                    height: AppSpace.s24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEFF1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '✕',
                      style: t(AppFontSize.f11, c: AppColor.textFaint),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineWeeklyRow extends StatelessWidget {
  const _RoutineWeeklyRow({required this.r, required this.s});

  final Routine r;
  final AppState s;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s10),
    child: Row(
      children: [
        SizedBox(
          width: AppSpace.s64,
          child: Text(
            r.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t(AppFontSize.f12, c: AppColor.textMuted),
          ),
        ),
        Expanded(
          child: ProgressBar(
            value:
                r.weeklyUsed /
                s.routines
                    .map((x) => x.weeklyUsed)
                    .reduce((a, b) => a > b ? a : b)
                    .clamp(1, 999),
          ),
        ),
        const SizedBox(width: AppSpace.s8),
        SizedBox(
          width: AppSpace.s24,
          child: Text(
            '${r.weeklyUsed}회',
            textAlign: TextAlign.right,
            style: t(AppFontSize.f12, c: AppColor.textFaint),
          ),
        ),
      ],
    ),
  );
}

// 체중 기록

class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final weight = context.watch<WeightViewModel>();

    return ScreenScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SubHeader(
                emoji: '⚖️',
                title: '체중 기록',
                onBack: () => s.go('records'),
              ),
            ),
            Text(
              s.todayDateLabel,
              style: t(AppFontSize.f12, c: AppColor.textFaint),
            ),
          ],
        ),
        const _WeightInputCard(),
        const _WeightHistoryCard(),
        PrimaryButton(
          label: '체중 저장',
          onTap: () {
            if (weight.weightInput <= 0) {
              return toast(context, '체중을 입력해 주세요');
            }
            weight.logWeight();
            s.onWeightLogged(weight.weightInput);
            s.go('home');
            toast(
              context,
              '체중 ${weight.weightInput.toStringAsFixed(1)}kg을 저장했어요',
            );
          },
        ),
      ],
    );
  }
}

class _WeightInputCard extends StatelessWidget {
  const _WeightInputCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final weight = context.watch<WeightViewModel>();
    return AppCard(
      padding: 22,
      child: Column(
        children: [
          Text('오늘 체중', style: t(AppFontSize.f12, c: AppColor.textFaint)),
          const SizedBox(height: AppSpace.s12),
          NumberField(
            value: weight.weightInput,
            unit: 'kg',
            fontSize: 40,
            decimal: true,
            center: true,
            max: 300,
            onChanged: (v) => weight.setWeightInput(v.toDouble()),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            '어제보다 ${weight.weightDiffFrom(s.profile.weightKg)}',
            style: t(AppFontSize.f12, w: FontWeight.w700, c: AppColor.primary),
          ),
          const SizedBox(height: AppSpace.s20),
          // 읽기 전용 — 목표 체중 위치에 고정. 드래그해서 바뀌지 않아요.
          DragSlider(value: s.goalWeight, min: 45, max: 70),
          const SizedBox(height: AppSpace.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('45kg', style: t(AppFontSize.f10, c: AppColor.textGhost)),
              Text(
                '목표 ${s.goalWeight.toStringAsFixed(1)}kg',
                style: t(AppFontSize.f10, c: AppColor.textGhost),
              ),
              Text('70kg', style: t(AppFontSize.f10, c: AppColor.textGhost)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightHistoryCard extends StatelessWidget {
  const _WeightHistoryCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    context.watch<WeightViewModel>();
    final days = s.recentWeightDays;
    final recorded = [for (final d in days) ?d.kg];
    final lo = recorded.isEmpty
        ? 0.0
        : recorded.reduce((a, b) => a < b ? a : b);
    final hi = recorded.isEmpty
        ? 0.0
        : recorded.reduce((a, b) => a > b ? a : b);

    // 막대 높이: 기록한 날은 최저~최고를 24~58px에 맞춰 보여주고, 기록 없는 날은 짧은 자리표시.
    double barHeight(double? kg) {
      if (kg == null) return 6;
      if (hi == lo) return 40;
      return 24 + 34 * (kg - lo) / (hi - lo);
    }

    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('최근 7일', style: t(AppFontSize.f13, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s12),
          SizedBox(
            // 막대(최대 58) + 위·아래 글자 + 여백이 글자 크기 1.3배에서도 들어가도록 여유를 둔다.
            height: AppSpace.s110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (d.kg != null)
                            Text(
                              d.kg!.toStringAsFixed(1),
                              maxLines: 1,
                              style: t(AppFontSize.f9, c: AppColor.textFaint),
                            ),
                          const SizedBox(height: AppSpace.s2),
                          Container(
                            height: barHeight(d.kg),
                            decoration: BoxDecoration(
                              color: d.kg == null
                                  ? AppColor.divider
                                  : d.isToday
                                  ? AppColor.primary
                                  : AppColor.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: AppSpace.s5),
                          Text(
                            '${d.day}',
                            style: t(
                              AppFontSize.f9,
                              w: d.isToday ? FontWeight.w700 : FontWeight.w400,
                              c: d.isToday ? AppColor.text : AppColor.textGhost,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (recorded.isEmpty) ...[
            const SizedBox(height: AppSpace.s8),
            Text(
              '체중을 기록하면 여기에 7일 변화가 보여요.',
              style: t(AppFontSize.f11, c: AppColor.textGhost),
            ),
          ],
        ],
      ),
    );
  }
}
// 물 기록 시트 (화면 대신 시트)

class WaterSheet extends StatelessWidget {
  const WaterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final water = context.watch<WaterViewModel>();

    return SheetScaffold(
      title: '물 기록',
      subtitle:
          '오늘 ${AppState.comma(water.waterTotal)} / 2,000ml · ${AppState.comma(water.waterLeft)}ml 남음',
      leading: const IconTile(
        '💧',
        size: 40,
        radius: 20,
        bg: Color(0xFFEAF1FE),
        fontSize: 18,
      ),
      trailing: Text(
        '${water.waterPct}%',
        style: t(
          AppFontSize.f24,
          w: FontWeight.w900,
          c: AppColor.info,
          sp: -0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 가로 진행바
          ProgressBar(
            value: water.waterPct / 100,
            height: AppSpace.s8,
            color: AppColor.info,
            track: AppColor.divider,
          ),
          const SizedBox(height: AppSpace.s18),
          const _WaterInputRow(),
          const SizedBox(height: AppSpace.s20),
          const _WaterEntryList(),
          const SizedBox(height: AppSpace.s16),
          PrimaryButton(
            label: '완료',
            onTap: () => s.setSub(() => s.waterSheet = false),
          ),
        ],
      ),
    );
  }
}

/// ml 직접 입력 + 추가 버튼
class _WaterInputRow extends StatelessWidget {
  const _WaterInputRow();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final water = context.watch<WaterViewModel>();
    return Row(
      children: [
        Expanded(
          child: NumberField(
            value: water.waterInput,
            unit: 'ml',
            fontSize: 32,
            color: const Color(0xFF3C63C0),
            max: 3000,
            onChanged: (v) => water.setWaterInput(v.toInt()),
          ),
        ),
        const SizedBox(width: AppSpace.s10),
        GestureDetector(
          onTap: () {
            if (water.waterInput <= 0) {
              return toast(context, '추가할 용량을 입력해 주세요');
            }
            final ml = water.waterInput;
            water.addWater();
            s.onWaterAdded(ml);
            toast(context, '물 ${ml}ml를 기록했어요');
          },
          child: Container(
            height: AppSpace.s58,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s26),
            decoration: BoxDecoration(
              color: AppColor.info,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '추가',
              style: t(AppFontSize.f15, w: FontWeight.w700, c: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 오늘 기록 목록 — 헤더(건수 · 마지막 기록 취소) + 항목별 수정 · 삭제
class _WaterEntryList extends StatelessWidget {
  const _WaterEntryList();

  @override
  Widget build(BuildContext context) {
    final water = context.watch<WaterViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '오늘 기록 ${water.waterEntries.length}건',
              style: t(AppFontSize.f13, w: FontWeight.w700),
            ),
            const Spacer(),
            GestureDetector(
              onTap: water.undoWater,
              child: Text(
                '마지막 기록 취소',
                style: t(AppFontSize.f11, c: AppColor.textFaint),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s4),
        Text(
          '숫자를 눌러 수정하거나 ✕로 삭제할 수 있어요',
          style: t(AppFontSize.f10, c: AppColor.textGhost),
        ),
        const SizedBox(height: AppSpace.s10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: water.waterEntries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s10),
            itemBuilder: (_, i) => _WaterEntryRow(index: i, water: water),
          ),
        ),
      ],
    );
  }
}

class _WaterEntryRow extends StatelessWidget {
  const _WaterEntryRow({required this.index, required this.water});

  final int index;
  final WaterViewModel water;

  @override
  Widget build(BuildContext context) {
    final e = water.waterEntries[index];
    return SunkenBox(
      padding: 10,
      radius: 14,
      child: Row(
        children: [
          const SizedBox(width: AppSpace.s4),
          SizedBox(
            width: AppSpace.s40,
            child: Text(
              e.time,
              style: t(AppFontSize.f11, c: AppColor.textGhost),
            ),
          ),
          Expanded(
            child: NumberField(
              value: e.ml,
              unit: 'ml',
              fontSize: 18,
              color: const Color(0xFF3C63C0),
              max: 3000,
              onChanged: (v) => water.editWater(index, v.toInt()),
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          GestureDetector(
            onTap: () => water.removeWater(index),
            child: Container(
              width: AppSpace.s24,
              height: AppSpace.s24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFEDEFF1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '✕',
                style: t(AppFontSize.f11, c: AppColor.textFaint),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s6),
        ],
      ),
    );
  }
}

// 그릇 관리 — 추가 · 수정 · 삭제를 한 화면에서

class BowlsScreen extends StatelessWidget {
  const BowlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      children: [
        SubHeader(
          emoji: '🥣',
          title: '내 그릇 관리',
          onBack: () => s.go('my'),
          trailing: Text(
            '${s.bowls.length} / ${DietRules.maxBowls}',
            style: t(AppFontSize.f12, c: AppColor.textFaint),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
          child: Text(
            '자주 쓰는 그릇을 등록하면 식단 기록 시 분량을 자동 보정해요.',
            style: t(AppFontSize.f12, c: AppColor.textFaint, h: 1.6),
          ),
        ),
        // 신규 추가 폼 (인라인)
        if (s.bowlEditing == -1) const _BowlForm(),
        for (final (i, b) in s.bowls.indexed)
          if (s.bowlEditing == i)
            const _BowlForm()
          else
            _BowlCard(index: i, bowl: b, s: s),
        if (s.bowlEditing == -1) _AddBowlButton(s: s),
        const _BowlRulesCard(),
      ],
    );
  }
}

class _BowlCard extends StatelessWidget {
  const _BowlCard({required this.index, required this.bowl, required this.s});

  final int index;
  final Bowl bowl;
  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 14,
    child: Row(
      children: [
        IconTile(
          bowl.icon,
          size: 54,
          radius: 18,
          bg: AppColor.surfaceSunken,
          fontSize: 22,
        ),
        const SizedBox(width: AppSpace.s13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      bowl.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t(AppFontSize.f14, w: FontWeight.w700),
                    ),
                  ),
                  if (bowl.isDefault) ...[
                    const SizedBox(width: AppSpace.s7),
                    Pill('기본', fontSize: 9),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.s4),
              Text(
                bowl.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t(AppFontSize.f11, c: AppColor.textFaint),
              ),
              if (bowl.memo.isNotEmpty) ...[
                const SizedBox(height: AppSpace.s3),
                Text(
                  bowl.memo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t(AppFontSize.f11, c: AppColor.textGhost),
                ),
              ],
            ],
          ),
        ),
        Column(
          children: [
            SmallButton(label: '수정', onTap: () => s.startEditBowl(index)),
            const SizedBox(height: AppSpace.s6),
            GestureDetector(
              onTap: () {
                s.removeBowl(index);
                toast(context, '그릇을 삭제했어요');
              },
              child: Text(
                '삭제',
                style: t(AppFontSize.f11, c: const Color(0xFFC0C6CB)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AddBowlButton extends StatelessWidget {
  const _AddBowlButton({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      if (s.bowls.length >= DietRules.maxBowls) {
        return toast(context, '그릇은 최대 ${DietRules.maxBowls}개까지 등록할 수 있어요');
      }
      s.startAddBowl();
    },
    child: Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFA),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFC9D2CB), width: 1.5),
      ),
      child: Text(
        '+ 그릇 추가',
        style: t(AppFontSize.f14, w: FontWeight.w700, c: AppColor.primary),
      ),
    ),
  );
}

class _BowlRulesCard extends StatelessWidget {
  const _BowlRulesCard();

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('분량 보정 규칙', style: t(AppFontSize.f13, w: FontWeight.w700)),
        const SizedBox(height: AppSpace.s8),
        RowBetween('회사 도시락(500ml) + 가득', '× 1.0'),
        RowBetween('집 밥그릇(300ml) + 반', '× 0.5'),
        RowBetween('샐러드 볼(대) + 1/3', '× 0.33'),
      ],
    ),
  );
}

class _BowlForm extends StatelessWidget {
  const _BowlForm();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final d = s.draftBowl;
    final isNew = s.bowlEditing == -1;

    return AppCard(
      border: AppColor.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNew ? '그릇 추가' : '그릇 수정',
            style: t(AppFontSize.f14, w: FontWeight.w900),
          ),
          const SizedBox(height: AppSpace.s14),
          PhotoPlaceholder(
            height: AppSpace.s110,
            radius: 18,
            child: Text(
              'EMPTY BOWL PHOTO (선택)',
              style: t(AppFontSize.f10, c: AppColor.textFaint),
            ),
          ),
          const SizedBox(height: AppSpace.s14),
          Text(
            '그릇 이름',
            style: t(
              AppFontSize.f12,
              w: FontWeight.w500,
              c: AppColor.textFaint,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          AppTextField(
            value: d.name,
            hint: '예: 회사 도시락',
            fontSize: 15,
            onChanged: (v) => s.setSub(() => d.name = v),
          ),
          const SizedBox(height: AppSpace.s14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '용량',
                      style: t(
                        AppFontSize.f12,
                        w: FontWeight.w500,
                        c: AppColor.textFaint,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s8),
                    NumberField(
                      value: d.capacityMl,
                      unit: 'ml',
                      fontSize: 18,
                      color: AppColor.text,
                      max: 5000,
                      onChanged: (v) =>
                          s.setSub(() => d.capacityMl = v.toInt()),
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
                      '보정 계수',
                      style: t(
                        AppFontSize.f12,
                        w: FontWeight.w500,
                        c: AppColor.textFaint,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s8),
                    SunkenBox(
                      padding: 15,
                      radius: 16,
                      child: Text(
                        '× ${d.capacityFactor.toStringAsFixed(2)}',
                        style: t(
                          AppFontSize.f16,
                          w: FontWeight.w900,
                          c: AppColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          for (final f in const [
            (
              title: '기준 분량',
              key: 'portion',
              items: ['소', '중', '대', '1인분', '2인분'],
            ),
            (
              title: '재질',
              key: 'material',
              items: ['도자기', '플라스틱', '스테인리스', '종이', '유리'],
            ),
            (title: '형태', key: 'shape', items: ['원형', '사각', '도시락', '컵', '접시']),
          ]) ...[
            Text(f.title, style: t(AppFontSize.f13, w: FontWeight.w700)),
            const SizedBox(height: AppSpace.s10),
            ChipWrap(
              options: f.items,
              isSelected: (o) => switch (f.key) {
                'portion' => d.portion == o,
                'material' => d.material == o,
                _ => d.shape == o,
              },
              onPick: (o) => s.setSub(() {
                switch (f.key) {
                  case 'portion':
                    d.portion = o;
                  case 'material':
                    d.material = o;
                  default:
                    d.shape = o;
                }
              }),
            ),
            const SizedBox(height: AppSpace.s16),
          ],
          Text('메모', style: t(AppFontSize.f13, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s10),
          AppTextField(
            value: d.memo,
            hint: '예: 항상 가득 채워 먹음',
            fontSize: 12,
            onChanged: (v) => s.setSub(() => d.memo = v),
          ),
          const SizedBox(height: AppSpace.s14),
          SunkenBox(
            padding: 12,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기본 그릇으로 설정',
                        style: t(AppFontSize.f13, w: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpace.s3),
                      Text(
                        '식단 기록 시 자동 선택돼요 (1개만 가능)',
                        style: t(AppFontSize.f11, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                ),
                AppToggle(
                  value: d.isDefault,
                  onChanged: () => s.setSub(() => d.isDefault = !d.isDefault),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: s.cancelBowlEdit,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
                    decoration: BoxDecoration(
                      color: AppColor.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(
                      '취소',
                      style: t(
                        AppFontSize.f14,
                        w: FontWeight.w700,
                        c: AppColor.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s10),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: isNew ? '그릇 저장' : '수정 저장',
                  enabled: d.name.trim().isNotEmpty,
                  onTap: () {
                    if (!s.saveBowl()) return toast(context, '그릇 이름을 입력해 주세요');
                    toast(context, '“${d.name}” 그릇을 저장했어요');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
