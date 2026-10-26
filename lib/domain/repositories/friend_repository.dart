import 'package:diet_project/domain/models/models.dart';

/// 초대 코드 · 친구 요청 · 친구 관계를 다루는 저장소.
///
/// 다른 저장소들과 다르게 "내 기록"이 아니라 "나와 다른 사람 사이의 관계"를
/// 담당해서, users/{uid} 밑이 아니라 별도 공간(구현체에 따라 다름)에 둔다.
abstract class FriendRepository {
  /// 이 계정의 초대 코드를 가져온다. 처음이면 새로 만든다.
  Future<String> ensureInviteCode(String uid, String nickname);

  /// 코드로 상대방 uid를 찾는다. 없는 코드면 null.
  Future<String?> findUidByCode(String code);

  Future<PublicProfile?> loadPublicProfile(String uid);

  /// fromUid가 toUid에게 친구 요청을 보낸다.
  Future<void> sendFriendRequest(String fromUid, String toUid);

  /// 내가 받은, 아직 답하지 않은 친구 요청 목록.
  Future<List<FriendRequest>> loadIncomingRequests(String uid);

  /// 요청을 수락하고, 서로를 정식 친구 관계로 확정한다.
  Future<void> acceptFriendRequest(FriendRequest request);

  Future<void> declineFriendRequest(String requestId);

  /// 이 계정의 친구 uid 목록.
  Future<List<String>> loadFriendUids(String uid);

  /// 내가 보낸, 아직 답을 받지 못한 친구 요청 목록.
  Future<List<FriendRequest>> loadOutgoingRequests(String uid);

  /// 내가 보낸 요청을 취소한다 (상대가 아직 답하지 않았을 때).
  Future<void> cancelFriendRequest(String requestId);

  /// 친구 관계를 끊는다 — 상대의 친구 목록에서도 나가 사라진다.
  Future<void> removeFriend(String uid, String friendUid);

  /// 계정 삭제 때 이 사용자의 공개 프로필 · 초대 코드 · 친구 관계 · 친구 요청을 모두 지운다.
  Future<void> deleteAllForUser(String uid);
}
