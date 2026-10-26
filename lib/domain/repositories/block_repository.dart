/// 내가 차단한 사용자 목록 — 내 계정에만 속하는 정보다.
abstract class BlockRepository {
  /// 차단한 사용자들 (uid → 차단 당시 닉네임).
  Future<Map<String, String>> loadBlocked(String uid);

  Future<void> block(String uid, String targetUid, String nickname);

  Future<void> unblock(String uid, String targetUid);

  /// 계정 삭제 때 차단 목록을 모두 지운다.
  Future<void> deleteAll(String uid);
}
