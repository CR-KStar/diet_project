import 'package:diet_project/app_composition.dart';
import 'package:diet_project/app_providers.dart';
import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/impl/memory_challenge_repository.dart';
import 'package:diet_project/ui/social/viewmodel/challenge_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Challenge _challenge(String id, {required String creator, List<String>? who}) =>
    Challenge(
      id: id,
      title: '챌린지 $id',
      description: '설명',
      icon: '💧',
      category: '데일리',
      period: '오늘 하루',
      creatorId: creator,
      participantIds: who ?? [creator],
      metricType: ChallengeType.water,
      targetValue: 2000,
    );

/// leave · delete를 실패시킬 수 있는 챌린지 저장소.
class _Repo extends MemoryChallengeRepository {
  _Repo(List<Challenge> seed) : super(seed: seed);

  bool fail = false;

  @override
  Future<void> leave(String challengeId, String userId) async {
    if (fail) throw Exception('network down');
    return super.leave(challengeId, userId);
  }

  @override
  Future<void> delete(String challengeId) async {
    if (fail) throw Exception('network down');
    return super.delete(challengeId);
  }
}

const _meAccount = AuthAccount(
  uid: 'me',
  provider: LoginProvider.google,
  displayName: '채린',
);

class _FakeAuth implements AuthService {
  @override
  bool get isDemo => false;

  @override
  AuthAccount? get currentAccount => _meAccount;

  @override
  Future<AuthAccount?> restoreAccount() async => _meAccount;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => _meAccount;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('ChallengeViewModel · 나가기 · 삭제', () {
    late _Repo repo;
    late ChallengeViewModel vm;
    final messages = <String>[];

    setUp(() async {
      messages.clear();
      repo = _Repo([
        _challenge('mine', creator: 'me', who: ['me', 'bob']),
        _challenge('theirs', creator: 'bob', who: ['bob', 'me']),
        _challenge('others', creator: 'bob', who: ['bob']),
      ]);
      vm = ChallengeViewModel(challengeRepo: repo)..onSyncFailed = messages.add;
      await vm.loadForUid('me');
    });

    test('남이 만든 챌린지에서 나가면 내 목록에서 빠지고, 챌린지는 남는다', () async {
      expect(vm.myChallenges.map((c) => c.id), containsAll(['mine', 'theirs']));

      expect(await vm.leaveChallenge('theirs'), isTrue);

      expect(vm.myChallenges.map((c) => c.id), ['mine']);
      final stored = (await repo.loadAll()).firstWhere((c) => c.id == 'theirs');
      expect(stored.participantIds, ['bob']);
      // 나간 챌린지는 다시 참여할 수 있는 목록에 나온다.
      expect(vm.joinableChallenges.map((c) => c.id), contains('theirs'));
    });

    test('나가면 내 진행 기록이 지워진다', () async {
      await repo.reportProgress('theirs', 'me', 500);

      await vm.leaveChallenge('theirs');

      expect(await repo.loadProgress('theirs', ['me']), {'me': 0});
    });

    test('내가 만든 챌린지는 나가기가 아니라 삭제로만 지운다', () async {
      expect(await vm.leaveChallenge('mine'), isFalse);
      expect(vm.myChallenges.map((c) => c.id), contains('mine'));
    });

    test('참여하지 않은 챌린지나 없는 챌린지는 나갈 수 없다', () async {
      expect(await vm.leaveChallenge('others'), isFalse);
      expect(await vm.leaveChallenge('none'), isFalse);
    });

    test('내가 만든 챌린지를 삭제하면 모든 참여자에게서 사라진다', () async {
      expect(await vm.deleteChallenge('mine'), isTrue);

      expect(vm.challenges.map((c) => c.id), isNot(contains('mine')));
      expect((await repo.loadAll()).map((c) => c.id), isNot(contains('mine')));
    });

    test('남이 만든 챌린지는 삭제할 수 없다', () async {
      expect(await vm.deleteChallenge('theirs'), isFalse);
      expect((await repo.loadAll()).map((c) => c.id), contains('theirs'));
    });

    test('서버에서 나가지 못하면 원래대로 되돌리고 알린다', () async {
      repo.fail = true;

      expect(await vm.leaveChallenge('theirs'), isFalse);

      expect(vm.myChallenges.map((c) => c.id), contains('theirs'));
      expect(messages.single, contains('나가지 못했어요'));
    });

    test('서버에서 삭제하지 못하면 같은 자리에 되돌리고 알린다', () async {
      repo.fail = true;
      final before = vm.challenges.map((c) => c.id).toList();

      expect(await vm.deleteChallenge('mine'), isFalse);

      expect(vm.challenges.map((c) => c.id), before);
      expect(messages.single, contains('삭제하지 못했어요'));
    });
  });

  group('챌린지 탭 화면', () {
    Future<AppState> pumpChallenges(WidgetTester tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final state = AppState(
        dependencies: memoryDependencies(
          auth: _FakeAuth(),
          challengeRepo: _Repo([
            _challenge('mine', creator: 'me', who: ['me', 'bob']),
            _challenge('theirs', creator: 'bob', who: ['bob', 'me']),
          ]),
          now: () => DateTime(2026, 10, 18),
        ),
      );
      await state.restoreSession();
      state.navigationViewModel.go('friends');
      state.navigationViewModel.setFriendTab('챌린지');
      await tester.pumpWidget(
        AppProviders(
          state: state,
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      return state;
    }

    testWidgets('내가 만든 건 "삭제", 남이 만든 건 "나가기"가 보인다', (tester) async {
      await pumpChallenges(tester);

      expect(find.text('삭제'), findsOneWidget);
      expect(find.text('나가기'), findsOneWidget);
    });

    testWidgets('나가기는 확인창에서 나가기를 눌러야 나간다', (tester) async {
      final state = await pumpChallenges(tester);

      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();
      expect(find.text('챌린지에서 나갈까요?'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(
        state.challengeViewModel.myChallenges.map((c) => c.id),
        contains('theirs'),
      );

      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('나가기'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        state.challengeViewModel.myChallenges.map((c) => c.id),
        isNot(contains('theirs')),
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('삭제는 확인창에서 삭제를 눌러야 지워진다', (tester) async {
      final state = await pumpChallenges(tester);

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('챌린지를 삭제할까요?'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('삭제'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        state.challengeViewModel.challenges.map((c) => c.id),
        isNot(contains('mine')),
      );
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
