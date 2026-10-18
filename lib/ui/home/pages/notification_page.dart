// 알림 — 전체/기록/친구/식물 탭

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/home/viewmodel/notification_inbox_view_model.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';
import 'package:diet_project/ui/core/ui/icons/app_icons.dart';

/// 알림이 온 시각을 "방금 · n분 전 · n시간 전 · 어제 · n일 전"으로 보여준다.
String _timeLabel(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 2) return '어제';
  return '${diff.inDays}일 전';
}

Color _tintOf(String category) => switch (category) {
  '식물' => const Color(0xFFF2F8F2),
  '친구' => const Color(0xFFFFF3EF),
  _ => AppColor.primaryTint,
};

class NotifScreen extends StatelessWidget {
  const NotifScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificationInboxViewModel>();
    final s = context.watch<AppState>();
    final list = inbox.visibleItems;

    return ScreenScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SubHeader(
                icon: AppIcons.notifications,
                title: '알림',
                onBack: () => s.go('home'),
              ),
            ),
            if (inbox.unread > 0)
              GestureDetector(
                onTap: () {
                  inbox.readAll();
                  toast(context, '모든 알림을 읽음으로 표시했어요');
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpace.s4),
                  child: Text(
                    '모두 읽음',
                    style: t(
                      AppFontSize.f12,
                      w: FontWeight.w700,
                      c: AppColor.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        FilterTabs(
          options: const ['전체', '기록', '친구', '식물'],
          value: inbox.notifTab,
          onChanged: inbox.setNotifTab,
        ),
        if (list.isEmpty)
          const _EmptyInbox()
        else
          for (final n in list)
            _NotifCard(
              n: n,
              unread: inbox.isUnread(n),
              time: _timeLabel(n.at, s.today),
            ),
      ],
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n, required this.unread, required this.time});

  final InboxNotification n;
  final bool unread;
  final String time;

  @override
  Widget build(BuildContext context) {
    final inbox = context.read<NotificationInboxViewModel>();
    final s = context.read<AppState>();
    return Container(
      padding: const EdgeInsets.all(AppSpace.s15),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFFBFDF9) : AppColor.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.card,
        border: Border(
          left: BorderSide(
            color: unread ? AppColor.primary : Colors.transparent,
            width: AppSpace.s3,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          inbox.markNotifRead(n.id);
          s.go(n.route);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile.icon(
              n.icon,
              size: 40,
              radius: 14,
              bg: _tintOf(n.category),
              iconSize: 22,
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          n.title,
                          style: t(AppFontSize.f13, w: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s6),
                      if (unread)
                        Container(
                          width: AppSpace.s6,
                          height: AppSpace.s6,
                          decoration: const BoxDecoration(
                            color: AppColor.alert,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    n.body,
                    style: t(AppFontSize.f12, c: AppColor.textMuted, h: 1.55),
                  ),
                  const SizedBox(height: AppSpace.s5),
                  Text(time, style: t(AppFontSize.f10, c: AppColor.textGhost)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 알림이 하나도 없을 때 — 리마인드는 기기 알림으로 간다는 것과 설정으로 가는 길을 알려준다.
class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return AppCard(
      padding: 24,
      child: Column(
        children: [
          const Icon(AppIcons.notifications, size: 34, color: AppColor.primary),
          const SizedBox(height: AppSpace.s10),
          Text('아직 알림이 없어요', style: t(AppFontSize.f14, w: FontWeight.w700)),
          const SizedBox(height: AppSpace.s6),
          Text(
            '식단 · 물 · 운동 리마인드는 기기 알림으로 보내드려요.\n'
            '설정에서 원하는 알림만 켜고 끌 수 있어요.',
            textAlign: TextAlign.center,
            style: t(AppFontSize.f12, c: AppColor.textMuted, h: 1.55),
          ),
          const SizedBox(height: AppSpace.s14),
          SmallButton(label: '알림 설정', onTap: () => s.go('alerts')),
        ],
      ),
    );
  }
}
