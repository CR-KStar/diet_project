/// 소셜 로그인 방식. 화면 문구는 label로 읽습니다.
enum LoginProvider {
  google('Google'),
  apple('Apple');

  const LoginProvider(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
