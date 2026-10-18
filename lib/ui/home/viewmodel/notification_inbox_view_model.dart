import 'package:flutter/foundation.dart';

/// 앱 안 알림함에 쌓이는 알림 하나.
class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.category,
    required this.icon,
    required this.title,
    required this.body,
    required this.at,
    required this.route,
  });

  final String id;

  /// 탭 분류 — '기록' · '친구' · '식물'
  final String category;
  final String icon;
  final String title;
  final String body;
  final DateTime at;

  /// 눌렀을 때 이동할 화면 id.
  final String route;
}

/// 알림 화면의 알림 목록 · 탭 · 읽음 표시를 담당한다.
///
/// 알림함에는 실제로 일어난 일만 담는다. 아직 알림을 만들어 주는 기능이 없어서 목록은
/// 비어 있고, 식단 · 물 · 운동 리마인드는 기기 알림으로 따로 간다(설정 > 알림).
/// 이전에는 예시 알림 6개가 모든 계정에 똑같이 보였는데, 실제로는 일어나지 않은 일을
/// 보여주는 것이라 없앴다.
class NotificationInboxViewModel extends ChangeNotifier {
  NotificationInboxViewModel({List<InboxNotification> items = const []})
    : items = List.of(items);

  String notifTab = '전체';

  /// 최신 알림이 먼저 오도록 쌓아 둔다.
  final List<InboxNotification> items;

  final Set<String> readNotifIds = {};

  /// 탭(전체 · 기록 · 친구 · 식물)에 맞는 알림.
  List<InboxNotification> get visibleItems => notifTab == '전체'
      ? List.unmodifiable(items)
      : items.where((n) => n.category == notifTab).toList();

  bool isUnread(InboxNotification n) => !readNotifIds.contains(n.id);

  int get unread => items.where(isUnread).length;

  void setNotifTab(String t) {
    notifTab = t;
    notifyListeners();
  }

  void markNotifRead(String id) {
    if (readNotifIds.add(id)) notifyListeners();
  }

  void readAll() {
    if (unread == 0) return;
    readNotifIds.addAll(items.map((n) => n.id));
    notifyListeners();
  }
}
