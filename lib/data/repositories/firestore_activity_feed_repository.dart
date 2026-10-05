import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diet_project/domain/models/models.dart';

import 'activity_feed_repository.dart';

/// 활동 피드를 Firestore 최상위 `activityFeed` 컬렉션에 저장하는 저장소.
class FirestoreActivityFeedRepository implements ActivityFeedRepository {
  FirestoreActivityFeedRepository({FirebaseFirestore? db}) : _injected = db;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('activityFeed');

  @override
  Future<void> post(String uid, String message) {
    return _col.add({
      'uid': uid,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<ActivityFeedEntry>> loadRecent(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    // Firestore whereIn은 한 번에 최대 30개까지만 받아서, 30개씩 나눠 조회한다.
    final entries = <ActivityFeedEntry>[];
    for (var i = 0; i < userIds.length; i += 30) {
      final chunk = userIds.sublist(
        i,
        i + 30 > userIds.length ? userIds.length : i + 30,
      );
      final snap = await _col
          .where('uid', whereIn: chunk)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      for (final d in snap.docs) {
        final data = d.data();
        final uid = data['uid'];
        final message = data['message'];
        final createdAt = data['createdAt'];
        if (uid is String && message is String && createdAt is Timestamp) {
          entries.add(
            ActivityFeedEntry(
              uid: uid,
              message: message,
              at: createdAt.toDate(),
            ),
          );
        }
      }
    }
    entries.sort((a, b) => b.at.compareTo(a.at));
    return entries.take(20).toList();
  }
}
