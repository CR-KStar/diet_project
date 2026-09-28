import 'enums.dart';

/// 초대 코드 검색 등에서 쓰는, 다른 사람에게 공개되는 최소 프로필.
class PublicProfile {
  const PublicProfile({required this.uid, required this.nickname});

  final String uid;
  final String nickname;
}

/// 친구 요청 하나 — 누가 누구에게 보냈는지와 지금 상태.
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final FriendRequestStatus status;
}

/// 친구 활동 피드에 뜨는 항목 하나 — "누가 뭘 했다"는 짧은 한 줄.
class ActivityFeedEntry {
  const ActivityFeedEntry({
    required this.uid,
    required this.message,
    required this.at,
  });

  final String uid;
  final String message;
  final DateTime at;
}
