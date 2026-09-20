import 'package:diet_project/domain/models/models.dart';

/// 로그인에 성공한 계정. 인증 서비스가 알려 주는 값만 담습니다.
class AuthAccount {
  const AuthAccount({
    required this.uid,
    required this.provider,
    this.displayName,
    this.email,
    this.isNewUser = false,
  });

  /// 인증 서비스가 발급한 사용자 id — 앞으로 모든 모델의 userId가 됩니다.
  final String uid;
  final LoginProvider provider;
  final String? displayName;
  final String? email;

  /// 이 계정으로 처음 로그인했는지 (온보딩을 보여줄지 판단하는 데 씁니다).
  final bool isNewUser;
}

/// 사용자에게 보여줄 수 있는 문구를 가진 로그인 실패.
/// (사용자가 창을 닫아 취소한 경우는 실패가 아니라 signIn이 null을 돌려줍니다.)
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure($message)';
}

/// 로그인 · 로그아웃 · 계정 삭제를 맡는 서비스.
///
/// AppState는 이 인터페이스만 알고, 실제로 Firebase를 쓰는지는 main.dart에서
/// 정합니다. 그래서 Firebase 설정 전에도 앱이 그대로 돌아가고, 나중에 다른
/// 인증 서비스로 바꿔도 AppState와 화면은 손대지 않습니다.
abstract class AuthService {
  /// 지금 로그인되어 있는 계정 (없으면 null).
  AuthAccount? get currentAccount;

  /// 사용자가 창을 닫아 취소하면 null, 실패하면 [AuthFailure]를 던집니다.
  Future<AuthAccount?> signIn(LoginProvider provider);

  Future<void> signOut();

  /// 계정을 삭제합니다. 재인증이 필요하면 로그인 창이 한 번 더 뜰 수 있고,
  /// 그때 취소하면 [AuthFailure]를 던집니다.
  Future<void> deleteAccount();
}

/// Firebase 없이 화면 흐름만 확인할 때 쓰는 가짜 인증 서비스.
/// (지금 프로토타입 동작 그대로 — 항상 성공하고 uid는 고정된 내 계정입니다.)
class MockAuthService implements AuthService {
  AuthAccount? _account;

  @override
  AuthAccount? get currentAccount => _account;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async {
    return _account = AuthAccount(
      uid: User.meId,
      provider: provider,
      isNewUser: true,
    );
  }

  @override
  Future<void> signOut() async => _account = null;

  @override
  Future<void> deleteAccount() async => _account = null;
}
