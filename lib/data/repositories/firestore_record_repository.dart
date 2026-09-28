import 'package:cloud_firestore/cloud_firestore.dart';

import 'record_repository.dart';

/// Firestore의 `users/{uid}/{collection}/{문서 id}`에 기록을 저장하는 공통 저장소.
class FirestoreRecordRepository<T> implements RecordRepository<T> {
  FirestoreRecordRepository(
    this.collection,
    this.codec, {
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  final String collection;
  final RecordCodec<T> codec;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection(collection);

  List<T> _decode(String uid, QuerySnapshot<Map<String, dynamic>> snap) =>
      sortedRecords([
        for (final d in snap.docs) codec.fromMap(d.id, d.data(), uid),
      ], codec);

  @override
  Future<List<T>> loadAll(String uid) async =>
      _decode(uid, await _col(uid).get());

  @override
  Future<List<T>> loadRange(String uid, String fromKey, String toKey) async {
    // 날짜 한 칸에만 범위를 걸어서 별도 색인이 필요 없다. 정렬은 가져온 뒤에 한다.
    final snap = await _col(uid)
        .where('dateKey', isGreaterThanOrEqualTo: fromKey)
        .where('dateKey', isLessThanOrEqualTo: toKey)
        .get();
    return _decode(uid, snap);
  }

  @override
  Future<void> save(String uid, T entry) {
    return _col(uid).doc(codec.idOf(entry)).set({
      ...codec.toMap(entry),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();

  @override
  Future<void> deleteAll(String uid) async {
    // 한 번에 지울 수 있는 개수에 한도가 있어서, 나누어 지운다.
    while (true) {
      final snap = await _col(uid).limit(300).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }
}
