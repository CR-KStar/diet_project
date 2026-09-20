// 매일 입력하는 나머지 기록 — 운동(+루틴) · 체중(+눈바디) · 물 시트 · 그릇 관리

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

// ─────────────────────────────────────────────────────────
// 운동 기록 (루틴 통합)
// ─────────────────────────────────────────────────────────

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: SubHeader(emoji: '🏃', title: '운동 기록', onBack: () => s.go('records'))),
          Text('8월 19일', style: t(12, c: AppColor.textFaint)),
        ],
      ),

      // 종류 직접 입력
      AppCard(
        padding: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('운동 종류', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          AppTextField(
            value: s.exType,
            hint: '예: 달리기',
            fontSize: 15,
            onChanged: (v) => s.setSub(() => s.exType = v),
          ),
          const SizedBox(height: 10),
          Text('직접 입력하거나 아래에서 골라 넣으세요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 10),
          ChipWrap(
            options: DietRules.exerciseTypeFactor.keys.toList(),
            isSelected: (o) => s.exType == o,
            onPick: (o) => s.setSub(() => s.exType = o),
          ),
        ]),
      ),

      // 시간 · 강도
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('운동 시간', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          NumberField(
            value: s.exMinutes,
            unit: '분',
            fontSize: 26,
            max: 600,
            onChanged: (v) => s.setSub(() => s.exMinutes = v.toInt()),
          ),
          const SizedBox(height: 16),
          Text('강도', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          SegmentedRow(
            options: const ['낮음', '보통', '높음'],
            value: s.exIntensity,
            onChanged: (v) => s.setSub(() => s.exIntensity = v),
          ),
        ]),
      ),

      // 예상 소모
      AppCard(
        color: AppColor.primaryTint,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('예상 소모 칼로리',
                style: t(13, w: FontWeight.w700, c: AppColor.primaryDark)),
            const Spacer(),
            Text('${s.exKcal}',
                style: t(24, w: FontWeight.w900, c: AppColor.primaryDark, sp: -0.6)),
            const SizedBox(width: 4),
            Text('kcal', style: t(12, c: const Color(0xFF4A7A4E))),
          ]),
          if (!s.exTypeKnown) ...[
            const SizedBox(height: 7),
            Text('등록되지 않은 종류라 기본 계수로 추정했어요',
                style: t(11, c: const Color(0xFF4A7A4E), h: 1.5)),
          ],
        ]),
      ),

      // 내 루틴 — 불러오기 + 추가·삭제 + 이번 주 수행 현황
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('내 루틴 ${s.routines.length}개', style: t(14, w: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: s.toggleRoutineEditMode,
              child: Text(s.routineEditMode ? '완료' : '추가・삭제',
                  style: t(12, w: FontWeight.w700, c: AppColor.primary)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('루틴을 누르면 위 입력값이 자동으로 채워져요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 14),
          for (final r in s.routines)
                () {
              final loaded = s.exType == r.type &&
                  s.exMinutes == r.minutes &&
                  s.exIntensity == r.intensity.label;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: s.routineEditMode
                      ? null
                      : () {
                    s.loadRoutine(r);
                    toast(context, '“${r.name}” 루틴을 불러왔어요');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppDeco.selectableCard(selected: loaded),
                    child: Row(children: [
                      IconTile(r.icon, size: 44, radius: 22, bg: AppColor.surfaceSunken, fontSize: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.name, style: t(15, w: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${r.meta} · 이번 달 ${r.used}회',
                              style: t(12, c: AppColor.textFaint)),
                        ]),
                      ),
                      if (s.routineEditMode)
                        GestureDetector(
                          onTap: () {
                            s.removeRoutine(r);
                            toast(context, '루틴을 삭제했어요');
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDEFF1),
                              shape: BoxShape.circle,
                            ),
                            child: Text('✕', style: t(11, c: AppColor.textFaint)),
                          ),
                        ),
                    ]),
                  ),
                ),
              );
            }(),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text('이번 주 루틴 수행', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final r in s.routines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                SizedBox(width: 64, child: Text(r.name, style: t(12, c: AppColor.textMuted))),
                Expanded(
                  child: ProgressBar(
                    value: r.weeklyUsed /
                        s.routines.map((x) => x.weeklyUsed).reduce((a, b) => a > b ? a : b).clamp(1, 999),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: Text('${r.weeklyUsed}회',
                      textAlign: TextAlign.right, style: t(12, c: AppColor.textFaint)),
                ),
              ]),
            ),
        ]),
      ),

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
    ]);
  }
}

