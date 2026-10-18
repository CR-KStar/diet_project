/// 사용자에게 보여줄 문구를 가진 로그인 실패. 취소는 실패가 아니라 signIn이 null을 돌려준다.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure($message)';
}
