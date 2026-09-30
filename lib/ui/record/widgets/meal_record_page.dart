import 'package:image_picker/image_picker.dart';
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

    return ScreenScroll(
      children: [
        SubHeader(emoji: '📷', title: '식단 기록', onBack: () => s.go('home')),
        _PhotoCard(s: s),
        _AiAnalysisCard(s: s),
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
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.s});

  final AppState s;

  void _pickPhoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                s.pickAndAnalyzeMealPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                s.pickAndAnalyzeMealPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = s.pickedPhotoBytes;

    return GestureDetector(
      onTap: s.analyzingPhoto ? null : () => _pickPhoto(context),
      child: Container(
        height: 260,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardR,
          boxShadow: AppShadow.card,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image.memory(photo, fit: BoxFit.cover)
            else
              const _EmptyPhotoState(),
            if (s.analyzingPhoto) const _AnalyzingOverlay(),
            if (photo != null && !s.analyzingPhoto)
              Positioned(
                right: 12,
                bottom: 12,
                child: _RetakeChip(onTap: () => _pickPhoto(context)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 아직 사진을 안 골랐을 때 — 그냥 회색 칸 대신 뭘 하면 되는지 보여준다.
class _EmptyPhotoState extends StatelessWidget {
  const _EmptyPhotoState();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: AppColor.plantGradient),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadow.tile,
            ),
            child: const Text('📷', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 14),
          Text('오늘 뭐 드셨나요?', style: AppText.cardTitle),
          const SizedBox(height: 6),
          Text(
            '사진 한 장이면 AI가 칼로리와 영양소를 대신 계산해요',
            style: t(12, c: AppColor.textMuted),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: AppRadius.buttonR,
              boxShadow: AppShadow.primaryButton,
            ),
            child: Text(
              '📸 사진 추가하기',
              style: t(13, w: FontWeight.w800, c: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 분석 중일 때 사진 위에 덮는 반투명 오버레이.
class _AnalyzingOverlay extends StatelessWidget {
  const _AnalyzingOverlay();

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black.withValues(alpha: 0.45),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 14),
          Text(
            'AI가 사진을 분석하고 있어요...',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RetakeChip extends StatelessWidget {
  const _RetakeChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '📷 다시 촬영',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _AiAnalysisCard extends StatelessWidget {
  const _AiAnalysisCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) {
    if (s.analyzingPhoto) return const SizedBox.shrink();

    if (s.photoAnalysisError != null) {
      return AppCard(
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.photoAnalysisError!,
                style: t(12, c: AppColor.alertText),
              ),
            ),
          ],
        ),
      );
    }

    if (s.aiMealName == null) return const SizedBox.shrink();

    final nutrients = [
      ('단백질', '${s.aiProteinG?.round() ?? 0} g'),
      ('탄수화물', '${s.aiCarbG?.round() ?? 0} g'),
      ('지방', '${s.aiFatG?.round() ?? 0} g'),
      ('식이섬유', '${s.aiFiberG?.round() ?? 0} g'),
      ('나트륨', '${s.aiSodiumMg?.round() ?? 0} mg'),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                'AI 분석 결과',
                style: t(12, w: FontWeight.w700, c: AppColor.textMuted),
              ),
              if (s.needsPhotoReview) ...[
                const Spacer(),
                Pill(
                  '확인 필요',
                  bg: const Color(0xFFFFF3EF),
                  fg: AppColor.alertText,
                  fontSize: 10,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.aiMealName!,
            style: t(17, w: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${s.adjustedKcal}',
                style: t(28, w: FontWeight.w900, c: AppColor.primary, sp: -0.6),
              ),
              const SizedBox(width: 4),
              Text('kcal', style: t(13, c: AppColor.textFaint)),
            ],
          ),
          const SizedBox(height: 18),
          Row(children: [for (final n in nutrients) _NutrientTile(n: n)]),
        ],
      ),
    );
  }
}

class _NutrientTile extends StatelessWidget {
  const _NutrientTile({required this.n});

  final (String, String) n;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(n.$1, style: t(10, c: AppColor.textFaint)),
          const SizedBox(height: 4),
          Text(n.$2, style: t(15, w: FontWeight.w900)),
        ],
      ),
    ),
  );
}

/// 부가 정보 — 고기 · 소스 · 조리법 · 그릇 · 분량 · 태그 · 메모 (칼로리 보정에 반영됨)
class _ExtraInfoBody extends StatelessWidget {
  const _ExtraInfoBody();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final bowl = s.currentBowl;

    return ScreenScroll(
      children: [
        SubHeader(
          emoji: '📝',
          title: '부가 정보',
          onBack: () => s.setSub(() => s.extraOpen = false),
          trailing: Text('선택 입력', style: t(12, c: AppColor.textFaint)),
        ),

        _AdjustedKcalCard(s: s, bowl: bowl),

        _ExtraFieldCard(
          s: s,
          fieldKey: 'meat',
          label: '고기 / 단백질 종류',
          options: DietRules.proteinFactor.keys.toList(),
        ),
        _ExtraFieldCard(
          s: s,
          fieldKey: 'sauce',
          label: '소스 / 양념',
          options: DietRules.sauceFactor.keys.toList(),
        ),
        _ExtraFieldCard(
          s: s,
          fieldKey: 'cook',
          label: '조리법',
          options: DietRules.cookFactor.keys.toList(),
        ),
        _ExtraFieldCard(
          s: s,
          fieldKey: 'carb',
          label: '탄수화물 종류',
          options: _ExtraFieldCard._carbOptions,
        ),
        _ExtraFieldCard(
          s: s,
          fieldKey: 'meal',
          label: '식사 시간',
          options: _ExtraFieldCard._mealOptions,
        ),
        _ExtraFieldCard(
          s: s,
          fieldKey: 'context',
          label: '식사 상황',
          options: _ExtraFieldCard._contextOptions,
        ),

        _PortionCard(s: s),
        _BowlCard(s: s, bowl: bowl),
        _MemoCard(s: s),
        _TagCard(s: s),

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
      ],
    );
  }
}

