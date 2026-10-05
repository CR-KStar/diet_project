// 설정 — 알림(항목별 토글 · 시간 칩) / 데이터·개인정보(공개 범위 · 동의 관리 · 위험 액션)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';

/// 알림별 관련 시간대만 노출 — 스테퍼 대신 시간 칩
const _slots = [
  (
    key: '아침 기록 알림',
    hint: '하루를 시작하며 어제 기록을 정리해요',
    from: 6,
    to: 11,
    weekly: false,
  ),
  (key: '저녁 정리 알림', hint: '빠진 끼니와 물 섭취를 확인해요', from: 18, to: 23, weekly: false),
  (key: '주간 리포트', hint: '한 주 요약과 다음 주 추천을 받아요', from: 8, to: 22, weekly: true),
];

const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

const _dangerActions = [
  (title: '기록 전체 삭제', desc: '식단·운동·체중 기록을 모두 지웁니다', account: false),
  (title: '계정 삭제', desc: '계정과 저장된 모든 정보가 즉시 삭제됩니다', account: true),
];

/// 계정 삭제 — 되돌릴 수 없어서 한 번 더 확인한 뒤 진행한다.
/// 성공하면 로그인 화면으로 바뀌므로, 완료 안내는 화면 밖 안내(AppState.takeNotice)로 전달된다.
Future<void> _confirmDeleteAccount(BuildContext context) async {
  final s = context.read<AppState>();
  final ok = await confirmDialog(
    context,
    title: '계정을 삭제할까요?',
    message:
        '계정과 저장된 모든 정보가 즉시 삭제되고 되돌릴 수 없어요.\n'
        '본인 확인을 위해 로그인 창이 한 번 더 열려요.',
    confirmLabel: '삭제',
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  final done = await s.deleteAccount();
  if (!done && context.mounted) toast(context, s.authError ?? '계정을 삭제하지 못했어요');
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      children: [
        SubHeader(emoji: '⚙️', title: '설정', onBack: () => s.go('my')),
        PillTabs(
          options: const ['알림', '데이터 · 개인정보'],
          value: s.setTab,
          onChanged: s.setSetTab,
        ),
        if (s.setTab == '알림') const _AlertsTab() else const _PrivacyTab(),
      ],
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Column(
      children: [
        _NotifyTogglesCard(s: s),
        const SizedBox(height: AppSpace.cardGap),
        _AlertTimeCard(s: s),
        const SizedBox(height: AppSpace.cardGap),
        const _DoNotDisturbCard(),
      ],
    );
  }
}

class _NotifyTogglesCard extends StatelessWidget {
  const _NotifyTogglesCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('받을 알림', style: t(AppFontSize.f14, w: FontWeight.w700)),
        const SizedBox(height: AppSpace.s5),
        Text('필요한 알림만 켜세요', style: t(AppFontSize.f11, c: AppColor.textGhost)),
        const SizedBox(height: AppSpace.s10),
        for (final k in s.notifyToggles.keys)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k, style: t(AppFontSize.f13, w: FontWeight.w500)),
              AppToggle(
                value: s.notifyToggles[k]!,
                onChanged: () => s.toggleNotify(k),
              ),
            ],
          ),
      ],
    ),
  );
}

class _AlertTimeCard extends StatelessWidget {
  const _AlertTimeCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('알림 시간', style: t(AppFontSize.f14, w: FontWeight.w700)),
        const SizedBox(height: AppSpace.s5),
        Text(
          '시간을 좌우로 넘겨 골라주세요',
          style: t(AppFontSize.f11, c: AppColor.textGhost),
        ),
        const SizedBox(height: AppSpace.s16),
        for (final slot in _slots) _AlertTimeSlot(s: s, slot: slot),
      ],
    ),
  );
}

class _AlertTimeSlot extends StatelessWidget {
  const _AlertTimeSlot({required this.s, required this.slot});

  final AppState s;
  final ({String key, String hint, int from, int to, bool weekly}) slot;

  @override
  Widget build(BuildContext context) {
    final cur = s.alertTime[slot.key]!;
    final curDay =
        RegExp(r'^(일|월|화|수|목|금|토)요일').firstMatch(cur)?.group(1) ?? '일';
    final curHour = int.parse(RegExp(r'(\d{1,2}):').firstMatch(cur)!.group(1)!);
    final hours = <int>[
      for (var h = slot.from; h <= slot.to; h += slot.weekly ? 2 : 1) h,
    ];

    void set(String day, int hour) {
      final hh = '${hour.toString().padLeft(2, '0')}:00';
      s.setAlertTime(slot.key, slot.weekly ? '$day요일 $hh' : hh);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  slot.key,
                  style: t(AppFontSize.f12, w: FontWeight.w700),
                ),
              ),
              Text(
                cur,
                style: t(
                  AppFontSize.f16,
                  w: FontWeight.w900,
                  c: AppColor.primary,
                  sp: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          Text(slot.hint, style: t(AppFontSize.f10, c: AppColor.textGhost)),
          if (slot.weekly) ...[
            const SizedBox(height: AppSpace.s11),
            Row(
              children: [
                for (final d in _weekdayLabels)
                  _WeekdayChip(
                    d: d,
                    selected: curDay == d,
                    onTap: () => set(d, curHour),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.s11),
          ScrollChips(
            options: hours
                .map((h) => '${h.toString().padLeft(2, '0')}:00')
                .toList(),
            value: '${curHour.toString().padLeft(2, '0')}:00',
            onChanged: (v) => set(curDay, int.parse(v.split(':')[0])),
          ),
        ],
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({required this.d, required this.selected, this.onTap});

  final String d;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: AppSpace.s5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s10),
          decoration: BoxDecoration(
            color: selected ? AppColor.primary : AppColor.surfaceSunken,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            d,
            style: t(
              AppFontSize.f12,
              w: selected ? FontWeight.w700 : FontWeight.w500,
              c: selected ? Colors.white : AppColor.textFaint,
            ),
          ),
        ),
      ),
    ),
  );
}

