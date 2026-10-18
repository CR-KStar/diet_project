import 'package:diet_project/domain/models/friend_request_status.dart';

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
