import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diet_project/config/firestore_collections.dart';
import 'package:diet_project/domain/repositories/block_repository.dart';

import 'firestore_delete_where.dart';

/// 차단 목록을 `users/{uid}/blocks/{차단한 uid}`에 저장한다 — 내 계정 아래라서
/// 보안 규칙의 "본인만 읽고 쓴다"가 그대로 적용된다.
class FirestoreBlockRepository implements BlockRepository {
  FirestoreBlockRepository({FirebaseFirestore? db}) : _injected = db;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _db
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.blocks);

  @override
  Future<Map<String, String>> loadBlocked(String uid) async {
    final snap = await _col(uid).get();
    return {
      for (final d in snap.docs) d.id: (d.data()['nickname'] as String?) ?? '',
    };
  }

  @override
  Future<void> block(String uid, String targetUid, String nickname) {
    return _col(uid).doc(targetUid).set({
      'nickname': nickname,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unblock(String uid, String targetUid) =>
      _col(uid).doc(targetUid).delete();

  @override
  Future<void> deleteAll(String uid) => deleteWhere(_db, _col(uid));
}
