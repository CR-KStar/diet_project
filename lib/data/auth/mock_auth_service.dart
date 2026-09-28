import 'package:diet_project/domain/models/models.dart';

import 'auth_service.dart';

/// Firebase 없이 화면만 확인할 때 쓰는 가짜 인증 — 항상 성공하고 uid는 고정값이다.
class MockAuthService implements AuthService {
  AuthAccount? _account;

  @override
  AuthAccount? get currentAccount => _account;

  @override
  Future<AuthAccount?> restoreAccount() async => _account;

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
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {
    await beforeDelete?.call();
    _account = null;
  }
}
