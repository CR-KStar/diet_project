import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/water_repository.dart';
import 'package:diet_project/data/repositories/water_codec.dart';

/// 저장하지 않고 메모리에만 들고 있는 저장소 — Firebase 설정 전 프로토타입과 테스트용.
class MemoryWaterRepository implements WaterRepository {
  final Map<String, Map<String, Map<String, Object?>>> _store = {};

  @override
  Future<List<WaterEntry>> loadDay(String uid, String dateKey) async {
    final docs = _store[uid] ?? const {};
    final list = [
      for (final e in docs.entries)
        if (e.value['dateKey'] == dateKey)
          waterFromMap(e.key, e.value, userId: uid),
    ]..sort(compareWaterOrder);
    return list;
  }

  @override
  Future<void> save(String uid, WaterEntry entry) async {
    (_store[uid] ??= {})[entry.id] = waterToMap(entry);
  }

  @override
  Future<void> delete(String uid, String entryId) async {
    _store[uid]?.remove(entryId);
  }

  @override
  Future<void> deleteAll(String uid) async {
    _store.remove(uid);
  }
}
