import 'package:diet_project/domain/repositories/block_repository.dart';

/// 메모리에만 보관하는 차단 목록 — 테스트와 체험판이 쓴다.
class MemoryBlockRepository implements BlockRepository {
  final Map<String, Map<String, String>> _byUser = {};

  @override
  Future<Map<String, String>> loadBlocked(String uid) async =>
      Map.of(_byUser[uid] ?? const {});

  @override
  Future<void> block(String uid, String targetUid, String nickname) async {
    (_byUser[uid] ??= {})[targetUid] = nickname;
  }

  @override
  Future<void> unblock(String uid, String targetUid) async {
    _byUser[uid]?.remove(targetUid);
  }

  @override
  Future<void> deleteAll(String uid) async => _byUser.remove(uid);
}
