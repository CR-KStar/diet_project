import 'package:flutter/foundation.dart';

/// 알림 화면의 탭과 읽음 표시를 담당한다.
///
/// 기기 알림 예약(식단 미기록 알림 등)은 설정 쪽 일이고, 여기서는 앱 안 알림함만 다룬다.
class NotificationInboxViewModel extends ChangeNotifier {
  String notifTab = '전체';

  static const _unreadNotifIds = [
    '저녁 식단을 기록하지 않았어요',
    '식물이 물을 기다려요',
    '지현님이 응원을 보냈어요',
  ];

  final Set<String> readNotifIds = {};

  int get unread =>
      _unreadNotifIds.where((id) => !readNotifIds.contains(id)).length;

  void setNotifTab(String t) {
    notifTab = t;
    notifyListeners();
  }

  void markNotifRead(String id) {
    if (readNotifIds.add(id)) notifyListeners();
  }

  void readAll() {
    readNotifIds.addAll(_unreadNotifIds);
    notifyListeners();
  }
}
