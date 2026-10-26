import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/friend_repository.dart';

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

  @override
  Future<List<FriendRequest>> loadOutgoingRequests(String uid) async => [
    for (final r in _requests)
      if (r.fromUid == uid && r.status == FriendRequestStatus.pending) r,
  ];

  @override
  Future<void> cancelFriendRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
  }

  @override
  Future<void> removeFriend(String uid, String friendUid) async {
    _friendships.removeWhere(
      (f) =>
          (f.a == uid && f.b == friendUid) || (f.a == friendUid && f.b == uid),
    );
  }

  @override
  Future<void> deleteAllForUser(String uid) async {
    final code = _uidToCode.remove(uid);
    if (code != null) _codeToUid.remove(code);
    _nicknames.remove(uid);
    _requests.removeWhere((r) => r.fromUid == uid || r.toUid == uid);
    _friendships.removeWhere((f) => f.a == uid || f.b == uid);
  }
}
