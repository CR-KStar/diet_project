// 설정 — 알림(항목별 토글 · 시간 칩) / 데이터·개인정보(공개 범위 · 동의 관리 · 위험 액션)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(children: [
      SubHeader(emoji: '⚙️', title: '설정', onBack: () => s.go('my')),
      PillTabs(
        options: const ['알림', '데이터 · 개인정보'],
        value: s.setTab,
        onChanged: s.setSetTab,
      ),
      if (s.setTab == '알림') const _AlertsTab() else const _PrivacyTab(),
    ]);
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  /// 알림별 관련 시간대만 노출 — 스테퍼 대신 시간 칩
  static const _slots = [
    (key: '아침 기록 알림', hint: '하루를 시작하며 어제 기록을 정리해요', from: 6, to: 11, weekly: false),
    (key: '저녁 정리 알림', hint: '빠진 끼니와 물 섭취를 확인해요', from: 18, to: 23, weekly: false),
    (key: '주간 리포트', hint: '한 주 요약과 다음 주 추천을 받아요', from: 8, to: 22, weekly: true),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Column(children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('받을 알림', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('필요한 알림만 켜세요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 10),
          for (final k in s.notifyToggles.keys)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(k, style: t(13, w: FontWeight.w500)),
              AppToggle(
                value: s.notifyToggles[k]!,
                onChanged: () => s.toggleNotify(k),
              ),
            ]),
        ]),
      ),
      const SizedBox(height: AppSpace.cardGap),

      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('알림 시간', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('시간을 좌우로 넘겨 골라주세요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 16),
          for (final slot in _slots)
                () {
              final cur = s.alertTime[slot.key]!;
              final curDay = RegExp(r'^(일|월|화|수|목|금|토)요일')
                  .firstMatch(cur)
                  ?.group(1) ??
                  '일';
              final curHour =
              int.parse(RegExp(r'(\d{1,2}):').firstMatch(cur)!.group(1)!);
              final hours = <int>[
                for (var h = slot.from; h <= slot.to; h += slot.weekly ? 2 : 1) h,
              ];

              void set(String day, int hour) {
                final hh = '${hour.toString().padLeft(2, '0')}:00';
                s.setAlertTime(slot.key, slot.weekly ? '$day요일 $hh' : hh);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Expanded(child: Text(slot.key, style: t(12, w: FontWeight.w700))),
                    Text(cur, style: t(16, w: FontWeight.w900, c: AppColor.primary, sp: -0.3)),
                  ]),
                  const SizedBox(height: 3),
                  Text(slot.hint, style: t(10, c: AppColor.textGhost)),
                  if (slot.weekly) ...[
                    const SizedBox(height: 11),
                    Row(children: [
                      for (final d in ['일', '월', '화', '수', '목', '금', '토'])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: GestureDetector(
                              onTap: () => set(d, curHour),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: curDay == d
                                      ? AppColor.primary
                                      : AppColor.surfaceSunken,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(d,
                                    style: t(12,
                                        w: curDay == d ? FontWeight.w700 : FontWeight.w500,
                                        c: curDay == d ? Colors.white : AppColor.textFaint)),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 11),
                  ScrollChips(
                    options: hours
                        .map((h) => '${h.toString().padLeft(2, '0')}:00')
                        .toList(),
                    value: '${curHour.toString().padLeft(2, '0')}:00',
                    onChanged: (v) => set(curDay, int.parse(v.split(':')[0])),
                  ),
                ]),
              );
            }(),
        ]),
      ),
      const SizedBox(height: AppSpace.cardGap),

      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('방해 금지 시간', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('이 시간에는 알림을 보내지 않아요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 12),
          SunkenBox(
            padding: 14,
            radius: 16,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('23:00 ~ 07:00', style: t(14, w: FontWeight.w700)),
              Text('변경 ›', style: t(12, c: AppColor.textFaint)),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class _PrivacyTab extends StatelessWidget {
  const _PrivacyTab();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Column(children: [
      // 공개 범위
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('공개 설정', style: t(14, w: FontWeight.w700)),
            const Spacer(),
            Pill(s.shareScope,
                bg: s.shareScope == '비공개' ? AppColor.surfaceSunken : AppColor.primaryTint,
                fg: s.shareScope == '비공개' ? AppColor.textFaint : AppColor.primaryDark),
          ]),
          const SizedBox(height: 12),
          SegmentedRow(
            options: const ['비공개', '친구만', '전체 공개'],
            value: s.shareScope,
            onChanged: s.setShareScope,
          ),
          const SizedBox(height: 11),
          Text('눈바디 사진과 첨부 이미지는 공개 설정과 무관하게 항상 본인만 볼 수 있어요.',
              style: t(11, c: AppColor.textFaint, h: 1.6)),
        ]),
      ),
      const SizedBox(height: AppSpace.cardGap),

      // 동의 관리
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('동의 관리', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final k in s.terms.keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(child: Text(k, style: t(12, c: AppColor.textMuted))),
                GestureDetector(
                  // 약관 전문은 웹뷰로 — 앱 내 전용 화면 없음
                  onTap: () => toast(context, '약관 전문을 웹뷰로 엽니다'),
                  child: Text('보기 ›', style: t(11, c: AppColor.textGhost)),
                ),
                const SizedBox(width: 10),
                AppToggle(
                  value: s.terms[k]!,
                  width: 40,
                  onChanged: () {
                    if (k.contains('필수')) {
                      toast(context, '필수 항목은 해제할 수 없어요 · 계정 삭제로 철회됩니다');
                      return;
                    }
                    s.toggleTerm(k);
                  },
                ),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: AppSpace.cardGap),

      // 위험 액션
      AppCard(
        padding: 0,
        child: Column(children: [
          for (final (i, a) in const [
            (title: '기록 전체 삭제', desc: '식단·운동·체중 기록을 모두 지웁니다', msg: '기록 삭제를 요청했어요'),
            (title: '계정 삭제 요청', desc: '30일 후 모든 데이터가 영구 삭제됩니다', msg: '계정 삭제를 요청했어요'),
          ].indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
            GestureDetector(
              onTap: () => toast(context, a.msg),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.title,
                          style: t(14, w: FontWeight.w700, c: AppColor.alertText)),
                      const SizedBox(height: 3),
                      Text(a.desc, style: t(11, c: AppColor.textFaint)),
                    ]),
                  ),
                  const Text('›', style: TextStyle(fontSize: 16, color: AppColor.iconGhost)),
                ]),
              ),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text('건강 기록은 암호화되어 저장되며, 본인 외에는 조회할 수 없습니다.',
            textAlign: TextAlign.center,
            style: t(11, c: const Color(0xFFB2B9BE), h: 1.7)),
      ),
    ]);
  }
}