class _DoNotDisturbCard extends StatelessWidget {
  const _DoNotDisturbCard();

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('방해 금지 시간', style: t(AppFontSize.f14, w: FontWeight.w700)),
        const SizedBox(height: AppSpace.s5),
        Text(
          '이 시간에는 알림을 보내지 않아요',
          style: t(AppFontSize.f11, c: AppColor.textGhost),
        ),
        const SizedBox(height: AppSpace.s12),
        SunkenBox(
          padding: 14,
          radius: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '23:00 ~ 07:00',
                style: t(AppFontSize.f14, w: FontWeight.w700),
              ),
              Text('변경 ›', style: t(AppFontSize.f12, c: AppColor.textFaint)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PrivacyTab extends StatelessWidget {
  const _PrivacyTab();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Column(
      children: [
        _ShareScopeCard(s: s),
        const SizedBox(height: AppSpace.cardGap),
        _ConsentCard(s: s),
        const SizedBox(height: AppSpace.cardGap),
        const _DangerActionsCard(),
        const SizedBox(height: AppSpace.s8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s10),
          child: Text(
            '건강 기록은 암호화되어 저장되며, 본인 외에는 조회할 수 없습니다.',
            textAlign: TextAlign.center,
            style: t(AppFontSize.f11, c: const Color(0xFFB2B9BE), h: 1.7),
          ),
        ),
      ],
    );
  }
}

/// 공개 범위
class _ShareScopeCard extends StatelessWidget {
  const _ShareScopeCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('공개 설정', style: t(AppFontSize.f14, w: FontWeight.w700)),
            const Spacer(),
            Pill(
              s.shareScope,
              bg: s.shareScope == '비공개'
                  ? AppColor.surfaceSunken
                  : AppColor.primaryTint,
              fg: s.shareScope == '비공개'
                  ? AppColor.textFaint
                  : AppColor.primaryDark,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s12),
        SegmentedRow(
          options: const ['비공개', '친구만', '전체 공개'],
          value: s.shareScope,
          onChanged: s.setShareScope,
        ),
        const SizedBox(height: AppSpace.s11),
        Text(
          '공개 설정은 친구에게 보이는 정보의 범위에만 적용돼요.',
          style: t(AppFontSize.f11, c: AppColor.textFaint, h: 1.6),
        ),
      ],
    ),
  );
}

/// 동의 관리
class _ConsentCard extends StatelessWidget {
  const _ConsentCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('동의 관리', style: t(AppFontSize.f14, w: FontWeight.w700)),
        const SizedBox(height: AppSpace.s12),
        for (final k in s.terms.keys) _ConsentRow(s: s, k: k),
      ],
    ),
  );
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.s, required this.k});

  final AppState s;
  final String k;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s12),
    child: Row(
      children: [
        Expanded(
          child: Text(k, style: t(AppFontSize.f12, c: AppColor.textMuted)),
        ),
        GestureDetector(
          // 약관 전문은 웹뷰로 — 앱 내 전용 화면 없음
          onTap: () => toast(context, '약관 전문을 웹뷰로 엽니다'),
          child: Text('보기 ›', style: t(AppFontSize.f11, c: AppColor.textGhost)),
        ),
        const SizedBox(width: AppSpace.s10),
        AppToggle(
          value: s.terms[k]!,
          width: AppSpace.s40,
          onChanged: () {
            if (k.contains('필수')) {
              toast(context, '필수 항목은 해제할 수 없어요 · 계정 삭제로 철회됩니다');
              return;
            }
            s.toggleTerm(k);
          },
        ),
      ],
    ),
  );
}

/// 위험 액션
class _DangerActionsCard extends StatelessWidget {
  const _DangerActionsCard();

  @override
  Widget build(BuildContext context) => AppCard(
    padding: 0,
    child: Column(
      children: [
        for (final (i, a) in _dangerActions.indexed) ...[
          if (i > 0)
            const Divider(height: AppSpace.s1, indent: 18, endIndent: 18),
          _DangerActionRow(a: a),
        ],
      ],
    ),
  );
}

class _DangerActionRow extends StatelessWidget {
  const _DangerActionRow({required this.a});

  final ({String title, String desc, bool account}) a;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => a.account
        ? _confirmDeleteAccount(context)
        : toast(context, '기록 삭제를 요청했어요'),
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s18,
        vertical: AppSpace.s16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: t(
                    AppFontSize.f14,
                    w: FontWeight.w700,
                    c: AppColor.alertText,
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                Text(a.desc, style: t(AppFontSize.f11, c: AppColor.textFaint)),
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
