import 'package:diet_project/domain/models/models.dart';

/// 초대 코드 · 친구 요청 · 친구 관계를 다루는 저장소.
///
/// 다른 저장소들과 다르게 "내 기록"이 아니라 "나와 다른 사람 사이의 관계"를
/// 담당해서, users/{uid} 밑이 아니라 별도 공간(구현체에 따라 다름)에 둔다.
abstract class FriendRepository {
  /// 이 계정의 초대 코드를 가져온다. 처음이면 새로 만든다.
  Future<String> ensureInviteCode(String uid, String nickname);

  /// 코드로 상대방 uid를 찾는다. 없는 코드면 null.
  Future<String?> findUidByCode(String code);

  Future<PublicProfile?> loadPublicProfile(String uid);

  /// fromUid가 toUid에게 친구 요청을 보낸다.
  Future<void> sendFriendRequest(String fromUid, String toUid);

  /// 내가 받은, 아직 답하지 않은 친구 요청 목록.
  Future<List<FriendRequest>> loadIncomingRequests(String uid);

  /// 요청을 수락하고, 서로를 정식 친구 관계로 확정한다.
  Future<void> acceptFriendRequest(FriendRequest request);

  Future<void> declineFriendRequest(String requestId);

  /// 이 계정의 친구 uid 목록.
  Future<List<String>> loadFriendUids(String uid);
}

/// Firebase 없이 메모리에만 저장하는 버전 — 데모 모드 · 테스트용.
class MemoryFriendRepository implements FriendRepository {
  final Map<String, String> _codeToUid = {};
  final Map<String, String> _uidToCode = {};
  final Map<String, String> _nicknames = {};
  final List<FriendRequest> _requests = [];
  final List<({String a, String b})> _friendships = [];
  int _nextRequestId = 0;

  @override
  Future<String> ensureInviteCode(String uid, String nickname) async {
    _nicknames[uid] = nickname;
    final existing = _uidToCode[uid];
    if (existing != null) return existing;
    final code = 'DEMO${_uidToCode.length + 1}';
    _uidToCode[uid] = code;
    _codeToUid[code] = uid;
    return code;
  }

  @override
  Future<String?> findUidByCode(String code) async =>
      _codeToUid[code.trim().toUpperCase()];

  @override
  Future<PublicProfile?> loadPublicProfile(String uid) async {
    final nickname = _nicknames[uid];
    if (nickname == null) return null;
    return PublicProfile(uid: uid, nickname: nickname);
  }

  @override
  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    _requests.add(
      FriendRequest(
        id: 'req_${_nextRequestId++}',
        fromUid: fromUid,
        toUid: toUid,
        status: FriendRequestStatus.pending,
      ),
    );
  }

  @override
  Future<List<FriendRequest>> loadIncomingRequests(String uid) async => [
    for (final r in _requests)
      if (r.toUid == uid && r.status == FriendRequestStatus.pending) r,
  ];

  @override
  Future<void> acceptFriendRequest(FriendRequest request) async {
    _friendships.add((a: request.fromUid, b: request.toUid));
    _requests.removeWhere((r) => r.id == request.id);
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
  }

  @override
  Future<List<String>> loadFriendUids(String uid) async => [
    for (final f in _friendships)
      if (f.a == uid) f.b else if (f.b == uid) f.a,
  ];
}
