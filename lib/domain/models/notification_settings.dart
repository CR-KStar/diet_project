/// 사용자 알림 설정
class NotificationSettings {
  NotificationSettings({
    required this.userId,
    this.mealReminder = true,
    this.waterReminder = true,
    this.exerciseReminder = false,
    this.friendActivity = true,
    this.morningAlertTime = '08:00',
    this.eveningAlertTime = '21:00',
    this.weeklyReportTime = '일요일 20:00',
  });

  /// 이 알림 설정의 주인 — User.id
  final String userId;
  bool mealReminder;
  bool waterReminder;
  bool exerciseReminder;
  bool friendActivity;

  /// 설정 화면의 "알림 시간" 3종 — 아침 기록 · 저녁 정리 · 주간 리포트.
  String morningAlertTime;
  String eveningAlertTime;
  String weeklyReportTime;
}
