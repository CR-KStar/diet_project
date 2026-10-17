import 'package:cloud_firestore/cloud_firestore.dart';

/// [query]에 해당하는 문서를 전부 지운다.
/// 한 번에 지울 수 있는 개수에 한도가 있어서, 나누어 지운다.
Future<void> deleteWhere(
  FirebaseFirestore db,
  Query<Map<String, dynamic>> query,
) async {
  while (true) {
    final snap = await query.limit(300).get();
    if (snap.docs.isEmpty) return;
    final batch = db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
