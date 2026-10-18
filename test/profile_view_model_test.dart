import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/repositories/profile_repository.dart';
import 'package:diet_project/ui/onboarding/viewmodel/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _account = AuthAccount(
  uid: 'uid_1',
  provider: LoginProvider.google,
  displayName: '지민',
  isNewUser: true,
);

/// 저장 횟수를 세고, 불러오기 · 저장을 실패시킬 수 있는 저장소.
class _Repo extends MemoryProfileRepository {
  bool failLoad = false;
  bool failSave = false;
  int saves = 0;

  @override
  Future<SavedProfile?> load(String uid) async {
    if (failLoad) throw Exception('network down');
    return super.load(uid);
  }

  @override
  Future<void> save(String uid, SavedProfile profile) async {
    saves++;
    if (failSave) throw Exception('network down');
    return super.save(uid, profile);
  }
}

void main() {
  late _Repo repo;
  late ProfileViewModel vm;

  setUp(() {
    repo = _Repo();
    vm = ProfileViewModel(profiles: repo);
  });

  Future<void> signedIn() async {
    await vm.loadFor(_account, skipOnboardingForNewAccount: false);
  }

  group('ProfileViewModel · 불러오기', () {
    test('처음 가입한 계정은 계정 이름을 닉네임으로 쓰고 온보딩을 1단계부터 시작한다', () async {
      await signedIn();

      expect(vm.uid, 'uid_1');
      expect(vm.nickname, '지민');
      expect(vm.onboardingDone, isFalse);
      expect(vm.resumeStep, 1);
    });

    test('계정 이름이 비어 있으면 기본 닉네임을 그대로 둔다', () async {
      await vm.loadFor(
        const AuthAccount(
          uid: 'u',
          provider: LoginProvider.google,
          displayName: '  ',
          isNewUser: true,
        ),
        skipOnboardingForNewAccount: false,
      );

      expect(vm.nickname, '새싹');
    });

    test('웹 체험판은 온보딩 없이 바로 끝난 것으로 본다', () async {
      await vm.loadFor(_account, skipOnboardingForNewAccount: true);

      expect(vm.onboardingDone, isTrue);
    });

    test('저장된 프로필이 있으면 모든 값을 그대로 되살린다', () async {
      vm
        ..nickname = '저장닉'
        ..onboardingDone = true
        ..step = 3
        ..profile.heightCm = 171
        ..notificationSettings.exerciseReminder = true
        ..notificationSettings.morningAlertTime = '07:30'
        ..privacySettings.shareWeightTrend = true;
      vm.terms['(필수) 민감 건강정보 수집·이용 동의'] = true;
      vm.uid = 'uid_1';
      await vm.persist();

      final again = ProfileViewModel(profiles: repo);
      await again.loadFor(_account, skipOnboardingForNewAccount: false);

      expect(again.nickname, '저장닉');
      expect(again.onboardingDone, isTrue);
      expect(again.resumeStep, 3);
      expect(again.profile.heightCm, 171);
      expect(again.notificationSettings.exerciseReminder, isTrue);
      expect(again.notificationSettings.morningAlertTime, '07:30');
      expect(again.privacySettings.shareWeightTrend, isTrue);
      expect(again.terms['(필수) 민감 건강정보 수집·이용 동의'], isTrue);
    });

    test('불러오지 못하면 예외를 던지고 아무것도 바꾸지 않는다', () async {
      repo.failLoad = true;

      await expectLater(signedIn(), throwsException);

      expect(vm.uid, isNull);
      expect(vm.nickname, '새싹');
    });
  });

  group('ProfileViewModel · 저장', () {
    test('로그인 전에는 저장할 곳이 없어서 저장하지 않고 성공으로 본다', () async {
      expect(await vm.persist(), isTrue);
      expect(repo.saves, 0);
    });

    test('로그인하면 저장하고, 실패하면 이유를 남긴다', () async {
      await signedIn();
      expect(await vm.persist(), isTrue);
      expect(repo.saves, 1);

      repo.failSave = true;
      expect(await vm.persist(), isFalse);
      expect(vm.saveError, contains('저장하지 못했어요'));
    });

    test('온보딩 단계는 1~4 안으로 저장한다', () async {
      await signedIn();
      vm.step = 9;
      await vm.persist();

      final saved = await repo.load('uid_1');
      expect(saved!.onboardingStep, 4);
    });

    test('백그라운드 저장이 실패하면 안내 문구를 알린다', () async {
      await signedIn();
      repo.failSave = true;
      String? notice;
      vm.onSyncFailed = (m) => notice = m;

      await vm.persistAndReport();

      expect(notice, vm.saveError);
      expect(notice, isNotNull);
    });

    test('설정을 바꾸면 알리고 저장한다', () async {
      await signedIn();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.toggleNotify('운동 리마인드');
      vm.setAlertTime('아침 기록 알림', '06:00');
      vm.setShareScope('비공개');
      vm.toggleFriendVisibility('체중 변화');
      vm.toggleGardenPublic();
      await Future<void>.delayed(Duration.zero);

      expect(notified, 5);
      expect(repo.saves, 5);
      final saved = (await repo.load('uid_1'))!;
      expect(saved.notifications.exerciseReminder, isTrue);
      expect(saved.notifications.morningAlertTime, '06:00');
      expect(saved.privacy.scope, ShareScope.private);
      expect(saved.privacy.shareWeightTrend, isTrue);
      expect(saved.privacy.shareGarden, isFalse);
    });

    test('온보딩에서 알림을 켜고 끄는 것은 단계를 넘길 때까지 저장하지 않는다', () async {
      await signedIn();

      vm.toggleOnboardAlert('운동 리마인드');
      await Future<void>.delayed(Duration.zero);

      expect(vm.onboardAlerts['운동 리마인드'], isTrue);
      expect(repo.saves, 0);
    });

    test('체중을 기록하면 프로필의 현재 체중도 바뀌고 저장된다', () async {
      await signedIn();

      vm.onWeightLogged(63.5);
      await Future<void>.delayed(Duration.zero);

      expect(vm.profile.weightKg, 63.5);
      expect((await repo.load('uid_1'))!.profile.weightKg, 63.5);
    });
  });

  group('ProfileViewModel · 약관', () {
    test('필수 약관을 모두 동의해야 requiredTermsOk다', () {
      expect(vm.requiredTermsOk, isFalse); // 민감 건강정보 동의가 꺼져 있다

      vm.terms['(필수) 민감 건강정보 수집·이용 동의'] = true;

      expect(vm.requiredTermsOk, isTrue);
    });

    test('전체 동의는 하나라도 꺼져 있으면 모두 켜고, 모두 켜져 있으면 모두 끈다', () {
      vm.toggleAllTerms();
      expect(vm.terms.values.every((v) => v), isTrue);

      vm.toggleAllTerms();
      expect(vm.terms.values.every((v) => !v), isTrue);
    });

    test('약관 하나를 누르면 그 항목만 바뀐다', () {
      vm.toggleTerm('(선택) 마케팅 정보 수신');

      expect(vm.terms['(선택) 마케팅 정보 수신'], isTrue);
      expect(vm.terms['(필수) 서비스 이용약관'], isTrue);
    });
  });

  group('ProfileViewModel · 공개 범위', () {
    test('공개 범위 문구와 요약', () {
      expect(vm.shareScope, '친구만');
      vm.privacySettings
        ..shareGarden = false
        ..shareStreak = false
        ..shareMealPhotos = false
        ..shareChallengeRank = false;
      expect(vm.friendVisibilitySummary, '친구만 · 공개 항목 없음');

      vm.privacySettings.shareStreak = true;
      expect(vm.friendVisibilitySummary, '친구만 · 공개 항목 1개 — 연속 기록 · 스트릭');
    });

    test('"비공개"만 비공개로 바뀌고, 그 외 값은 친구 공개다', () {
      vm.shareScope = '비공개';
      expect(vm.privacySettings.scope, ShareScope.private);

      vm.shareScope = '아무거나';
      expect(vm.privacySettings.scope, ShareScope.friends);
    });
  });

  group('ProfileViewModel · 비우기 · 삭제', () {
    test('reset: 개인 정보를 처음 상태로 되돌리고 저장 대상을 끊는다', () async {
      await signedIn();
      vm
        ..nickname = '저장닉'
        ..onboardingDone = true
        ..step = 3
        ..profile.heightCm = 171
        ..notificationSettings.mealReminder = false;

      vm.reset();

      expect(vm.uid, isNull);
      expect(vm.nickname, '');
      expect(vm.onboardingDone, isFalse);
      expect(vm.step, 1);
      expect(vm.resumeStep, 1);
      expect(vm.profile.heightCm, UserProfile(userId: User.meId).heightCm);
      expect(vm.notificationSettings.mealReminder, isTrue);
      expect(await vm.persist(), isTrue);
      expect(repo.saves, 0);
    });

    test('deleteProfile: 저장된 프로필을 지운다', () async {
      await signedIn();
      await vm.persist();

      await vm.deleteProfile('uid_1');

      expect(await repo.load('uid_1'), isNull);
    });
  });

  group('AppState 연결', () {
    test('알림을 바꾸면 AppState 구독자에게도 전달된다', () {
      final s = AppState();
      var notified = 0;
      s.addListener(() => notified++);

      s.toggleNotify('운동 리마인드');

      expect(notified, greaterThan(0));
      expect(s.notifyToggles['운동 리마인드'], isTrue);
    });

    test('account를 바꾸면 내 정보 저장 대상도 함께 바뀐다', () async {
      final s = AppState(profiles: repo);

      s.account = _account;
      await s.saveProfile();
      expect(repo.saves, 1);

      s.account = null;
      await s.saveProfile();
      expect(repo.saves, 1);
    });
  });
}
