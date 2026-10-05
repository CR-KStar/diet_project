import '../../app_state.dart';

/// 로그인 · 로그아웃 · 계정 삭제를 맡는 서비스.
/// AppState는 이 인터페이스만 알고, 실제 구현(Firebase or Mock)은 main.dart에서 정한다.
abstract class AuthService {
  AuthAccount? get currentAccount;

  Future<AuthAccount?> restoreAccount();

  /// 취소하면 null, 실패하면 [AuthFailure]를 던진다.
  Future<AuthAccount?> signIn(LoginProvider provider);

  Future<void> signOut();

  /// [beforeDelete]는 본인 확인 직후, 계정 삭제 직전에 실행된다 (데이터 삭제용).
  Future<void> deleteAccount({Future<void> Function()? beforeDelete});
}

/// 사용자에게 보여줄 문구를 가진 로그인 실패. 취소는 실패가 아니라 signIn이 null을 돌려준다.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure($message)';
}
