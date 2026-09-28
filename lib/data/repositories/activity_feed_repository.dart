import 'package:diet_project/domain/models/models.dart';

/// 친구 활동 피드("누가 뭘 했다") 저장소.
abstract class ActivityFeedRepository {
  Future<void> post(String uid, String message);

  /// userIds(친구 + 나)가 남긴 최근 활동을 최신순으로.
  Future<List<ActivityFeedEntry>> loadRecent(List<String> userIds);
}

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
}