// ─────────────────────────────────────────────────────────
// 체중 기록 (눈바디 2장 필수)
// ─────────────────────────────────────────────────────────

class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: SubHeader(emoji: '⚖️', title: '체중 기록', onBack: () => s.go('records'))),
          Text('8월 19일 오전', style: t(12, c: AppColor.textFaint)),
        ],
      ),

      AppCard(
        padding: 22,
        child: Column(children: [
          Text('오늘 체중', style: t(12, c: AppColor.textFaint)),
          const SizedBox(height: 12),
          NumberField(
            value: s.weightInput,
            unit: 'kg',
            fontSize: 40,
            decimal: true,
            center: true,
            max: 300,
            onChanged: (v) => s.setSub(() => s.weightInput = v.toDouble()),
          ),
          const SizedBox(height: 8),
          Text('어제보다 ${s.weightDiff}',
              style: t(12, w: FontWeight.w700, c: AppColor.primary)),
          const SizedBox(height: 20),
          // 읽기 전용 — 목표 체중 위치에 고정. 드래그해서 바뀌지 않아요.
          DragSlider(
            value: s.goalWeight,
            min: 50,
            max: 65,
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('50kg', style: t(10, c: AppColor.textGhost)),
            Text('목표 ${s.goalWeight.toStringAsFixed(1)}kg', style: t(10, c: AppColor.textGhost)),
            Text('65kg', style: t(10, c: AppColor.textGhost)),
          ]),
        ]),
      ),

      // 눈바디 — 필수
      AppCard(
        padding: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('눈바디 사진', style: t(13, w: FontWeight.w700)),
            const SizedBox(width: 7),
            Pill('필수',
                bg: const Color(0xFFFFF3EF), fg: AppColor.alertText, fontSize: 9),
          ]),
          const SizedBox(height: 6),
          Text('정면·측면 2장을 촬영해야 체중이 저장돼요.', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 12),
          Row(children: [
            for (final b in const [('FRONT', '정면'), ('SIDE', '측면')])
                  () {
                final done = s.bodyShots[b.$1]!;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: b.$1 == 'FRONT' ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => s.toggleBodyShot(b.$1),
                      child: Container(
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: done ? const Color(0xFFF2F5F6) : const Color(0xFFFFFCFB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: done ? AppColor.primary : const Color(0xFFF0A98F),
                            width: 1.5,
                          ),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${b.$2} ${b.$1}',
                              style: t(9, c: done ? AppColor.textFaint : AppColor.primary)),
                          const SizedBox(height: 6),
                          Text(done ? '촬영 완료' : '＋ 촬영 필요',
                              style: t(10,
                                  w: FontWeight.w700,
                                  c: done ? AppColor.primary : AppColor.alertText)),
                        ]),
                      ),
                    ),
                  ),
                );
              }(),
          ]),
          const SizedBox(height: 10),
          Text('사진은 암호화되어 본인만 볼 수 있어요.', style: t(11, c: AppColor.textGhost)),
        ]),
      ),

      // 최근 7일
      AppCard(
        padding: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('최근 7일', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final d in const [
                (13, 58.0, false), (14, 55.0, false), (15, 50.0, false), (16, 52.0, false),
                (17, 45.0, true), (18, 42.0, true), (19, 36.0, true),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.5),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(
                        height: d.$2,
                        decoration: BoxDecoration(
                          color: d.$1 == 19
                              ? AppColor.primary
                              : d.$3
                              ? AppColor.secondary
                              : const Color(0xFFDCE6DD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('${d.$1}',
                          style: t(9,
                              w: d.$1 == 19 ? FontWeight.w700 : FontWeight.w400,
                              c: d.$1 == 19 ? AppColor.text : AppColor.textGhost)),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),

      PrimaryButton(
        label: s.bodyShotsOk ? '체중 저장' : '눈바디 2장을 촬영해 주세요',
        enabled: s.bodyShotsOk,
        onTap: () {
          if (!s.bodyShotsOk) return toast(context, '눈바디 정면·측면 사진을 촬영해 주세요');
          s.logWeight();
          s.go('home');
          toast(context, '체중 ${s.weightInput.toStringAsFixed(1)}kg · 눈바디 2장 저장');
        },
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────
// 물 기록 시트 (화면 대신 시트)
// ─────────────────────────────────────────────────────────

class WaterSheet extends StatelessWidget {
  const WaterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return SheetScaffold(
      title: '물 기록',
      subtitle: '오늘 ${AppState.comma(s.waterTotal)} / 2,000ml · ${AppState.comma(s.waterLeft)}ml 남음',
      leading: const IconTile('💧', size: 40, radius: 20, bg: Color(0xFFEAF1FE), fontSize: 18),
      trailing: Text('${s.waterPct}%', style: t(24, w: FontWeight.w900, c: AppColor.info, sp: -0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 가로 진행바
        ProgressBar(value: s.waterPct / 100, height: 8, color: AppColor.info, track: AppColor.divider),
        const SizedBox(height: 18),

        // ml 직접 입력 + 추가
        Row(children: [
          Expanded(
            child: NumberField(
              value: s.waterInput,
              unit: 'ml',
              fontSize: 32,
              color: const Color(0xFF3C63C0),
              max: 3000,
              onChanged: (v) => s.setSub(() => s.waterInput = v.toInt()),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (s.waterInput <= 0) return toast(context, '추가할 용량을 입력해 주세요');
              s.addWater();
              toast(context, '물 ${s.waterInput}ml를 기록했어요');
            },
            child: Container(
              height: 58,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              decoration: BoxDecoration(
                color: AppColor.info,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('추가', style: t(15, w: FontWeight.w700, c: Colors.white)),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // 기록 목록 — 수정 · 삭제
        Row(children: [
          Text('오늘 기록 ${s.waterEntries.length}건', style: t(13, w: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: s.undoWater,
            child: Text('마지막 기록 취소', style: t(11, c: AppColor.textFaint)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('숫자를 눌러 수정하거나 ✕로 삭제할 수 있어요', style: t(10, c: AppColor.textGhost)),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: s.waterEntries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final e = s.waterEntries[i];
              return SunkenBox(
                padding: 10,
                radius: 14,
                child: Row(children: [
                  const SizedBox(width: 4),
                  SizedBox(width: 40, child: Text(e.time, style: t(11, c: AppColor.textGhost))),
                  Expanded(
                    child: NumberField(
                      value: e.ml,
                      unit: 'ml',
                      fontSize: 18,
                      color: const Color(0xFF3C63C0),
                      max: 3000,
                      onChanged: (v) => s.editWater(i, v.toInt()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => s.removeWater(i),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDEFF1),
                        shape: BoxShape.circle,
                      ),
                      child: Text('✕', style: t(11, c: AppColor.textFaint)),
                    ),
                  ),
                  const SizedBox(width: 6),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: '완료',
          onTap: () {
            s.setSub(() => s.waterSheet = false);
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 그릇 관리 — 추가 · 수정 · 삭제를 한 화면에서
// ─────────────────────────────────────────────────────────

class BowlsScreen extends StatelessWidget {
  const BowlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(children: [
      SubHeader(
        emoji: '🥣',
        title: '내 그릇 관리',
        onBack: () => s.go('my'),
        trailing: Text('${s.bowls.length} / ${DietRules.maxBowls}',
            style: t(12, c: AppColor.textFaint)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('자주 쓰는 그릇을 등록하면 식단 기록 시 분량을 자동 보정해요.',
            style: t(12, c: AppColor.textFaint, h: 1.6)),
      ),

      // 신규 추가 폼 (인라인)
      if (s.bowlEditing == -1) const _BowlForm(),

      for (final (i, b) in s.bowls.indexed)
        if (s.bowlEditing == i)
          const _BowlForm()
        else
          AppCard(
            padding: 14,
            child: Row(children: [
              IconTile(b.icon, size: 54, radius: 18, bg: AppColor.surfaceSunken, fontSize: 22),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(b.name, style: t(14, w: FontWeight.w700)),
                    if (b.isDefault) ...[
                      const SizedBox(width: 7),
                      Pill('기본', fontSize: 9),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(b.meta, style: t(11, c: AppColor.textFaint)),
                  if (b.memo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(b.memo, style: t(11, c: AppColor.textGhost)),
                  ],
                ]),
              ),
              Column(children: [
                SmallButton(label: '수정', onTap: () => s.startEditBowl(i)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    s.removeBowl(i);
                    toast(context, '그릇을 삭제했어요');
                  },
                  child: Text('삭제', style: t(11, c: const Color(0xFFC0C6CB))),
                ),
              ]),
            ]),
          ),

      if (s.bowlEditing == -1)
        GestureDetector(
          onTap: () {
            if (s.bowls.length >= DietRules.maxBowls) {
              return toast(context, '그릇은 최대 ${DietRules.maxBowls}개까지 등록할 수 있어요');
            }
            s.startAddBowl();
          },
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFCFA),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: const Color(0xFFC9D2CB), width: 1.5),
            ),
            child: Text('+ 그릇 추가',
                style: t(14, w: FontWeight.w700, c: AppColor.primary)),
          ),
        ),

      AppCard(
        padding: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('분량 보정 규칙', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 8),
          RowBetween('회사 도시락(500ml) + 가득', '× 1.0'),
          RowBetween('집 밥그릇(300ml) + 반', '× 0.5'),
          RowBetween('샐러드 볼(대) + 1/3', '× 0.33'),
        ]),
      ),
    ]);
  }
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isNew ? '그릇 추가' : '그릇 수정', style: t(14, w: FontWeight.w900)),
        const SizedBox(height: 14),
        PhotoPlaceholder(
          height: 110,
          radius: 18,
          child: Text('EMPTY BOWL PHOTO (선택)', style: t(10, c: AppColor.textFaint)),
        ),
        const SizedBox(height: 14),
        Text('그릇 이름', style: t(12, w: FontWeight.w500, c: AppColor.textFaint)),
        const SizedBox(height: 8),
        AppTextField(
          value: d.name,
          hint: '예: 회사 도시락',
          fontSize: 15,
          onChanged: (v) => s.setSub(() => d.name = v),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('용량', style: t(12, w: FontWeight.w500, c: AppColor.textFaint)),
              const SizedBox(height: 8),
              NumberField(
                value: d.capacityMl,
                unit: 'ml',
                fontSize: 18,
                color: AppColor.text,
                max: 5000,
                onChanged: (v) => s.setSub(() => d.capacityMl = v.toInt()),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('보정 계수', style: t(12, w: FontWeight.w500, c: AppColor.textFaint)),
              const SizedBox(height: 8),
              SunkenBox(
                padding: 15,
                radius: 16,
                child: Text('× ${d.capacityFactor.toStringAsFixed(2)}',
                    style: t(16, w: FontWeight.w900, c: AppColor.primary)),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        for (final f in const [
          (title: '기준 분량', key: 'portion', items: ['소', '중', '대', '1인분', '2인분']),
          (title: '재질', key: 'material', items: ['도자기', '플라스틱', '스테인리스', '종이', '유리']),
          (title: '형태', key: 'shape', items: ['원형', '사각', '도시락', '컵', '접시']),
        ]) ...[
          Text(f.title, style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 10),
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
          const SizedBox(height: 16),
        ],
        Text('메모', style: t(13, w: FontWeight.w700)),
        const SizedBox(height: 10),
        AppTextField(
          value: d.memo,
          hint: '예: 항상 가득 채워 먹음',
          fontSize: 12,
          onChanged: (v) => s.setSub(() => d.memo = v),
        ),
        const SizedBox(height: 14),
        SunkenBox(
          padding: 12,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('기본 그릇으로 설정', style: t(13, w: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('식단 기록 시 자동 선택돼요 (1개만 가능)',
                    style: t(11, c: AppColor.textFaint)),
              ]),
            ),
            AppToggle(
              value: d.isDefault,
              onChanged: () => s.setSub(() => d.isDefault = !d.isDefault),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: s.cancelBowlEdit,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColor.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text('취소', style: t(14, w: FontWeight.w700, c: AppColor.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
        ]),
      ]),
    );
  }
}
