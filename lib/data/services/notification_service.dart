/// 아침 기록 · 저녁 정리 · 주간 리포트 알림을 기기에 예약하는 서비스.
/// 화면 쪽은 이 인터페이스만 알고, 실제 예약 방법(기기 알림 플러그인)은 구현이 안다.
abstract class NotificationService {
  Future<void> init();

  /// 알림 권한을 요청한다. 거부되면 false.
  Future<bool> requestPermission();

  /// [hhmm]은 '08:00' 같은 시각.
  Future<void> scheduleMorning(String hhmm);
  Future<void> scheduleEvening(String hhmm);

  /// [label]은 '일요일 20:00' 같은 요일 · 시각.
  Future<void> scheduleWeekly(String label);

  Future<void> cancelMorning();
  Future<void> cancelEvening();
  Future<void> cancelWeekly();
}
