// 알림 — 전체/기록/친구/식물 탭

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

class NotifScreen extends StatelessWidget {
  const NotifScreen({super.key});

  static const _items = [
    (cat: '기록', icon: '🍽️', tint: AppColor.primaryTint, title: '저녁 식단을 기록하지 않았어요', body: '오늘 남은 칼로리는 350kcal예요. 지금 기록하면 미션도 함께 완료돼요.', time: '10분 전', unread: true, to: 'capture'),
    (cat: '식물', icon: '🌱', tint: Color(0xFFF2F8F2), title: '식물이 물을 기다려요', body: '오늘 물 주기 3/3을 완료하면 +20 EXP를 받아요.', time: '1시간 전', unread: true, to: 'plant'),
    (cat: '친구', icon: '👏', tint: Color(0xFFFFF3EF), title: '지현님이 응원을 보냈어요', body: '“오늘도 화이팅! 같이 챌린지 끝까지 가요.”', time: '3시간 전', unread: true, to: 'friends'),
    (cat: '기록', icon: '💧', tint: Color(0xFFF0F5FF), title: '물 마실 시간이에요', body: '목표까지 550ml 남았어요.', time: '5시간 전', unread: false, to: 'water'),
    (cat: '친구', icon: '🏆', tint: Color(0xFFFFF9E9), title: '물 마시기 챌린지 3일 남음', body: '현재 1위예요. 마지막까지 유지해 보세요.', time: '어제', unread: false, to: 'challenge'),
    (cat: '기록', icon: '📊', tint: AppColor.surfaceSunken, title: '주간 리포트가 준비됐어요', body: '지난주보다 평균 120kcal 줄었어요.', time: '어제', unread: false, to: 'report'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.notifTab == '전체'
        ? _items
        : _items.where((n) => n.cat == s.notifTab).toList();

    return ScreenScroll(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SubHeader(emoji: '🔔', title: '알림', onBack: () => s.go('home'))),
          GestureDetector(
            onTap: () {
              s.readAll();
              toast(context, '모든 알림을 읽음으로 표시했어요');
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('모두 읽음', style: t(12, w: FontWeight.w700, c: AppColor.primary)),
            ),
          ),
        ],
      ),
      FilterTabs(
        options: const ['전체', '기록', '친구', '식물'],
        value: s.notifTab,
        onChanged: s.setNotifTab,
      ),
      for (final n in list)
            () {
          final unread = n.unread && !s.readNotifIds.contains(n.title);
          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: unread ? const Color(0xFFFBFDF9) : AppColor.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadow.card,
              border: Border(
                left: BorderSide(
                  color: unread ? AppColor.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                s.markNotifRead(n.title);
                s.go(n.to);
              },
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconTile(n.icon, size: 40, radius: 14, bg: n.tint, fontSize: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(n.title, style: t(13, w: FontWeight.w700))),
                      const SizedBox(width: 6),
                      if (unread)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColor.alert, shape: BoxShape.circle),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(n.body, style: t(12, c: AppColor.textMuted, h: 1.55)),
                    const SizedBox(height: 5),
                    Text(n.time, style: t(10, c: AppColor.textGhost)),
                  ]),
                ),
              ]),
            ),
          );
        }(),
      Center(
        child: Text('30일 이전 알림은 자동으로 삭제돼요',
            style: t(11, c: const Color(0xFFB2B9BE))),
      ),
    ]);
  }
}
