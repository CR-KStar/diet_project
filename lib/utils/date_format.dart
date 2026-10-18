/// 날짜 · 시각을 저장 · 비교에 쓰는 문자열로 바꾸는 함수들 — 앱 전체가 같은 모양을 쓰도록 한곳에 둔다.
library;

/// 'yyyy-MM-dd' — 기록의 날짜 키.
String formatDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 'yyyy-MM' — 월 단위로 기록을 불러올 때 쓰는 키.
String formatMonthKey(int year, int month) =>
    '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

/// 'HH:mm' — 기록한 시각.
String formatClockTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
