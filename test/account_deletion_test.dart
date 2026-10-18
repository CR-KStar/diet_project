import 'package:diet_project/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_project/data/repositories/impl/memory_activity_feed_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_challenge_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_friend_repository.dart';
import 'package:diet_project/data/auth/auth_service.dart';

/// 로그인된 계정처럼 동작하고, 삭제 전에 beforeDelete를 불러주는 가짜 인증.
class _Auth implements AuthService {
  _Auth(this.uid);

  final String uid;

  @override
  AuthAccount? get currentAccount =>
      AuthAccount(uid: uid, provider: LoginProvider.google);

  @override
  Future<AuthAccount?> restoreAccount() async => currentAccount;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => currentAccount;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {
    await beforeDelete?.call();
  }
}

Challenge _challenge(String id, String creator, List<String> people) =>
    Challenge(
      id: id,
      title: id,
      description: '',
      icon: '💧',
      category: '데일리',
      period: '오늘 하루',
      creatorId: creator,
      participantIds: people,
      metricType: ChallengeType.water,
      targetValue: 2000,
      isPublic: true,
      rewardDescription: '',
      bonusDescription: '',
    );

void main() {
  test('계정을 삭제하면 친구 · 챌린지 · 활동 피드의 내 데이터도 지워지고 다른 사람 것은 남는다', () async {
    final friends = MemoryFriendRepository();
    await friends.ensureInviteCode('me', '나');
    await friends.ensureInviteCode('bob', '밥');
    await friends.sendFriendRequest('bob', 'me');
    final request = (await friends.loadIncomingRequests('me')).single;
    await friends.acceptFriendRequest(request); // me ↔ bob 친구
    await friends.sendFriendRequest('me', 'carol'); // 내가 보낸 요청

    final challenges = MemoryChallengeRepository(
      seed: [
        _challenge('solo', 'me', ['me']), // 혼자 만든 챌린지 → 삭제
        _challenge('shared', 'bob', ['bob', 'me']), // 밥이 만든 것 → 나만 빠짐
      ],
    );
    await challenges.reportProgress('solo', 'me', 5);
    await challenges.reportProgress('shared', 'me', 7);
    await challenges.reportProgress('shared', 'bob', 9);

    final feed = MemoryActivityFeedRepository();
    await feed.post('me', '식단을 기록했어요');
    await feed.post('bob', '물을 마셨어요');

    final s = AppState(
      auth: _Auth('me'),
      friendRepo: friends,
      challengeRepo: challenges,
      activityFeedRepo: feed,
    );
    await s.restoreSession();

    expect(await s.deleteAccount(), isTrue);

    // 친구: 내 프로필 · 친구 관계 · 보낸 요청이 사라지고, 밥의 친구 목록에서도 빠진다.
    expect(await friends.loadPublicProfile('me'), isNull);
    expect(await friends.loadFriendUids('bob'), isEmpty);
    expect(await friends.loadIncomingRequests('carol'), isEmpty);
    expect(await friends.loadPublicProfile('bob'), isNotNull);

    // 챌린지: 혼자 만든 건 삭제, 함께한 건 내 이름만 빠지고 진행 기록도 지워진다.
    final left = await challenges.loadAll();
    expect(left.map((c) => c.id), ['shared']);
    expect(left.single.participantIds, ['bob']);
    expect(await challenges.loadProgress('shared', ['me', 'bob']), {
      'me': 0,
      'bob': 9,
    });

    // 활동 피드: 내 것만 사라진다.
    final entries = await feed.loadRecent(['me', 'bob']);
    expect(entries.map((e) => e.uid), ['bob']);
  });
}
