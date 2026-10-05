import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    // s.step: 1(계정 연결), 2(목표), 3(신체), 4(알림)
    Widget body;
    if (s.step == 2) {
      body = const _GoalStep();
    } else if (s.step == 3) {
      body = const _BodyStep();
    } else if (s.step == 4) {
      body = const _AlertStep();
    } else {
      body = const _AccountLinkStep();
    }

    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(child: body),
    );
  }
}

// 온보딩 1단계 — 계정 연결 · 닉네임 · 약관 (s.step == 1)

class _AccountLinkStep extends StatelessWidget {
  const _AccountLinkStep();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final apple = s.provider == 'Apple';
    final ok = s.requiredTermsOk && s.nickname.trim().isNotEmpty;

    return ScreenScroll(
      horizontal: AppSpace.s20,
      top: AppSpace.s8,
      children: [
        SubHeader(emoji: '🔗', title: '계정 연결', onBack: () => s.go('login')),
        Text(
          '${s.provider} 계정으로 처음 로그인했어요. 아래 정보만 확인하면 바로 시작할 수 있어요.',
          style: t(AppFontSize.f13, c: AppColor.textFaint, h: 1.6),
        ),

        AppCard(
          child: Row(
            children: [
              IconTile(
                apple ? '\uF8FF' : 'G',
                size: 44,
                radius: 14,
                fontSize: 18,
                bg: apple ? const Color(0xFF111111) : const Color(0xFFF1F3F4),
              ),
              const SizedBox(width: AppSpace.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apple
                          ? 'chaerin@privaterelay.appleid.com'
                          : 'chaerin@gmail.com',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t(AppFontSize.f14, w: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      '${s.provider} 계정으로 연결됨',
                      style: t(AppFontSize.f11, c: AppColor.textFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s10),
              GestureDetector(
                onTap: () => s.go('login'),
                child: Text(
                  '변경',
                  style: t(AppFontSize.f11, c: AppColor.textFaint),
                ),
              ),
            ],
          ),
        ),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '앱에서 쓸 닉네임',
                style: t(
                  AppFontSize.f12,
                  w: FontWeight.w500,
                  c: AppColor.textFaint,
                ),
              ),
              const SizedBox(height: AppSpace.s9),
              AppTextField(
                value: s.nickname,
                hint: '닉네임',
                fontSize: 15,
                onChanged: (v) => s.setSub(() => s.nickname = v),
              ),
              const SizedBox(height: AppSpace.s9),
              Text(
                '친구 검색과 챌린지 순위에 표시돼요. 나중에 바꿀 수 있어요.',
                style: t(AppFontSize.f11, c: AppColor.textGhost),
              ),
            ],
          ),
        ),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: s.toggleAllTerms,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s13),
                  child: Row(
                    children: [
                      CheckDot(
                        on: s.terms.values.every((v) => v),
                        size: 22,
                        radius: 7,
                      ),
                      const SizedBox(width: AppSpace.s10),
                      Text(
                        '전체 동의',
                        style: t(AppFontSize.f14, w: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppSpace.s1),
              const SizedBox(height: AppSpace.s13),
              for (final k in s.terms.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => s.toggleTerm(k),
                        child: CheckDot(on: s.terms[k]!),
                      ),
                      const SizedBox(width: AppSpace.s10),
                      Expanded(
                        child: Text(
                          k,
                          style: t(AppFontSize.f12, c: AppColor.textMuted),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => toast(context, '약관 전문을 웹뷰로 엽니다'),
                        child: Text(
                          '보기 ›',
                          style: t(AppFontSize.f11, c: AppColor.textGhost),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        PrimaryButton(
          label: '동의하고 시작하기',
          enabled: ok,
          onTap: () {
            if (!s.requiredTermsOk) return toast(context, '필수 약관에 동의해 주세요');
            if (s.nickname.trim().isEmpty) {
              return toast(context, '닉네임을 입력해 주세요');
            }
            s.goToStep(2);
          },
        ),
        Text(
          '비밀번호는 저장하지 않아요 · 건강 기록은 암호화되어 본인만 조회할 수 있어요.',
          textAlign: TextAlign.center,
          style: t(AppFontSize.f10, c: const Color(0xFFB2B9BE), h: 1.7),
        ),
      ],
    );
  }
}

// 온보딩 3단계 공용 헤더

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.stepNo,
    required this.title,
    required this.desc,
    this.onBack,
  });

  final int stepNo; // 1..3
  final String title;
  final String desc;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: AppSpace.s22,
                child: Text('‹', style: t(AppFontSize.f20, c: AppColor.text)),
              ),
            )
          else
            const SizedBox(width: AppSpace.s22),
          const SizedBox(width: AppSpace.s10),
          Text(
            'STEP $stepNo / 3',
            style: t(AppFontSize.f13, w: FontWeight.w700, c: AppColor.primary),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.s16),
      Text(title, style: t(AppFontSize.f24, w: FontWeight.w900, h: 1.35)),
      const SizedBox(height: AppSpace.s8),
      Text(desc, style: t(AppFontSize.f13, c: AppColor.textFaint, h: 1.6)),
      const SizedBox(height: AppSpace.s16),
      Row(
        children: [
          for (var i = 1; i <= 3; i++) ...[
            if (i > 1) const SizedBox(width: AppSpace.s6),
            Expanded(
              child: Container(
                height: AppSpace.s4,
                decoration: BoxDecoration(
                  color: i <= stepNo
                      ? AppColor.primary
                      : const Color(0xFFE3E7E9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

// STEP 1/3 — 목표 · 활동량 (s.step == 2)

class _GoalStep extends StatelessWidget {
  const _GoalStep();

  static const _goals = [
    ('체중 감량', '식단과 운동으로 체중을 줄여요'),
    ('체중 유지', '지금 체중과 컨디션을 유지해요'),
    ('근육 증가', '체중이 늘어도 근육 위주로 키워요'),
  ];

  static const _activityDesc = {
    '적음': '주로 앉아서 생활하고 운동은 거의 안 해요',
    '보통': '가볍게 걷거나 주 1~2회 운동해요',
    '많음': '주 3회 이상 운동하거나 활동량이 많아요',
  };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      horizontal: AppSpace.s20,
      top: AppSpace.s8,
      children: [
        _StepHeader(
          stepNo: 1,
          title: '어떤 목표로 시작할까요?',
          desc: '목표와 평소 활동량에 맞춰 하루 권장 칼로리를 계산해요.',
          onBack: () => s.setSub(() => s.step = 1),
        ),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('목표', style: t(AppFontSize.f13, w: FontWeight.w700)),
              const SizedBox(height: AppSpace.s12),
              for (final g in _goals) ...[
                GestureDetector(
                  onTap: () => s.setSub(() => s.goal = g.$1),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.s14),
                    decoration: AppDeco.selectableCard(
                      selected: s.goal == g.$1,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.$1,
                                style: t(AppFontSize.f14, w: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpace.s3),
                              Text(
                                g.$2,
                                style: t(
                                  AppFontSize.f11,
                                  c: AppColor.textFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CheckDot(on: s.goal == g.$1, size: 20),
                      ],
                    ),
                  ),
                ),
                if (g != _goals.last) const SizedBox(height: AppSpace.s9),
              ],
            ],
          ),
        ),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('활동량', style: t(AppFontSize.f13, w: FontWeight.w700)),
              const SizedBox(height: AppSpace.s12),
              SegmentedRow(
                options: DietRules.activityFactor.keys.toList(),
                value: s.activity,
                onChanged: (v) => s.setSub(() => s.activity = v),
              ),
              const SizedBox(height: AppSpace.s12),
              Text(
                _activityDesc[s.activity] ?? '',
                style: t(AppFontSize.f11, c: AppColor.textGhost, h: 1.6),
              ),
            ],
          ),
        ),

        PrimaryButton(label: '다음', onTap: () => s.goToStep(3)),
      ],
    );
  }
}

