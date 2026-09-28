import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diet_project/domain/models/models.dart';

import 'water_repository.dart';

/// Firestore의 `users/{uid}/water/{기록 id}` 문서에 물 기록을 저장하는 저장소.
class FirestoreWaterRepository implements WaterRepository {
  FirestoreWaterRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('water');

  @override
  Future<List<WaterEntry>> loadDay(String uid, String dateKey) async {
    // 날짜 하나로만 거르면 별도 색인이 필요 없다. 정렬은 가져온 뒤에 한다(하루치라 적다).
    final snap = await _col(uid).where('dateKey', isEqualTo: dateKey).get();
    return [
      for (final d in snap.docs) waterFromMap(d.id, d.data(), userId: uid),
    ]..sort(compareWaterOrder);
  }

  @override
  Future<void> save(String uid, WaterEntry entry) {
    return _col(uid).doc(entry.id).set({
      ...waterToMap(entry),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String uid, String entryId) =>
      _col(uid).doc(entryId).delete();

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
