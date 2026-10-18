import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/data/repositories/profile_codec.dart';
import 'package:diet_project/domain/repositories/profile_repository.dart';

/// Firebase 없이 메모리에만 저장하는 버전 — 테스트용.
class MemoryProfileRepository implements ProfileRepository {
  final Map<String, Map<String, Object?>> _store = {};

  @override
  Future<SavedProfile?> load(String uid) async {
    final map = _store[uid];
    return map == null ? null : ProfileCodec.fromMap(map, userId: uid);
  }

  @override
  Future<void> save(String uid, SavedProfile profile) async {
    _store[uid] = ProfileCodec.toMap(profile);
  }

  @override
  Future<void> delete(String uid) async {
    _store.remove(uid);
  }
}
