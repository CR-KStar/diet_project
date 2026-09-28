import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _account = AuthAccount(
  uid: 'uid_1',
  provider: LoginProvider.google,
  displayName: '지민',
  isNewUser: true,
);

class _FakeAuth implements AuthService {
  _FakeAuth({this.current});

  final AuthAccount? current;

  @override
  AuthAccount? get currentAccount => current;

  @override
  Future<AuthAccount?> restoreAccount() async => current;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => current;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {
    await beforeDelete?.call();
  }
}

/// 불러오기 · 저장이 실패하는 저장소.
class _BrokenRepo implements ProfileRepository {
  int saveCalls = 0;

  @override
  Future<SavedProfile?> load(String uid) async =>
      throw Exception('network down');

  @override
  Future<void> save(String uid, SavedProfile profile) async {
    saveCalls++;
    throw Exception('network down');
  }

  @override
  Future<void> delete(String uid) async => throw Exception('network down');
}

/// 저장은 되지만 삭제만 실패하는 저장소.
class _DeleteFailsRepo extends MemoryProfileRepository {
  @override
  Future<void> delete(String uid) async => throw Exception('network down');
}

SavedProfile _saved({required bool onboardingDone, String nickname = '저장된닉'}) {
  final profile = UserProfile(userId: 'uid_1')
    ..goal = '근육 증가'
    ..activity = '많음'
    ..gender = '남성'
    ..heightCm = 180
    ..weightKg = 75.5
    ..age = 31
    ..goalWeight = 72;
  final notifications = NotificationSettings(userId: 'uid_1')
    ..exerciseReminder = true;
  return SavedProfile(
    nickname: nickname,
    onboardingDone: onboardingDone,
    profile: profile,
    notifications: notifications,
    privacy: PrivacySettings(userId: 'uid_1'),
  );
}

