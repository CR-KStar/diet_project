import 'package:diet_project/data/repositories/impl/memory_activity_feed_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_block_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_friend_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_report_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/block_repository.dart';
import 'package:diet_project/domain/repositories/friend_repository.dart';
import 'package:diet_project/domain/repositories/report_repository.dart';
import 'package:diet_project/ui/social/viewmodel/friend_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// 동작을 실패시킬 수 있는 친구 저장소.
class _Friends extends MemoryFriendRepository {
  bool failRemove = false;
  bool failCancel = false;

  @override
  Future<void> removeFriend(String uid, String friendUid) async {
    if (failRemove) throw Exception('network down');
    return super.removeFriend(uid, friendUid);
  }

  @override
  Future<void> cancelFriendRequest(String requestId) async {
    if (failCancel) throw Exception('network down');
    return super.cancelFriendRequest(requestId);
  }
}

class _Blocks extends MemoryBlockRepository {
  bool fail = false;

  @override
  Future<void> block(String uid, String targetUid, String nickname) async {
    if (fail) throw Exception('network down');
    return super.block(uid, targetUid, nickname);
  }

  @override
  Future<void> unblock(String uid, String targetUid) async {
    if (fail) throw Exception('network down');
    return super.unblock(uid, targetUid);
  }
}

class _Reports extends MemoryReportRepository {
  bool fail = false;

  @override
  Future<void> submit(UserReport report) async {
    if (fail) throw Exception('network down');
    return super.submit(report);
  }
}

