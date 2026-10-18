import 'dart:async';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/auth/mock_auth_service.dart';
import 'package:diet_project/ui/onboarding/viewmodel/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _account = AuthAccount(
  uid: 'uid_1',
  provider: LoginProvider.google,
  displayName: '지민',
  isNewUser: true,
);

/// 결과를 정할 수 있고, 어떤 순서로 불렸는지 기록하는 가짜 로그인 서비스.
class _FakeAuth implements AuthService {
  AuthAccount? signInResult = _account;
  Object? signInError;
  Object? deleteError;
  Completer<void>? signInGate;
  final log = <String>[];

  @override
  AuthAccount? get currentAccount => _account;

  @override
  Future<AuthAccount?> restoreAccount() async => signInResult;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async {
    log.add('signIn');
    await signInGate?.future;
    if (signInError != null) throw signInError!;
    return signInResult;
  }

  @override
  Future<void> signOut() async => log.add('signOut');

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {
    log.add('deleteAccount:start');
    await beforeDelete?.call();
    if (deleteError != null) throw deleteError!;
    log.add('deleteAccount:done');
  }
}

void main() {
  late _FakeAuth auth;
  late AuthViewModel vm;
  late List<String> entered;

  setUp(() {
    auth = _FakeAuth();
    vm = AuthViewModel(auth: auth);
    entered = [];
  });

  Future<bool> enter(AuthAccount a) async {
    entered.add(a.uid);
    return true;
  }

  group('AuthViewModel · 로그인', () {
    test('로그인에 성공하면 계정으로 앱 상태를 채우고 true를 돌려준다', () async {
      expect(await vm.signIn(LoginProvider.google, enter: enter), isTrue);

      expect(entered, ['uid_1']);
      expect(vm.authError, isNull);
      expect(vm.signingIn, isFalse);
    });

    test('앱 상태를 채우지 못하면 로그인도 실패로 본다', () async {
      final ok = await vm.signIn(
        LoginProvider.google,
        enter: (_) async => false,
      );

      expect(ok, isFalse);
    });

    test('사용자가 취소하면 실패 문구 없이 false다', () async {
      auth.signInResult = null;

      expect(await vm.signIn(LoginProvider.google, enter: enter), isFalse);

      expect(entered, isEmpty);
      expect(vm.authError, isNull);
    });

    test('로그인 실패는 서비스가 준 문구를 그대로 보여 준다', () async {
      auth.signInError = const AuthFailure('이미 다른 방법으로 가입된 이메일이에요');

      expect(await vm.signIn(LoginProvider.google, enter: enter), isFalse);

      expect(vm.authError, '이미 다른 방법으로 가입된 이메일이에요');
    });

    test('예상치 못한 오류는 일반 안내 문구로 바꿔 보여 준다', () async {
      auth.signInError = Exception('boom');

      expect(await vm.signIn(LoginProvider.google, enter: enter), isFalse);

      expect(vm.authError, '로그인 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요.');
    });

    test('다시 시도하면 이전 실패 문구는 지워진다', () async {
      auth.signInError = const AuthFailure('실패');
      await vm.signIn(LoginProvider.google, enter: enter);

      auth.signInError = null;
      await vm.signIn(LoginProvider.google, enter: enter);

      expect(vm.authError, isNull);
    });

    test('진행 중에는 signingIn이 켜져 있고, 그동안의 중복 탭은 무시한다', () async {
      auth.signInGate = Completer<void>();
      final states = <bool>[];
      vm.addListener(() => states.add(vm.signingIn));

      final first = vm.signIn(LoginProvider.google, enter: enter);
      await Future<void>.delayed(Duration.zero);
      expect(vm.signingIn, isTrue);
      expect(await vm.signIn(LoginProvider.google, enter: enter), isFalse);

      auth.signInGate!.complete();
      expect(await first, isTrue);

      expect(auth.log.where((e) => e == 'signIn'), hasLength(1));
      expect(entered, ['uid_1']);
      expect(states, [true, false]);
    });

    test('실패해도 signingIn은 꺼진다', () async {
      auth.signInError = Exception('boom');

      await vm.signIn(LoginProvider.google, enter: enter);

      expect(vm.signingIn, isFalse);
    });
  });

  group('AuthViewModel · 계정 삭제', () {
    test('저장된 정보를 먼저 지우고 계정을 지운 뒤, 마무리 작업을 한다', () async {
      final ok = await vm.deleteAccount(
        uid: 'uid_1',
        deleteUserData: (uid) async => auth.log.add('data:$uid'),
        afterDelete: () => auth.log.add('after'),
      );

      expect(ok, isTrue);
      expect(auth.log, [
        'deleteAccount:start',
        'data:uid_1',
        'deleteAccount:done',
        'after',
      ]);
      expect(vm.deleting, isFalse);
    });

    test('로그인 정보가 없으면 정보 삭제 없이 계정만 지운다', () async {
      var dataCalls = 0;

      await vm.deleteAccount(
        uid: null,
        deleteUserData: (_) async => dataCalls++,
        afterDelete: () {},
      );

      expect(dataCalls, 0);
      expect(auth.log, contains('deleteAccount:done'));
    });

    test('정보를 지우지 못하면 실패로 알리고, 마무리 작업은 하지 않는다', () async {
      var after = 0;

      final ok = await vm.deleteAccount(
        uid: 'uid_1',
        deleteUserData: (_) async => throw Exception('network down'),
        afterDelete: () => after++,
      );

      expect(ok, isFalse);
      expect(after, 0);
      expect(vm.authError, contains('삭제하지 못했어요'));
      expect(vm.deleting, isFalse);
    });

    test('다시 로그인이 필요하면 서비스가 준 문구를 보여 준다', () async {
      auth.deleteError = const AuthFailure('보안을 위해 다시 로그인해 주세요');

      final ok = await vm.deleteAccount(
        uid: 'uid_1',
        deleteUserData: (_) async {},
        afterDelete: () {},
      );

      expect(ok, isFalse);
      expect(vm.authError, '보안을 위해 다시 로그인해 주세요');
    });

    test('삭제가 진행되는 동안의 중복 탭은 무시한다', () async {
      final gate = Completer<void>();
      final first = vm.deleteAccount(
        uid: 'uid_1',
        deleteUserData: (_) => gate.future,
        afterDelete: () {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(vm.deleting, isTrue);

      final second = await vm.deleteAccount(
        uid: 'uid_1',
        deleteUserData: (_) async {},
        afterDelete: () {},
      );
      gate.complete();
      await first;

      expect(second, isFalse);
      expect(auth.log.where((e) => e == 'deleteAccount:start'), hasLength(1));
    });
  });

  group('AuthViewModel · 기타', () {
    test('이전에 로그인한 계정을 되살리고, 로그아웃한다', () async {
      expect(await vm.restoreAccount(), _account);

      await vm.signOut();

      expect(auth.log, ['signOut']);
    });

    test('가짜 로그인(Mock)일 때만 데모로 본다', () {
      expect(vm.isDemo, isFalse);
      expect(AuthViewModel(auth: MockAuthService()).isDemo, isTrue);
    });
  });

  group('AppState 연결', () {
    test('로그인 상태 변화가 AppState 구독자에게도 전달된다', () async {
      final s = AppState(auth: auth);
      var notified = 0;
      s.addListener(() => notified++);

      await s.signIn(LoginProvider.google);

      expect(notified, greaterThanOrEqualTo(2)); // 시작 · 끝
      expect(s.account?.uid, 'uid_1');
      expect(s.signingIn, isFalse);
    });

    test('계정을 삭제하면 로그인 화면으로 돌아가고 안내 문구를 남긴다', () async {
      final s = AppState(auth: auth);
      await s.signIn(LoginProvider.google);

      expect(await s.deleteAccount(), isTrue);

      expect(s.account, isNull);
      expect(s.screen, 'login');
      expect(s.takeNotice(), contains('모두 삭제'));
    });
  });
}