void main() {
  group('SavedProfile 저장 형식', () {
    test('저장했다가 복원하면 같은 값이 나온다', () {
      final restored = SavedProfile.fromMap(
        _saved(onboardingDone: true).toMap(),
        userId: 'uid_1',
      );

      expect(restored.nickname, '저장된닉');
      expect(restored.onboardingDone, isTrue);
      expect(restored.profile.goalType, DietGoal.gainMuscle);
      expect(restored.profile.activityLevel, ActivityLevel.high);
      expect(restored.profile.genderType, Gender.male);
      expect(restored.profile.heightCm, 180);
      expect(restored.profile.weightKg, 75.5);
      expect(restored.profile.age, 31);
      expect(restored.profile.goalWeight, 72);
      expect(restored.notifications.exerciseReminder, isTrue);
      expect(restored.profile.userId, 'uid_1');
    });

    test('값이 비어 있거나 알 수 없어도 기본값으로 복원한다', () {
      final restored = SavedProfile.fromMap({
        'nickname': 123,
        'profile': {'goal': '없는목표', 'heightCm': '문자열'},
        'notifications': {'meal': 'yes'},
      }, userId: 'uid_1');

      expect(restored.onboardingDone, isFalse);
      expect(restored.nickname, '');
      expect(restored.profile.goalType, DietGoal.loseWeight);
      expect(restored.profile.heightCm, 168);
      expect(restored.notifications.mealReminder, isTrue);
    });
  });

  group('앱을 다시 켰을 때', () {
    test('로그인된 계정이 없으면 로그인 화면에 머문다', () async {
      final s = AppState(auth: _FakeAuth());

      expect(await s.restoreSession(), isFalse);
      expect(s.screen, 'login');
    });

    test('온보딩을 마친 계정은 로그인과 온보딩을 건너뛰고 홈으로 간다', () async {
      final repo = MemoryProfileRepository();
      await repo.save('uid_1', _saved(onboardingDone: true));
      final s = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );

      expect(await s.restoreSession(), isTrue);
      expect(s.screen, 'home');
      expect(s.nickname, '저장된닉');
      expect(s.onboardingDone, isTrue);
      expect(s.heightCm, 180);
      expect(s.goal, '근육 증가');
      expect(s.notificationSettings.exerciseReminder, isTrue);
    });

    test('저장된 정보가 없는 새 계정은 온보딩부터 시작하고 이름을 닉네임으로 쓴다', () async {
      final s = AppState(auth: _FakeAuth(current: _account));

      expect(await s.restoreSession(), isTrue);
      // 'signup'은 온보딩 1단계(계정 연결)로 가는 별칭이다.
      expect(s.screen, 'onboard');
      expect(s.step, 1);
      expect(s.nickname, '지민');
      expect(s.onboardingDone, isFalse);
    });

    test('불러오기에 실패하면 화면을 넘기지 않고 아무것도 덮어쓰지 않는다', () async {
      final repo = _BrokenRepo();
      final s = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );
      final nicknameBefore = s.nickname;

      expect(await s.restoreSession(), isFalse);
      expect(s.screen, 'login');
      expect(s.authError, isNotNull);
      expect(s.nickname, nicknameBefore);
      expect(repo.saveCalls, 0);
    });
  });

  group('온보딩 완료와 저장', () {
    test('완료하면 저장되고, 다음에 켜면 온보딩 없이 홈으로 간다', () async {
      final repo = MemoryProfileRepository();
      final first = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );
      await first.restoreSession();
      first
        ..nickname = '새닉네임'
        ..heightCm = 171;

      expect(await first.completeOnboarding(), isTrue);
      expect(first.screen, 'home');

      final second = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );
      await second.restoreSession();

      expect(second.screen, 'home');
      expect(second.nickname, '새닉네임');
      expect(second.heightCm, 171);
    });

    test('저장에 실패하면 화면과 완료 표시를 그대로 둔다', () async {
      final s = AppState(
        auth: _FakeAuth(current: _account),
        profiles: _BrokenRepo(),
      );
      await s.signIn(LoginProvider.google); // 불러오기 실패 → 로그인 상태만 유지
      s.account = _account;

      expect(await s.completeOnboarding(), isFalse);
      expect(s.onboardingDone, isFalse);
      expect(s.screen, isNot('home'));
      expect(s.authError, isNotNull);
    });

    test('단계를 넘길 때마다 진행 상황이 저장되고, 다시 켜면 그 단계에서 이어서 한다', () async {
      final repo = MemoryProfileRepository();
      final first = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );
      await first.restoreSession();
      first.nickname = '중간닉';

      await first.goToStep(2);
      await first.goToStep(3);

      final saved = await repo.load('uid_1');
      expect(saved?.onboardingStep, 3);
      expect(saved?.onboardingDone, isFalse);
      expect(saved?.nickname, '중간닉');

      final second = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );
      await second.restoreSession();

      expect(second.screen, 'onboard');
      expect(second.step, 3);
      expect(second.nickname, '중간닉');
    });

    test('단계 저장이 실패해도 화면은 넘어가고 안내 문구가 남는다', () async {
      final s = AppState(
        auth: _FakeAuth(current: _account),
        profiles: _BrokenRepo(),
      );
      await s.signIn(LoginProvider.google);
      s.account = _account;

      await s.goToStep(2);

      expect(s.step, 2);
      expect(s.takeNotice(), isNotNull);
      expect(s.takeNotice(), isNull); // 한 번 꺼내면 비워진다
    });

    test('내 정보 수정 저장도 계정에 반영된다', () async {
      final repo = MemoryProfileRepository();
      await repo.save('uid_1', _saved(onboardingDone: true));
      final s = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );
      await s.restoreSession();

      s.age = 40;
      expect(await s.saveProfile(), isTrue);

      final reloaded = await repo.load('uid_1');
      expect(reloaded?.profile.age, 40);
      expect(reloaded?.onboardingDone, isTrue);
    });
  });

  group('계정 삭제', () {
    test('저장된 정보까지 지우고 로그인 화면으로 돌아간다', () async {
      final repo = MemoryProfileRepository();
      await repo.save('uid_1', _saved(onboardingDone: true));
      final s = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );
      await s.restoreSession();

      expect(await s.deleteAccount(), isTrue);

      expect(await repo.load('uid_1'), isNull);
      expect(s.account, isNull);
      expect(s.screen, 'login');
      expect(s.nickname, '');
      expect(s.takeNotice(), contains('삭제'));
      expect(s.deleting, isFalse);
    });

    test('저장된 정보를 지우지 못하면 실패로 알리고 계정 상태를 그대로 둔다', () async {
      final repo = _DeleteFailsRepo();
      await repo.save('uid_1', _saved(onboardingDone: true));
      final s = AppState(
        auth: _FakeAuth(current: _account),
        profiles: repo,
      );
      await s.restoreSession();

      expect(await s.deleteAccount(), isFalse);

      expect(s.authError, isNotNull);
      expect(s.account, isNotNull);
      expect(s.screen, 'home');
      expect(s.deleting, isFalse);
      expect(await repo.load('uid_1'), isNotNull);
    });
  });

  test('로그아웃하면 안내 문구가 남는다', () async {
    final s = AppState(auth: _FakeAuth(current: _account));
    await s.restoreSession();

    await s.signOut();

    expect(s.takeNotice(), contains('로그아웃'));
  });

  test('로그아웃하면 이전 계정의 값이 남지 않는다', () async {
    final repo = MemoryProfileRepository();
    await repo.save('uid_1', _saved(onboardingDone: true));
    final s = AppState(
      auth: _FakeAuth(current: _account),
      profiles: repo,
    );
    await s.restoreSession();

    await s.signOut();

    expect(s.account, isNull);
    expect(s.onboardingDone, isFalse);
    expect(s.nickname, '');
    expect(s.screen, 'login');
  });
}
