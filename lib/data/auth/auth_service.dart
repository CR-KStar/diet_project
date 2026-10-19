import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/data/auth/auth_failure.dart';

/// 로그인 · 로그아웃 · 계정 삭제를 맡는 서비스.
/// AppState는 이 인터페이스만 알고, 실제 구현(Firebase or Mock)은 app_composition.dart에서 정한다.
abstract class AuthService {
  /// 서버 없이 도는 체험용 로그인인지 (저장되지 않고, 예시 데이터가 보인다).
  bool get isDemo;

  AuthAccount? get currentAccount;

  Future<AuthAccount?> restoreAccount();

  /// 취소하면 null, 실패하면 [AuthFailure]를 던진다.
  Future<AuthAccount?> signIn(LoginProvider provider);

  Future<void> signOut();

  /// [beforeDelete]는 본인 확인 직후, 계정 삭제 직전에 실행된다 (데이터 삭제용).
  Future<void> deleteAccount({Future<void> Function()? beforeDelete});
}
