/// 앱 전체에서 쓰는 고정 설정값 — 흩어져 있던 주소 · 이름을 한곳에 모았다.
abstract final class AppConfig {
  /// 개인정보 처리방침 · 약관 · 건강 정보 출처 문서를 공개한 사이트 (GitHub Pages).
  static const siteBaseUrl = 'https://cr-kstar.github.io/diet_project';

  /// 한국 사용자 전용 앱이라 기기 알림 시간대는 서울로 고정한다.
  static const timeZone = 'Asia/Seoul';

  /// 앱 아이콘을 바꾸는 플랫폼 채널 이름 (iOS · 안드로이드 코드와 같아야 한다).
  static const appIconChannel = 'kr.chaerin.dietapp/app_icon';

  /// Cloud Functions 함수 이름 (functions/src/index.ts의 이름과 같아야 한다).
  static const analyzeMealPhotoFunction = 'analyzeMealPhoto';
  static const recommendMealsFunction = 'recommendMeals';
}
