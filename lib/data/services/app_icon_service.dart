/// 오늘 식단을 기록했는지에 따라 홈 화면 앱 아이콘을 바꾼다 (빈 그릇 ↔ 채운 그릇).
/// 아이콘은 꾸밈 기능이라, 구현은 실패해도 앱 사용에 지장이 없게 조용히 넘어가야 한다.
abstract class AppIconService {
  Future<void> setFilled(bool filled);
}
