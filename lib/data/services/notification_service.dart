import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 아침 기록 · 저녁 정리 · 주간 리포트 알림을 기기에 직접 예약하는 서비스.
///
/// 서버 없이 기기 안에서만 동작한다 — "친구 응원 알림"처럼 다른 사람의
/// 행동으로 오는 알림은 이 서비스가 다루는 범위가 아니다(그건 서버가
/// 보내는 푸시가 따로 필요하다).
///
/// 한국 사용자 전용 앱이라 시간대는 'Asia/Seoul'로 고정한다.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _morningId = 101;
  static const _eveningId = 102;
  static const _weeklyId = 103;

  static const _channel = AndroidNotificationDetails(
    'daily_reminders',
    '일일 리마인드',
    channelDescription: '아침 기록 · 저녁 정리 · 주간 리포트 알림',
    importance: Importance.defaultImportance,
  );

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  /// 알림 권한을 요청한다. 거부되면 false.
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  tz.TZDateTime _nextInstanceOfTime(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 8;
    final minute = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static const _weekdayNames = {
    '월요일': DateTime.monday,
    '화요일': DateTime.tuesday,
    '수요일': DateTime.wednesday,
    '목요일': DateTime.thursday,
    '금요일': DateTime.friday,
    '토요일': DateTime.saturday,
    '일요일': DateTime.sunday,
  };

  /// '일요일 20:00' 같은 문자열 → 다음으로 돌아오는 그 요일 · 시각.
  tz.TZDateTime _nextInstanceOfWeekly(String label) {
    final match = RegExp(r'^(\S+요일) (\d{1,2}):(\d{2})$').firstMatch(label);
    final weekday = _weekdayNames[match?.group(1)] ?? DateTime.sunday;
    final hour = int.tryParse(match?.group(2) ?? '') ?? 20;
    final minute = int.tryParse(match?.group(3) ?? '') ?? 0;

    var scheduled = _nextInstanceOfTime('$hour:$minute');
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required String hhmm,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: _nextInstanceOfTime(hhmm),
    notificationDetails: const NotificationDetails(
      android: _channel,
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  Future<void> scheduleMorning(String hhmm) => _scheduleDaily(
    id: _morningId,
    title: '오늘도 기록을 시작해볼까요? 🌱',
    body: '어제 기록을 확인하고 오늘 하루를 계획해보세요.',
    hhmm: hhmm,
  );

  Future<void> scheduleEvening(String hhmm) => _scheduleDaily(
    id: _eveningId,
    title: '오늘 하루 정리할 시간이에요',
    body: '빠진 끼니와 물 섭취를 확인해보세요.',
    hhmm: hhmm,
  );

  Future<void> scheduleWeekly(String label) => _plugin.zonedSchedule(
    id: _weeklyId,
    title: '이번 주 리포트가 준비됐어요 📊',
    body: '한 주 요약과 다음 주 추천을 확인해보세요.',
    scheduledDate: _nextInstanceOfWeekly(label),
    notificationDetails: const NotificationDetails(
      android: _channel,
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );

  Future<void> cancelMorning() => _plugin.cancel(id: _morningId);
  Future<void> cancelEvening() => _plugin.cancel(id: _eveningId);
  Future<void> cancelWeekly() => _plugin.cancel(id: _weeklyId);
}
