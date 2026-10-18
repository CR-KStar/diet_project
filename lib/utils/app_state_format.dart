/// 숫자 콤마 포맷 — `AppState.comma`가 이 구현을 그대로 감싸 화면에 노출한다.
abstract final class AppStateFormat {
  static String comma(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
}
