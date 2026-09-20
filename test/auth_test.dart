import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 정해 둔 결과만 돌려주는 가짜 인증 서비스.
class _FakeAuth implements AuthService {
  _FakeAuth({this.result, this.failure});

  final AuthAccount? result;
  final AuthFailure? failure;
  bool signedOut = false;
  bool deleted = false;

  @override
  AuthAccount? get currentAccount => result;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async {
    if (failure != null) throw failure!;
    return result;
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  Future<void> deleteAccount() async {
    if (failure != null) throw failure!;
    deleted = true;
  }
}

void main() {
  group('AppState.signIn', () {
    test('성공하면 계정 · 방식 · 닉네임이 반영된다', () async {
      final s = AppState(
        auth: _FakeAuth(
          result: const AuthAccount(
            uid: 'firebase_uid_1',
            provider: LoginProvider.apple,
            displayName: '지민',
            isNewUser: true,
          ),
        ),
      );

      expect(await s.signIn(LoginProvider.apple), isTrue);
      expect(s.account?.uid, 'firebase_uid_1');
      expect(s.provider, 'Apple');
      expect(s.nickname, '지민');
      expect(s.signingIn, isFalse);
    });

    test('이름을 못 받으면 기존 닉네임을 유지한다', () async {
      final s = AppState(
        auth: _FakeAuth(result: const AuthAccount(uid: 'u1', provider: LoginProvider.google)),
      );
      final before = s.nickname;

      expect(await s.signIn(LoginProvider.google), isTrue);
      expect(s.nickname, before);
    });

    test('사용자가 취소하면 false이고 오류 문구는 없다', () async {
      final s = AppState(auth: _FakeAuth());

      expect(await s.signIn(LoginProvider.google), isFalse);
      expect(s.account, isNull);
      expect(s.authError, isNull);
      expect(s.signingIn, isFalse);
    });

    test('실패하면 false이고 사용자용 문구가 남는다', () async {
      final s = AppState(auth: _FakeAuth(failure: const AuthFailure('로그인에 실패했어요.')));

      expect(await s.signIn(LoginProvider.google), isFalse);
      expect(s.authError, '로그인에 실패했어요.');
      expect(s.signingIn, isFalse);
    });
  });

  group('AppState.signOut · deleteAccount', () {
    test('로그아웃하면 계정이 지워지고 로그인 화면으로 돌아간다', () async {
      final fake = _FakeAuth(result: const AuthAccount(uid: 'u1', provider: LoginProvider.google));
      final s = AppState(auth: fake);
      await s.signIn(LoginProvider.google);

      await s.signOut();

      expect(fake.signedOut, isTrue);
      expect(s.account, isNull);
      expect(s.screen, 'login');
    });

    test('계정 삭제에 실패하면 false이고 문구가 남는다', () async {
      final s = AppState(auth: _FakeAuth(failure: const AuthFailure('삭제 실패')));

      expect(await s.deleteAccount(), isFalse);
      expect(s.authError, '삭제 실패');
    });
  });

  group('MockAuthService', () {
    test('항상 성공하고 uid는 고정된 내 계정이다', () async {
      final account = await MockAuthService().signIn(LoginProvider.apple);

      expect(account?.uid, User.meId);
      expect(account?.provider, LoginProvider.apple);
    });
  });
}
