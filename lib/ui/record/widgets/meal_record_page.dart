import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';

/// 식단 촬영/기록 화면 — 사진(자리표시자) + AI 분석 결과 + 저장
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.extraOpen) return const _ExtraInfoBody();

    return ScreenScroll(children: [
      SubHeader(emoji: '📷', title: '식단 기록', onBack: () => s.go('home')),

      PhotoPlaceholder(
        height: 212,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('MEAL PHOTO — 도시락 사진', style: t(11, c: AppColor.textFaint)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('📷 다시 촬영', style: t(12, w: FontWeight.w700, c: Colors.white)),
          ),
        ]),
      ),

      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Pill('AI 분석 완료', fontSize: 10),
            const SizedBox(width: 8),
            Pill('고기 종류 확인 필요',
                bg: const Color(0xFFFFF3EF), fg: AppColor.alertText, fontSize: 10),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('볶음밥', style: t(19, w: FontWeight.w900)),
                    const SizedBox(width: 5),
                    Text('(추정)', style: t(13, c: AppColor.textFaint)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('점심 · 오후 12:40', style: t(12, c: AppColor.textFaint)),
              ]),
            ),
            Text('${s.adjustedKcal}',
                style: t(26, w: FontWeight.w900, c: AppColor.primary, sp: -0.6)),
            const SizedBox(width: 3),
            Text('kcal', style: t(12, c: AppColor.textFaint)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            for (final n in const [
              ('단백질', '22 g'), ('탄수화물', '58 g'), ('지방', '16 g'), ('나트륨', '840 mg'),
            ])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceSunken,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    Text(n.$1, style: t(10, c: AppColor.textFaint)),
                    const SizedBox(height: 4),
                    Text(n.$2, style: t(15, w: FontWeight.w900)),
                  ]),
                ),
              ),
          ]),
        ]),
      ),

      PrimaryButton(
        label: '저장하기',
        onTap: () {
          s.logMeal();
          s.go('home');
          toast(context, '${s.extras['meal']} 기록 저장 · AI 추정값으로 반영됐어요');
        },
      ),
      TextLink(
        label: '부가 정보 입력 ›',
        onTap: () => s.setSub(() => s.extraOpen = true),
      ),
    ]);
  }
}

/// 부가 정보 — 고기 · 소스 · 조리법 · 그릇 · 분량 · 태그 · 메모 (칼로리 보정에 반영됨)
class _ExtraInfoBody extends StatelessWidget {
  const _ExtraInfoBody();

  static const _mealOptions = ['아침', '점심', '저녁', '간식'];
  static const _contextOptions = ['집밥', '도시락', '외식', '배달'];
  static const _carbOptions = ['백미', '현미', '통밀빵', '파스타', '없음'];
  static const _tagOptions = ['#저탄고지', '#비건', '#길거리음식', '#단백질보충', '#야식'];

  static const _hints = {
    'meat': '예: 오리고기',
    'sauce': '예: 스리라차',
    'cook': '예: 에어프라이어',
    'carb': '예: 고구마',
    'meal': '예: 브런치',
    'context': '예: 캠핑',
  };