// STEP 2/3 — 신체 정보 (s.step == 3)

class _BodyStep extends StatelessWidget {
  const _BodyStep();

  static String _bmiLabel(double bmi) {
    if (bmi.isInfinite || bmi.isNaN) return '-';
    if (bmi < 18.5) return '저체중';
    if (bmi < 23) return '정상';
    if (bmi < 25) return '과체중';
    return '비만';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      horizontal: AppSpace.s20,
      top: AppSpace.s8,
      children: [
        _StepHeader(
          stepNo: 2,
          title: '신체 정보를 알려주세요',
          desc: '기초대사량과 권장 칼로리를 정확히 계산하는 데 쓰여요.',
          onBack: () => s.setSub(() => s.step = 2),
        ),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _UnderlineField(
                      label: '키',
                      value: s.heightCm,
                      unit: 'cm',
                      decimal: true,
                      onChanged: (v) =>
                          s.setSub(() => s.heightCm = v.toDouble()),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: _UnderlineField(
                      label: '현재 몸무게',
                      value: s.weightKg,
                      unit: 'kg',
                      decimal: true,
                      onChanged: (v) => s.setSub(() {
                        s.weightKg = v.toDouble();
                        s.goalWeight = v.toDouble();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s14),
              Row(
                children: [
                  Expanded(
                    child: _UnderlineField(
                      label: '나이',
                      value: s.age,
                      unit: '세',
                      onChanged: (v) => s.setSub(() => s.age = v.toInt()),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s12),
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
                        const SizedBox(height: AppSpace.s6),
                        Row(
                          children: [
                            Expanded(
                              child: _GenderButton(
                                label: '여성',
                                selected: s.gender == '여성',
                                onTap: () => s.setSub(() => s.gender = '여성'),
                              ),
                            ),
                            const SizedBox(width: AppSpace.s6),
                            Expanded(
                              child: _GenderButton(
                                label: '남성',
                                selected: s.gender == '남성',
                                onTap: () => s.setSub(() => s.gender = '남성'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('자동 계산 결과', style: t(AppFontSize.f14, w: FontWeight.w700)),
              const SizedBox(height: AppSpace.s14),
              Row(
                children: [
                  Expanded(
                    child: _CalcTile(
                      label: 'BMI',
                      value: (s.bmi.isInfinite || s.bmi.isNaN)
                          ? '-'
                          : s.bmi.toStringAsFixed(1),
                      sub: _bmiLabel(s.bmi),
                      highlight: true,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s10),
                  Expanded(
                    child: _CalcTile(
                      label: '기초대사량',
                      value: (s.bmr.isInfinite || s.bmr.isNaN)
                          ? '-'
                          : AppState.comma(s.bmr.round()),
                      sub: 'kcal',
                    ),
                  ),
                  const SizedBox(width: AppSpace.s10),
                  Expanded(
                    child: _CalcTile(
                      label: '일일 권장',
                      value: AppState.comma(s.dailyTarget),
                      sub: 'kcal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s12),
              Text(
                '모든 영양 정보는 참고용이며 의료 진단이 아닙니다.',
                style: t(AppFontSize.f11, c: AppColor.textGhost, h: 1.5),
              ),
            ],
          ),
        ),

        PrimaryButton(label: '다음', onTap: () => s.goToStep(4)),
      ],
    );
  }
}

/// 성별 선택 버튼 — 선택 시 primaryTint 배경 + primary 테두리
class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s11),
      decoration: BoxDecoration(
        color: selected ? AppColor.primaryTint : AppColor.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? AppColor.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: t(
          AppFontSize.f14,
          w: selected ? FontWeight.w700 : FontWeight.w500,
          c: selected ? AppColor.primaryDark : AppColor.textFaint,
        ),
      ),
    ),
  );
}

class _UnderlineField extends StatefulWidget {
  const _UnderlineField({
    required this.label,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.decimal = false,
  });

  final String label;
  final num value;
  final String unit;
  final bool decimal;
  final void Function(num) onChanged;

  @override
  State<_UnderlineField> createState() => _UnderlineFieldState();
}

class _UnderlineFieldState extends State<_UnderlineField> {
  late final FocusNode _focus = FocusNode()..addListener(() => setState(() {}));

  /// 처음엔 비워두고, 기본값(widget.value)은 연한 placeholder로만 보여준다 —
  /// 실제로 입력한 값처럼 보이지 않게, 타이핑을 시작하는 순간 자연스럽게
  /// placeholder가 사라지게 하려는 의도.
  late final TextEditingController _c = TextEditingController();

  String _fmt(num v) {
    if (!widget.decimal) return v.toString();
    final d = v.toDouble();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: t(AppFontSize.f12, w: FontWeight.w500, c: AppColor.textFaint),
        ),
        const SizedBox(height: AppSpace.s6),
        Container(
          padding: const EdgeInsets.only(bottom: AppSpace.s8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _focus.hasFocus
                    ? AppColor.primary
                    : const Color(0xFFE3E7E9),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  focusNode: _focus,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: widget.decimal,
                  ),
                  style: t(AppFontSize.f22, w: FontWeight.w700),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: _fmt(widget.value),
                    hintStyle: t(
                      AppFontSize.f22,
                      w: FontWeight.w700,
                      c: AppColor.textGhost,
                    ),
                  ),
                  onChanged: (v) {
                    final n = widget.decimal
                        ? double.tryParse(v)
                        : int.tryParse(v);
                    if (n != null) widget.onChanged(n);
                  },
                ),
              ),
              const SizedBox(width: AppSpace.s4),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s4),
                child: Text(
                  widget.unit,
                  style: t(AppFontSize.f13, c: AppColor.textFaint),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalcTile extends StatelessWidget {
  const _CalcTile({
    required this.label,
    required this.value,
    required this.sub,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String sub;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.s12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FAF7),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t(AppFontSize.f11, w: FontWeight.w500, c: AppColor.textFaint),
        ),
        const SizedBox(height: AppSpace.s4),
        Text(
          value,
          style: t(
            AppFontSize.f20,
            w: FontWeight.w900,
            c: highlight ? AppColor.primary : AppColor.text,
          ),
        ),
        Text(sub, style: t(AppFontSize.f11, c: AppColor.textFaint)),
      ],
    ),
  );
}

// STEP 3/3 — 알림 (s.step == 4)

class _AlertStep extends StatelessWidget {
  const _AlertStep();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      horizontal: AppSpace.s20,
      top: AppSpace.s8,
      children: [
        _StepHeader(
          stepNo: 3,
          title: '목표 체중과 알림을 정해요',
          desc: '목표 체중을 입력하고, 필요한 알림만 켜세요.',
          onBack: () => s.setSub(() => s.step = 3),
        ),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('목표 체중', style: t(AppFontSize.f13, w: FontWeight.w700)),
              const SizedBox(height: AppSpace.s12),
              NumberField(
                value: s.goalWeight,
                unit: 'kg',
                fontSize: 28,
                decimal: true,
                center: true,
                min: 45,
                max: 70,
                onChanged: (v) => s.setSub(() => s.goalWeight = v.toDouble()),
              ),
              const SizedBox(height: AppSpace.s10),
              Center(
                child: Text(
                  '현재 ${s.weightKg.toStringAsFixed(1)}kg · 45~70kg 사이로 입력하세요',
                  style: t(AppFontSize.f11, c: AppColor.textGhost),
                ),
              ),
              const SizedBox(height: AppSpace.s14),
              const Divider(height: AppSpace.s1),
              const SizedBox(height: AppSpace.s14),
              RowBetween('감량 목표', s.goalDelta),
            ],
          ),
        ),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('알림 받기', style: t(AppFontSize.f13, w: FontWeight.w700)),
              const SizedBox(height: AppSpace.s5),
              Text(
                '필요한 알림만 켜세요. 나중에 변경할 수 있어요.',
                style: t(AppFontSize.f11, c: AppColor.textGhost),
              ),
              const SizedBox(height: AppSpace.s12),
              for (final a in s.onboardAlerts.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(a, style: t(AppFontSize.f13, w: FontWeight.w500)),
                      AppToggle(
                        value: s.onboardAlerts[a]!,
                        onChanged: () => s.toggleOnboardAlert(a),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        AppCard(
          color: AppColor.primaryTint,
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌱 식물이 함께 자라요',
                style: t(
                  AppFontSize.f13,
                  w: FontWeight.w700,
                  c: AppColor.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpace.s7),
              Text(
                '하루 목표를 달성하면 EXP가 쌓이고 식물이 다음 단계로 성장해요.',
                style: t(AppFontSize.f12, c: const Color(0xFF4A7A4E), h: 1.6),
              ),
            ],
          ),
        ),

        PrimaryButton(
          label: '시작하기',
          onTap: () async {
            final saved = await s.completeOnboarding();
            if (!context.mounted) return;
            toast(
              context,
              saved ? '환영해요! 오늘 첫 기록을 시작해볼까요?' : (s.authError ?? '저장하지 못했어요'),
            );
          },
        ),
      ],
    );
  }
}
