import 'package:diet_project/data/repositories/record_codec.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';

/// Firebase 없이 메모리에만 저장하는 버전 — 테스트용.
class MemoryRecordRepository<T> implements RecordRepository<T> {
  MemoryRecordRepository(this.codec);

  final RecordCodec<T> codec;
  final Map<String, Map<String, Map<String, Object?>>> _store = {};

  List<T> _decode(
    String uid,
    Iterable<MapEntry<String, Map<String, Object?>>> docs,
  ) => sortedRecords([
    for (final d in docs) codec.fromMap(d.key, d.value, uid),
  ], codec);

  @override
  Future<List<T>> loadAll(String uid) async =>
      _decode(uid, (_store[uid] ?? const {}).entries);

  @override
  Future<List<T>> loadRange(String uid, String fromKey, String toKey) async {
    final docs = (_store[uid] ?? const <String, Map<String, Object?>>{}).entries
        .where((d) {
          final key = d.value['dateKey'];
          return key is String &&
              key.compareTo(fromKey) >= 0 &&
              key.compareTo(toKey) <= 0;
        });
    return _decode(uid, docs);
  }

  @override
  Future<void> save(String uid, T entry) async {
    (_store[uid] ??= {})[codec.idOf(entry)] = codec.toMap(entry);
  }

  @override
  Future<void> delete(String uid, String id) async {
    _store[uid]?.remove(id);
  }

  @override
  Future<void> deleteAll(String uid) async {
    _store.remove(uid);
  }
}
