import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/social/viewmodel/challenge_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_project/data/repositories/impl/memory_challenge_repository.dart';
import 'package:diet_project/domain/repositories/challenge_repository.dart';
import 'package:diet_project/app_composition.dart';

Challenge _challenge(
  String id, {
  required String creator,
  required List<String> people,
  ChallengeType type = ChallengeType.water,
  int target = 100,
  bool isPublic = true,
}) => Challenge(
  id: id,
  title: id,
  description: '',
  icon: '💧',
  category: '데일리',
  period: '오늘 하루',
  creatorId: creator,
  participantIds: people,
  metricType: type,
  targetValue: target,
  isPublic: isPublic,
  rewardDescription: '',
  bonusDescription: '',
);

class _FailingChallengeRepo extends MemoryChallengeRepository {
  @override
  Future<List<Challenge>> loadAll() async => throw Exception('network down');
}

void main() {
  late MemoryChallengeRepository repo;

  ChallengeViewModel build({
    ChallengeRepository? challengeRepo,
    List<Challenge>? seed,
  }) {
    repo = MemoryChallengeRepository(seed: seed ?? []);
    return ChallengeViewModel(
      challengeRepo: challengeRepo ?? repo,
      now: () => DateTime(2026, 10, 18, 9),
    );
  }

  group('ChallengeViewModel · 목록과 참여', () {
    test('내가 참여 중인 것과 참여할 수 있는 공개 챌린지를 나눈다', () async {
      final vm = build(
        seed: [
          _challenge('mine', creator: 'me', people: ['me', 'bob']),
          _challenge('open', creator: 'bob', people: ['bob']),
          _challenge(
            'secret',
            creator: 'bob',
            people: ['bob'],
            isPublic: false,
          ),
        ],
      );
      await vm.loadForUid('me');

      expect(vm.myChallenges.map((c) => c.id), ['mine']);
      expect(vm.joinableChallenges.map((c) => c.id), ['open']);
    });

    test('참여하면 바로 내 챌린지가 되고, 저장소에도 반영된다', () async {
      final vm = build(
        seed: [
          _challenge('open', creator: 'bob', people: ['bob']),
        ],
      );
      await vm.loadForUid('me');

      await vm.joinChallenge('open');

      expect(vm.myChallenges.map((c) => c.id), ['open']);
      expect((await repo.loadAll()).single.participantIds, ['bob', 'me']);
    });

    test('없는 챌린지에 참여해도 아무 일도 일어나지 않는다', () async {
      final vm = build();
      await vm.loadForUid('me');
      var notified = 0;
      vm.addListener(() => notified++);

      await vm.joinChallenge('missing');

      expect(notified, 0);
    });

    test('불러오지 못하면 목록을 비우고 알림 문구와 함께 알린다', () async {
      final vm = build(challengeRepo: _FailingChallengeRepo());
      String? notice;
      vm.onSyncFailed = (m) => notice = m;

      await vm.loadForUid('me');

      expect(vm.challenges, isEmpty);
      expect(notice, '챌린지를 불러오지 못했어요.');
    });

    test('deleteAll: 혼자 만든 챌린지는 지우고, 함께한 챌린지에서는 빠진다', () async {
      final vm = build(
        seed: [
          _challenge('solo', creator: 'me', people: ['me']),
          _challenge('shared', creator: 'bob', people: ['bob', 'me']),
        ],
      );
      await vm.loadForUid('me');

      await vm.deleteAll('me');

      final left = await repo.loadAll();
      expect(left.map((c) => c.id), ['shared']);
      expect(left.single.participantIds, ['bob']);
    });
  });

  group('ChallengeViewModel · 순위', () {
    test('진행률 순으로 순위를 매기고 내 순위를 알려 준다', () async {
      final vm = build(
        seed: [
          _challenge('c', creator: 'me', people: ['me', 'bob', 'carol']),
        ],
      );
      await repo.reportProgress('c', 'me', 50);
      await repo.reportProgress('c', 'bob', 100);
      await repo.reportProgress('c', 'carol', 20);
      await vm.loadForUid('me');

      final board = vm.challengeLeaderboard;
      expect(board.map((r) => r.user.id), ['bob', 'me', 'carol']);
      expect(board.map((r) => r.pct), [100, 50, 20]);
      expect(board.map((r) => r.rank), [1, 2, 3]);
      expect(vm.myChallengeRank, 2);
    });

    test('진행률은 100%를 넘지 않고, 목표가 0이면 0%다', () async {
      final vm = build(
        seed: [
          _challenge('over', creator: 'me', people: ['me']),
          _challenge('zero', creator: 'me', people: ['me'], target: 0),
        ],
      );
      await repo.reportProgress('over', 'me', 500);
      await repo.reportProgress('zero', 'me', 5);
      await vm.loadForUid('me');

      expect(vm.challengeLeaderboard.single.pct, 100);
      expect(vm.activeChallengeProgress.single.ratio, 1.0);

      vm.challenges.removeAt(0); // 'zero'가 대표 챌린지가 되도록
      expect(vm.challengeLeaderboard.single.pct, 0);
    });

    test('참여 중인 챌린지가 없으면 순위도 비어 있다', () async {
      final vm = build();
      await vm.loadForUid('me');

      expect(vm.myChallengeRank, 0);
      expect(vm.challengeLeaderboard, isEmpty);
      expect(vm.activeChallengeName, '');
      expect(vm.activeChallengePeriod, '');
    });

    test('참가자는 userFor로 화면용 사람으로 바꿔서 보여 준다', () async {
      final vm = build(
        seed: [
          _challenge('c', creator: 'me', people: ['me', 'bob']),
        ],
      );
      vm.userFor = (id) =>
          User(id: id, nickname: '닉네임-$id', emoji: '🙂', tint: 0xFFFFFFFF);
      await vm.loadForUid('me');

      expect(vm.challengeLeaderboard.map((r) => r.user.nickname).toSet(), {
        '닉네임-me',
        '닉네임-bob',
      });
    });
  });

  group('ChallengeViewModel · 진행 상황 보고', () {
    test('같은 종류의 내 챌린지에만 보고한다', () async {
      final vm = build(
        seed: [
          _challenge('water', creator: 'me', people: ['me']),
          _challenge(
            'run',
            creator: 'me',
            people: ['me'],
            type: ChallengeType.exercise,
          ),
          _challenge('others', creator: 'bob', people: ['bob']),
        ],
      );
      await vm.loadForUid('me');

      vm.reportProgress(ChallengeType.water, 700);
      await Future<void>.delayed(Duration.zero);

      expect(await repo.loadProgress('water', ['me']), {'me': 700});
      expect(await repo.loadProgress('run', ['me']), {'me': 0});
      expect(await repo.loadProgress('others', ['me']), {'me': 0});
    });

    test('로그인 전(데모)에는 보고하지 않는다', () async {
      final vm = build(
        seed: [
          _challenge('water', creator: 'me', people: ['me']),
        ],
      );
      vm.uid = null;
      vm.challenges = await repo.loadAll();

      vm.reportProgress(ChallengeType.water, 700);
      await Future<void>.delayed(Duration.zero);

      expect(await repo.loadProgress('water', ['me']), {'me': 0});
    });
  });

  group('ChallengeViewModel · 만들기 폼', () {
    test('종류를 바꾸면 목표가 그 종류의 기본값으로 바뀐다', () {
      final vm = build();

      vm.setChKind('운동 시간');

      expect(vm.chKind, '운동 시간');
      expect(vm.chTarget, 40);
      expect(vm.chUnit, '분');
    });

    test('기간은 1~365일로 제한하고, 라벨은 일·주·개월로 보여준다', () {
      final vm = build();

      vm.setChDays(0);
      expect(vm.chDays, 1);
      vm.setChDays(1000);
      expect(vm.chDays, 365);

      vm.setChDays(10);
      expect(vm.chDurLabel, '10일');
      vm.setChDays(14);
      expect(vm.chDurLabel, '2주');
      vm.setChDays(60);
      expect(vm.chDurLabel, '2개월');
    });

    test('목표는 음수가 될 수 없다', () {
      final vm = build();
      vm.setChTarget(-5);
      expect(vm.chTarget, 0);
    });

    test('기간 문구는 오늘부터 계산한다', () {
      final vm = build()..setChDays(7);

      expect(vm.chRange, '10월 18일 ~ 10월 24일 (7일)');
    });

    test('초대는 켜고 끌 수 있고, 미리보기 인원에 나를 더해 센다', () {
      final vm = build();

      vm.toggleChInvite('지현');
      vm.toggleChInvite('민수');
      expect(vm.chInvites, ['지현', '민수']);
      expect(vm.chPreview, contains('참가 3명'));

      vm.toggleChInvite('지현');
      expect(vm.chInvites, ['민수']);
    });

    test('만들면 목록에 바로 들어가고 저장소에도 저장된다', () async {
      final vm = build();
      await vm.loadForUid('me');
      vm
        ..setChKind('물 마시기')
        ..setChDays(7)
        ..toggleChInvite('지현');

      await vm.createChallenge();

      final c = vm.challenges.single;
      expect(c.title, '물 마시기 2,000ml 1주 챌린지');
      expect(c.period, '10/18 ~ 10/24');
      expect(c.creatorId, 'me');
      expect(c.participantIds, ['me', 'u_jihyun']);
      expect(c.metricType, ChallengeType.water);
      expect((await repo.loadAll()).map((x) => x.id), [c.id]);
    });
  });

  // 예전에는 "저장소가 읽기 전용 목록을 주면 챌린지를 만들 때 터지는" 문제가 있었다.
  test('읽기 전용 목록을 주는 저장소에서도 챌린지를 만들 수 있다', () async {
    final vm = ChallengeViewModel(challengeRepo: MemoryChallengeRepository());
    await vm.loadForUid('me');

    await vm.createChallenge();

    expect(vm.challenges.any((c) => c.creatorId == 'me'), isTrue);
  });

  group('AppState 연결', () {
    test('챌린지를 만들면 챌린지 탭으로 이동한다', () async {
      final s = AppState(
        dependencies: memoryDependencies(
          challengeRepo: MemoryChallengeRepository(seed: []),
        ),
      );

      await s.createChallenge();

      expect(s.navigationViewModel.screen, 'friends');
      expect(s.navigationViewModel.friendTab, '챌린지');
      // 데모 계정은 예시 챌린지 2개로 시작하고, 새로 만든 것이 맨 뒤에 붙는다.
      expect(s.challenges, hasLength(3));
      expect(s.challenges.last.creatorId, User.meId);
    });

    test('챌린지 목록 변화가 화면이 구독하는 ViewModel에 전달된다', () async {
      final s = AppState(
        dependencies: memoryDependencies(
          challengeRepo: MemoryChallengeRepository(seed: []),
        ),
      );
      var notified = 0;
      s.challengeViewModel.addListener(() => notified++);

      s.setChKind('단백질');

      expect(notified, greaterThan(0));
      expect(s.chKind, '단백질');
    });
  });
}
