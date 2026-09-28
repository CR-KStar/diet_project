import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diet_project/domain/models/models.dart';

import 'friend_repository.dart';

/// 초대 코드 · 친구 요청 · 친구 관계를 Firestore에 저장하고 불러오는 저장소.
///
/// 다른 저장소들과 다르게 users/{uid} 밑이 아니라 최상위 컬렉션
/// (publicProfiles · inviteCodes · friendRequests · friendships)을 쓴다 —
/// 이 데이터는 "내 기록"이 아니라 "나와 다른 사람 사이의 관계"라서다.
class FirestoreFriendRepository implements FriendRepository {
  FirestoreFriendRepository({FirebaseFirestore? db}) : _injected = db;

  final FirebaseFirestore? _injected;

  // AppState가 만들어지는 시점(테스트 포함)엔 Firebase가 아직 초기화되지
  // 않았을 수 있어서, 실제로 어떤 메서드가 호출될 때만 늦게 가져온다.
  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  // 헷갈리는 글자(0/O, 1/I)는 뺐다 — 사람이 손으로 옮겨 적는 코드라서.
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _randomCode() {
    final rnd = Random();
    return List.generate(
      6,
      (_) => _codeChars[rnd.nextInt(_codeChars.length)],
    ).join();
  }

  @override
  Future<String> ensureInviteCode(String uid, String nickname) async {
    final profileDoc = _db.collection('publicProfiles').doc(uid);
    final existing = await profileDoc.get();
    final data = existing.data();
    if (data != null && data['inviteCode'] is String) {
      await profileDoc.set({'nickname': nickname}, SetOptions(merge: true));
      return data['inviteCode'] as String;
    }

    // 아주 드물게 코드가 겹칠 수 있어서 몇 번 다시 시도한다.
    for (var i = 0; i < 5; i++) {
      final code = _randomCode();
      final codeDoc = _db.collection('inviteCodes').doc(code);
      if ((await codeDoc.get()).exists) continue;
      await codeDoc.set({'uid': uid});
      await profileDoc.set({'nickname': nickname, 'inviteCode': code});
      return code;
    }
    throw StateError('초대 코드를 만들지 못했어요. 다시 시도해주세요.');
  }

  @override
  Future<String?> findUidByCode(String code) async {
    final doc = await _db
        .collection('inviteCodes')
        .doc(code.trim().toUpperCase())
        .get();
    final uid = doc.data()?['uid'];
    return uid is String ? uid : null;
  }

  @override
  Future<PublicProfile?> loadPublicProfile(String uid) async {
    final doc = await _db.collection('publicProfiles').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return PublicProfile(
      uid: uid,
      nickname: (data['nickname'] as String?) ?? '이름 없음',
    );
  }

  @override
  Future<void> sendFriendRequest(String fromUid, String toUid) {
    return _db.collection('friendRequests').add({
      'fromUid': fromUid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<FriendRequest>> loadIncomingRequests(String uid) async {
    final snap = await _db
        .collection('friendRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();
    return [
      for (final d in snap.docs)
        FriendRequest(
          id: d.id,
          fromUid: d.data()['fromUid'] as String,
          toUid: d.data()['toUid'] as String,
          status: FriendRequestStatus.pending,
        ),
    ];
  }

  @override
  Future<void> acceptFriendRequest(FriendRequest request) async {
    final pairId = ([request.fromUid, request.toUid]..sort()).join('_');
    final batch = _db.batch();
    batch.set(_db.collection('friendships').doc(pairId), {
      'users': [request.fromUid, request.toUid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('friendRequests').doc(request.id), {
      'status': 'accepted',
    });
    await batch.commit();
  }

  @override
  Future<void> declineFriendRequest(String requestId) {
    return _db.collection('friendRequests').doc(requestId).update({
      'status': 'declined',
    });
  }

  @override
  Future<List<String>> loadFriendUids(String uid) async {
    final snap = await _db
        .collection('friendships')
        .where('users', arrayContains: uid)
        .get();
    return [
      for (final d in snap.docs) ...(d.data()['users'] as List).cast<String>(),
    ]..removeWhere((id) => id == uid);
  }
}
