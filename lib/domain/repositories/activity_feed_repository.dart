import 'package:diet_project/domain/models/models.dart';

/// 친구 활동 피드("누가 뭘 했다") 저장소.
abstract class ActivityFeedRepository {
  Future<void> post(String uid, String message);

  /// userIds(친구 + 나)가 남긴 최근 활동을 최신순으로.
  Future<List<ActivityFeedEntry>> loadRecent(List<String> userIds);

  /// 계정 삭제 때 이 사용자가 남긴 활동을 모두 지운다.
  Future<void> deleteAllForUser(String uid);
}