class _AdjustedKcalCard extends StatelessWidget {
  const _AdjustedKcalCard({required this.s, required this.bowl});

  final AppState s;
  final Bowl? bowl;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('보정된 칼로리', style: t(12, c: AppColor.textFaint)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${s.adjustedKcal}',
                    style: t(
                      26,
                      w: FontWeight.w900,
                      c: AppColor.primary,
                      sp: -0.6,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text('kcal', style: t(12, c: AppColor.textFaint)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                bowl == null
                    ? '${s.portion} · ${s.fill}'
                    : '${s.portion} · ${bowl!.name} ${s.fill}',
                style: t(11, c: AppColor.textFaint),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'AI 추정 ${s.baseKcal}kcal',
              style: t(11, c: AppColor.textFaint),
            ),
            const SizedBox(height: 2),
            Text('부가 정보 반영 후', style: t(11, c: AppColor.textFaint)),
          ],
        ),
      ],
    ),
  );
}

class _ExtraFieldCard extends StatelessWidget {
  const _ExtraFieldCard({
    required this.s,
    required this.fieldKey,
    required this.label,
    required this.options,
  });

  final AppState s;
  final String fieldKey;
  final String label;
  final List<String> options;

  static const _mealOptions = ['아침', '점심', '저녁', '간식'];
  static const _contextOptions = ['집밥', '도시락', '외식', '배달'];
  static const _carbOptions = ['백미', '현미', '통밀빵', '파스타', '없음'];

  static const _hints = {
    'meat': '예: 오리고기',
    'sauce': '예: 스리라차',
    'cook': '예: 에어프라이어',
    'carb': '예: 고구마',
    'meal': '예: 브런치',
    'context': '예: 캠핑',
  };

  @override
  Widget build(BuildContext context) {
    final current = s.extras[fieldKey] ?? '';
    final input = s.customInputs[fieldKey] ?? '';
    final canApply = input.trim().isNotEmpty;
    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t(13, w: FontWeight.w700)),
          const SizedBox(height: 11),
          ChipWrap(
            options: {...options, if (current.isNotEmpty) current}.toList(),
            isSelected: (o) => current == o,
            onPick: (o) => s.setExtra(fieldKey, o),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  value: input,
                  hint: _hints[fieldKey] ?? '직접 입력',
                  fontSize: 13,
                  onChanged: (v) => s.setCustomInput(fieldKey, v),
                ),
              ),
              const SizedBox(width: 8),
              SmallButton(
                label: '적용',
                bg: canApply ? AppColor.primaryTint : AppColor.surfaceSunken,
                fg: canApply ? AppColor.primaryDark : AppColor.textGhost,
                onTap: canApply
                    ? () {
                        if (s.applyCustom(fieldKey)) {
                          toast(context, '$label 항목을 추가했어요');
                        }
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortionCard extends StatelessWidget {
  const _PortionCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    ),
  );
}

class _BowlCard extends StatelessWidget {
  const _BowlCard({required this.s, required this.bowl});

  final AppState s;
  final Bowl? bowl;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (bowl == null)
              Expanded(
                child: Text(
                  '등록된 그릇이 없어요 · 그릇 없이도 기록할 수 있어요',
                  style: t(12, c: AppColor.textFaint),
                ),
              )
            else ...[
              IconTile(
                bowl!.icon,
                size: 44,
                radius: 22,
                bg: AppColor.surfaceSunken,
                fontSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bowl!.name, style: t(15, w: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      '${bowl!.capacityMl}ml · ${bowl!.material} · ${s.fill}',
                      style: t(12, c: AppColor.textFaint),
                    ),
                  ],
                ),
              ),
              if (bowl!.isDefault) Pill('기본 그릇', fontSize: 10),
            ],
          ],
        ),
      ],
    ),
  );
}

class _MemoCard extends StatelessWidget {
  const _MemoCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('자유 메모', style: t(13, w: FontWeight.w700)),
        const SizedBox(height: 11),
        AppTextField(
          value: s.memo,
          hint: '예: 기름기 좀 많음, 소스는 절반만 뿌렸어요.',
          fontSize: 13,
          maxLines: 3,
          onChanged: (v) => s.setSub(() => s.memo = v),
        ),
      ],
    ),
  );
}

class _TagCard extends StatelessWidget {
  const _TagCard({required this.s});

  final AppState s;

  static const _tagOptions = ['#저탄고지', '#비건', '#길거리음식', '#단백질보충', '#야식'];

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('태그', style: t(13, w: FontWeight.w700)),
        const SizedBox(height: 11),
        ChipWrap(
          options: {..._tagOptions, ...s.customTags, ...s.tags}.toList(),
          isSelected: (o) => s.tags.contains(o),
          onPick: s.toggleTag,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
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
          ],
        ),
      ],
    ),
  );
}