  Widget _extraField(
      BuildContext context,
      AppState s,
      String key,
      String label,
      List<String> options,
      ) {
    final current = s.extras[key] ?? '';
    final input = s.customInputs[key] ?? '';
    final canApply = input.trim().isNotEmpty;
    return AppCard(
      padding: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: t(13, w: FontWeight.w700)),
        const SizedBox(height: 11),
        ChipWrap(
          options: {...options, if (current.isNotEmpty) current}.toList(),
          isSelected: (o) => current == o,
          onPick: (o) => s.setExtra(key, o),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AppTextField(
              value: input,
              hint: _hints[key] ?? '직접 입력',
              fontSize: 13,
              onChanged: (v) => s.setCustomInput(key, v),
            ),
          ),
          const SizedBox(width: 8),
          SmallButton(
            label: '적용',
            bg: canApply ? AppColor.primaryTint : AppColor.surfaceSunken,
            fg: canApply ? AppColor.primaryDark : AppColor.textGhost,
            onTap: canApply
                ? () {
              if (s.applyCustom(key)) toast(context, '$label 항목을 추가했어요');
            }
                : null,
          ),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final bowl = s.bowls[s.bowlIndex.clamp(0, s.bowls.length - 1)];

    return ScreenScroll(children: [
      SubHeader(
        emoji: '📝',
        title: '부가 정보',
        onBack: () => s.setSub(() => s.extraOpen = false),
        trailing: Text('선택 입력', style: t(12, c: AppColor.textFaint)),
      ),

      AppCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('보정된 칼로리', style: t(12, c: AppColor.textFaint)),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('${s.adjustedKcal}',
                    style: t(26, w: FontWeight.w900, c: AppColor.primary, sp: -0.6)),
                const SizedBox(width: 3),
                Text('kcal', style: t(12, c: AppColor.textFaint)),
              ]),
              const SizedBox(height: 6),
              Text('${s.portion} · ${bowl.name} ${s.fill}', style: t(11, c: AppColor.textFaint)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('AI 추정 ${s.baseKcal}kcal', style: t(11, c: AppColor.textFaint)),
            const SizedBox(height: 2),
            Text('부가 정보 반영 후', style: t(11, c: AppColor.textFaint)),
          ]),
        ]),
      ),

      _extraField(context, s, 'meat', '고기 / 단백질 종류', DietRules.proteinFactor.keys.toList()),
      _extraField(context, s, 'sauce', '소스 / 양념', DietRules.sauceFactor.keys.toList()),
      _extraField(context, s, 'cook', '조리법', DietRules.cookFactor.keys.toList()),
      _extraField(context, s, 'carb', '탄수화물 종류', _carbOptions),
      _extraField(context, s, 'meal', '식사 시간', _mealOptions),
      _extraField(context, s, 'context', '식사 상황', _contextOptions),

      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('섭취 분량', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          SegmentedRow(
            options: const ['전체', '반절', '1/3', '직접'],
            value: s.portion,
            onChanged: s.setPortion,
          ),
          if (s.portion == '직접') ...[
            const SizedBox(height: 12),
            Text('직접 비율 입력', style: t(12, c: AppColor.textFaint)),
            const SizedBox(height: 8),
            NumberField(
              value: s.portionPct,
              unit: '%',
              fontSize: 22,
              max: 300,
              onChanged: (v) => s.setPortionPct(v.toInt()),
            ),
          ],
          const SizedBox(height: 16),
          Text('그릇에 담긴 정도', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          SegmentedRow(
            options: const ['가득', '반', '1/3'],
            value: s.fill,
            onChanged: s.setFill,
          ),
        ]),
      ),

      AppCard(
        padding: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('그릇 선택', style: t(13, w: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => s.setSub(() => s.bowlSheet = true),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text('변경 ›', style: t(12, c: AppColor.textFaint)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            IconTile(bowl.icon, size: 44, radius: 22, bg: AppColor.surfaceSunken, fontSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bowl.name, style: t(15, w: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${bowl.capacityMl}ml · ${bowl.material} · ${s.fill}',
                    style: t(12, c: AppColor.textFaint)),
              ]),
            ),
            if (bowl.isDefault) Pill('기본 그릇', fontSize: 10),
          ]),
        ]),
      ),

      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('자유 메모', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          AppTextField(
            value: s.memo,
            hint: '예: 기름기 좀 많음, 소스는 절반만 뿌렸어요.',
            fontSize: 13,
            maxLines: 3,
            onChanged: (v) => s.setSub(() => s.memo = v),
          ),
        ]),
      ),

      AppCard(
        padding: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('태그', style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          ChipWrap(
            options: {..._tagOptions, ...s.customTags, ...s.tags}.toList(),
            isSelected: (o) => s.tags.contains(o),
            onPick: s.toggleTag,
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: AppTextField(
                value: s.tagInput,
                hint: '새 태그 직접 입력',
                fontSize: 13,
                onChanged: (v) => s.setSub(() => s.tagInput = v),
              ),
            ),
            const SizedBox(width: 8),
            SmallButton(
              label: '추가',
              onTap: () {
                if (s.addCustomTag()) toast(context, '태그를 추가했어요');
              },
            ),
          ]),
        ]),
      ),

      PrimaryButton(
        label: '저장하기',
        onTap: () {
          s.logMeal();
          s.go('home');
          toast(context, '${s.extras['meal']} 기록 저장 · 부가 정보가 반영됐어요');
        },
      ),
      TextLink(
        label: '이 설정을 자주 쓰는 설정으로 저장',
        onTap: () {
          s.saveExtrasAsPreset();
          toast(context, '자주 쓰는 설정으로 저장했어요');
        },
      ),
    ]);
  }
}
