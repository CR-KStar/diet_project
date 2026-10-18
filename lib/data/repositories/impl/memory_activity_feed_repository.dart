import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/activity_feed_repository.dart';

/// Firebase 없이 메모리에만 저장하는 버전 — 데모 모드 · 테스트용.
class MemoryActivityFeedRepository implements ActivityFeedRepository {
  final List<ActivityFeedEntry> _all = [];

  @override
  Future<void> post(String uid, String message) async {
    _all.insert(
      0,
      ActivityFeedEntry(uid: uid, message: message, at: DateTime.now()),
    );
  }

  @override
  Future<List<ActivityFeedEntry>> loadRecent(List<String> userIds) async => [
    for (final e in _all)
      if (userIds.contains(e.uid)) e,
  ];

  @override
  Future<void> deleteAllForUser(String uid) async {
    _all.removeWhere((e) => e.uid == uid);
  }
}