void main() {
  late _Friends friends;
  late _Blocks blocks;
  late _Reports reports;
  late MemoryActivityFeedRepository feed;
  final messages = <String>[];

  FriendViewModel build(String uid, String nickname) {
    final vm = FriendViewModel(
      friendRepo: friends as FriendRepository,
      activityFeedRepo: feed,
      blockRepo: blocks as BlockRepository,
      reportRepo: reports as ReportRepository,
      now: () => DateTime(2026, 10, 18, 12),
    )..nickname = (() => nickname);
    vm.onSyncFailed = messages.add;
    return vm;
  }

  setUp(() {
    friends = _Friends();
    blocks = _Blocks();
    reports = _Reports();
    feed = MemoryActivityFeedRepository();
    messages.clear();
  });

  /// me와 bob이 서로 친구인 상태로 만든다.
  Future<(FriendViewModel, FriendViewModel)> befriended() async {
    final me = build('me', '채린');
    final bob = build('bob', '밥');
    await me.loadForUid('me');
    await bob.loadForUid('bob');
    final bobCode = (await friends.ensureInviteCode('bob', '밥'));
    me.setFriendSearchQuery(bobCode);
    await me.searchFriendByCode();
    await me.sendFriendRequestToSearchResult();
    await bob.loadForUid('bob');
    await bob.acceptFriendRequest(bob.incomingFriendRequests.single);
    await me.loadForUid('me');
    return (me, bob);
  }

  group('친구 끊기', () {
    test('끊으면 내 목록에서 사라지고 상대의 목록에서도 사라진다', () async {
      final (me, bob) = await befriended();
      expect(me.realFriends.map((f) => f.uid), ['bob']);

      final ok = await me.removeFriend('bob');

      expect(ok, isTrue);
      expect(me.realFriends, isEmpty);
      await bob.loadForUid('bob');
      expect(bob.realFriends, isEmpty);
    });

    test('끊은 친구의 활동은 피드에서도 사라진다', () async {
      final (me, _) = await befriended();
      await feed.post('bob', '식단을 기록했어요');
      await me.loadForUid('me');
      expect(me.friendActivity, hasLength(1));

      await me.removeFriend('bob');

      expect(me.friendActivity, isEmpty);
    });

    test('서버에서 끊지 못하면 친구 목록은 그대로고 알린다', () async {
      final (me, _) = await befriended();
      friends.failRemove = true;

      final ok = await me.removeFriend('bob');

      expect(ok, isFalse);
      expect(me.realFriends.map((f) => f.uid), ['bob']);
      expect(messages.single, contains('친구를 끊지 못했어요'));
    });
  });

  group('보낸 요청 취소', () {
    Future<(FriendViewModel, FriendRequest)> sentRequest() async {
      final me = build('me', '채린');
      await me.loadForUid('me');
      final code = await friends.ensureInviteCode('bob', '밥');
      me.setFriendSearchQuery(code);
      await me.searchFriendByCode();
      await me.sendFriendRequestToSearchResult();
      return (me, me.outgoingFriendRequests.single);
    }

    test('보낸 요청이 목록에 나오고, 받는 사람의 닉네임도 알 수 있다', () async {
      final (me, request) = await sentRequest();

      expect(request.toUid, 'bob');
      expect(me.outgoingProfiles['bob']?.nickname, '밥');
    });

    test('취소하면 목록에서 없어지고 상대는 더 이상 받지 않는다', () async {
      final (me, request) = await sentRequest();

      expect(await me.cancelFriendRequest(request), isTrue);

      expect(me.outgoingFriendRequests, isEmpty);
      expect(await friends.loadIncomingRequests('bob'), isEmpty);
    });

    test('취소하지 못하면 그대로 두고 알린다', () async {
      final (me, request) = await sentRequest();
      friends.failCancel = true;

      expect(await me.cancelFriendRequest(request), isFalse);

      expect(me.outgoingFriendRequests, hasLength(1));
      expect(messages.single, contains('취소하지 못했어요'));
    });
  });

  group('차단', () {
    test('친구를 차단하면 친구 관계가 끊기고 활동이 숨겨진다', () async {
      final (me, bob) = await befriended();
      await feed.post('bob', '운동했어요');
      await me.loadForUid('me');
      expect(me.friendActivity, hasLength(1));

      expect(await me.blockUser('bob', '밥'), isTrue);

      expect(me.isBlocked('bob'), isTrue);
      expect(me.realFriends, isEmpty);
      expect(me.friendActivity, isEmpty);
      await bob.loadForUid('bob');
      expect(bob.realFriends, isEmpty);
    });

    test('차단한 사람이 보낸 요청은 정리되고, 다시 불러와도 나타나지 않는다', () async {
      final me = build('me', '채린');
      final bob = build('bob', '밥');
      await me.loadForUid('me');
      await bob.loadForUid('bob');
      final myCode = await friends.ensureInviteCode('me', '채린');
      bob.setFriendSearchQuery(myCode);
      await bob.searchFriendByCode();
      await bob.sendFriendRequestToSearchResult();
      await me.loadForUid('me');
      expect(me.incomingFriendRequests, hasLength(1));

      await me.blockUser('bob', '밥');
      expect(me.incomingFriendRequests, isEmpty);

      await me.loadForUid('me');
      expect(me.incomingFriendRequests, isEmpty);
    });

    test('차단한 사람의 초대 코드로 검색하면 찾았다고 하지 않고 차단 상태로 알려준다', () async {
      final me = build('me', '채린');
      await me.loadForUid('me');
      final code = await friends.ensureInviteCode('bob', '밥');
      await me.blockUser('bob', '밥');

      me.setFriendSearchQuery(code);
      await me.searchFriendByCode();

      expect(me.friendSearchResult, isNull);
      expect(me.friendSearchBlocked, isTrue);
      expect(me.friendSearchNotFound, isFalse);
    });

    test('다시 불러와도 차단 목록이 남고, 해제하면 풀린다', () async {
      final me = build('me', '채린');
      await me.loadForUid('me');
      await me.blockUser('bob', '밥');

      final again = build('me', '채린');
      await again.loadForUid('me');
      expect(again.blocked, {'bob': '밥'});

      expect(await again.unblock('bob'), isTrue);
      expect(again.isBlocked('bob'), isFalse);
      final third = build('me', '채린');
      await third.loadForUid('me');
      expect(third.blocked, isEmpty);
    });

    test('차단이 저장되지 않으면 아무것도 바꾸지 않는다', () async {
      final (me, _) = await befriended();
      blocks.fail = true;

      expect(await me.blockUser('bob', '밥'), isFalse);

      expect(me.isBlocked('bob'), isFalse);
      expect(me.realFriends.map((f) => f.uid), ['bob']);
      expect(messages.single, contains('차단하지 못했어요'));
    });

    test('계정을 삭제하면 차단 목록도 지워진다', () async {
      final me = build('me', '채린');
      await me.loadForUid('me');
      await me.blockUser('bob', '밥');

      await me.deleteAll('me');

      expect(await blocks.loadBlocked('me'), isEmpty);
    });
  });

  group('신고', () {
    test('사유와 설명이 신고로 접수된다', () async {
      final me = build('me', '채린');
      await me.loadForUid('me');

      final ok = await me.reportUser(
        targetUid: 'bob',
        nickname: '밥',
        reason: ReportReason.harassment,
        detail: '  계속 이상한 요청을 보내요  ',
      );

      expect(ok, isTrue);
      final r = reports.submitted.single;
      expect(r.reporterUid, 'me');
      expect(r.targetUid, 'bob');
      expect(r.targetNickname, '밥');
      expect(r.reason, ReportReason.harassment);
      expect(r.detail, '계속 이상한 요청을 보내요');
    });

    test('접수하지 못하면 false를 돌려준다 (화면이 다시 시도하게 안내한다)', () async {
      final me = build('me', '채린');
      reports.fail = true;

      final ok = await me.reportUser(
        targetUid: 'bob',
        nickname: '밥',
        reason: ReportReason.spam,
      );

      expect(ok, isFalse);
      expect(reports.submitted, isEmpty);
    });
  });
}
