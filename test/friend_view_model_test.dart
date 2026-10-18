import 'package:diet_project/data/repositories/activity_feed_repository.dart';
import 'package:diet_project/data/repositories/friend_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/social/viewmodel/friend_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// 불러오기를 실패시킬 수 있는 친구 저장소.
class _FailingFriendRepo extends MemoryFriendRepository {
  @override
  Future<List<String>> loadFriendUids(String uid) async =>
      throw Exception('network down');
}

/// 글이 올라온 횟수를 세고, 실패시킬 수 있는 활동 피드 저장소.
class _Feed extends MemoryActivityFeedRepository {
  _Feed({this.failPost = false});

  final bool failPost;
  final posted = <String>[];

  @override
  Future<void> post(String uid, String message) async {
    if (failPost) throw Exception('network down');
    posted.add('$uid:$message');
    return super.post(uid, message);
  }
}

void main() {
  late MemoryFriendRepository friends;
  late _Feed feed;
  late DateTime clock;

  FriendViewModel build({
    FriendRepository? friendRepo,
    _Feed? activityFeed,
    String nickname = '나',
  }) {
    friends = MemoryFriendRepository();
    feed = activityFeed ?? _Feed();
    return FriendViewModel(
      friendRepo: friendRepo ?? friends,
      activityFeedRepo: feed,
      now: () => clock,
    )..nickname = () => nickname;
  }

  setUp(() => clock = DateTime(2026, 10, 18, 12));

  group('FriendViewModel · 사람 찾기', () {
    test('내 닉네임은 AppState가 갖고 있어서 매번 물어본다', () {
      var name = '새싹';
      final vm = build()..nickname = () => name;
      expect(vm.currentUser.nickname, '새싹');

      name = '채린';
      expect(vm.currentUser.nickname, '채린');
    });

    test('userFor: 나 → 실제 친구 → 데모 인물 → 알 수 없음 순서로 찾는다', () {
      final vm = build(nickname: '채린')..uid = 'me';
      vm.realFriends = [const PublicProfile(uid: 'bob', nickname: '밥')];

      expect(vm.userFor('me').nickname, '채린');
      expect(vm.userFor('bob').nickname, '밥');
      expect(vm.userFor('u_jihyun').nickname, '지현');
      expect(vm.userFor('nobody').nickname, '알 수 없음');
    });
  });

  group('FriendViewModel · 친구 요청', () {
    test('초대 코드로 찾아 요청을 보내면 상대가 받고, 수락하면 친구가 된다', () async {
      final me = build(nickname: '채린');
      // 상대(bob)가 먼저 가입해 초대 코드를 갖고 있다.
      final bobCode = await friends.ensureInviteCode('bob', '밥');
      await me.loadForUid('me');

      me.setFriendSearchQuery(bobCode);
      await me.searchFriendByCode();
      expect(me.friendSearchResult?.uid, 'bob');
      expect(me.friendSearchNotFound, isFalse);

      await me.sendFriendRequestToSearchResult();
      expect(me.friendSearchResult, isNull);
      expect(me.friendSearchQuery, '');

      // bob 쪽에서 받은 요청을 수락한다.
      final bob = FriendViewModel(
        friendRepo: friends,
        activityFeedRepo: feed,
        now: () => clock,
      )..nickname = () => '밥';
      await bob.loadForUid('bob');
      expect(bob.incomingFriendRequests, hasLength(1));
      expect(bob.requesterProfiles['me']?.nickname, '채린');

      await bob.acceptFriendRequest(bob.incomingFriendRequests.single);
      expect(bob.incomingFriendRequests, isEmpty);
      expect(bob.realFriends.map((f) => f.uid), ['me']);
    });

    test('없는 코드나 내 코드를 찾으면 "없음"으로 표시한다', () async {
      final vm = build();
      await vm.loadForUid('me');

      vm.setFriendSearchQuery('NOPE');
      await vm.searchFriendByCode();
      expect(vm.friendSearchNotFound, isTrue);
      expect(vm.friendSearchResult, isNull);

      vm.setFriendSearchQuery(vm.inviteCode); // 내 코드
      await vm.searchFriendByCode();
      expect(vm.friendSearchNotFound, isTrue);
    });

    test('검색어를 바꾸면 이전 검색 결과는 사라진다', () async {
      final bobCode = await (friends = MemoryFriendRepository())
          .ensureInviteCode('bob', '밥');
      final vm = FriendViewModel(
        friendRepo: friends,
        activityFeedRepo: MemoryActivityFeedRepository(),
      )..nickname = () => '나';
      vm.setFriendSearchQuery(bobCode);
      await vm.searchFriendByCode();
      expect(vm.friendSearchResult, isNotNull);

      vm.setFriendSearchQuery('x');
      expect(vm.friendSearchResult, isNull);
      expect(vm.friendSearchNotFound, isFalse);
    });

    test('요청을 거절하면 목록에서 사라지고 친구는 늘지 않는다', () async {
      await friends.ensureInviteCode('bob', '밥');
      final vm = build();
      await friends.sendFriendRequest('bob', 'me');
      await vm.loadForUid('me');
      expect(vm.incomingFriendRequests, hasLength(1));

      await vm.declineFriendRequest(vm.incomingFriendRequests.single);

      expect(vm.incomingFriendRequests, isEmpty);
      expect(vm.requesterProfiles, isEmpty);
      expect(vm.realFriends, isEmpty);
    });
  });

  group('FriendViewModel · 활동 피드', () {
    test('로그인 전(데모)에는 활동을 남기지 않는다', () async {
      final vm = build();

      vm.postActivity('물 500ml을 기록했어요');
      await Future<void>.delayed(Duration.zero);

      expect(feed.posted, isEmpty);
    });

    test('로그인하면 내 uid로 남기고, 불러오면 방금 전으로 보인다', () async {
      final vm = build(nickname: '채린');
      await vm.loadForUid('me');
      feed.posted.clear();

      vm.postActivity('물 500ml을 기록했어요');
      await Future<void>.delayed(Duration.zero);
      expect(feed.posted, ['me:물 500ml을 기록했어요']);

      await vm.loadForUid('me');
      final item = vm.friendActivity.single;
      expect(item.user.nickname, '채린');
      expect(item.activity, '물 500ml을 기록했어요');
      expect(item.time, '방금');
    });

    test('활동 시각을 "n분 전 · n시간 전 · 어제 · n일 전"으로 보여준다', () {
      final vm = build();
      String at(Duration ago) {
        vm.realActivityFeed = [
          ActivityFeedEntry(
            uid: 'u_jihyun',
            message: 'x',
            at: clock.subtract(ago),
          ),
        ];
        return vm.friendActivity.single.time;
      }

      expect(at(const Duration(seconds: 20)), '방금');
      expect(at(const Duration(minutes: 5)), '5분 전');
      expect(at(const Duration(hours: 3)), '3시간 전');
      expect(at(const Duration(hours: 30)), '어제');
      expect(at(const Duration(days: 4)), '4일 전');
    });

    test('활동 기록이 실패해도 앱은 멈추지 않는다', () async {
      final vm = build(activityFeed: _Feed(failPost: true));
      await vm.loadForUid('me');

      vm.postActivity('x');
      await Future<void>.delayed(Duration.zero);
      // 예외가 밖으로 새면 이 테스트가 실패한다.
    });
  });

  group('FriendViewModel · 불러오기 · 비우기 · 삭제', () {
    test('불러오지 못하면 알림 문구와 함께 알린다', () async {
      final vm = build(friendRepo: _FailingFriendRepo());
      String? notice;
      vm.onSyncFailed = (m) => notice = m;

      await vm.loadForUid('me');

      expect(notice, '친구 정보를 불러오지 못했어요.');
    });

    test('clear: 친구 데이터와 검색 상태를 모두 비운다', () async {
      final vm = build();
      await vm.loadForUid('me');
      vm.realFriends = [const PublicProfile(uid: 'bob', nickname: '밥')];
      vm.friendSearchNotFound = true;

      vm.clear();

      expect(vm.inviteCode, '');
      expect(vm.realFriends, isEmpty);
      expect(vm.incomingFriendRequests, isEmpty);
      expect(vm.friendSearchNotFound, isFalse);
    });

    test('deleteAll: 프로필 · 친구 관계 · 내 활동 피드를 지운다', () async {
      final vm = build();
      await friends.ensureInviteCode('bob', '밥');
      await friends.sendFriendRequest('bob', 'me');
      await vm.loadForUid('me');
      await vm.acceptFriendRequest(vm.incomingFriendRequests.single);
      vm.postActivity('hi');
      await Future<void>.delayed(Duration.zero);

      await vm.deleteAll('me');

      expect(await friends.loadPublicProfile('me'), isNull);
      expect(await friends.loadFriendUids('bob'), isEmpty);
      expect(await feed.loadRecent(['me']), isEmpty);
    });

    test('응원은 한 번 누르면 "응원 완료"로 기억한다', () {
      final vm = build();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.cheerFriend('u_minsu');

      expect(vm.cheeredFriends, {'u_minsu'});
      expect(notified, 1);
    });
  });
}
