/// 기록 한 종류(체중 · 운동 · 식단 · 그릇 · 루틴 · 식물)의 저장 형식.
/// 종류마다 저장소를 새로 만들지 않도록, id · 날짜 · 변환 함수만 여기에 담아 공통 저장소에 넘긴다.
class RecordCodec<T> {
  const RecordCodec({
    required this.idOf,
    required this.dateKeyOf,
    required this.toMap,
    required this.fromMap,
  });

  final String Function(T entry) idOf;

  /// 'yyyy-MM-dd'. 날짜가 없는 종류(그릇 · 루틴 · 식물)는 빈 문자열.
  final String Function(T entry) dateKeyOf;
  final Map<String, Object?> Function(T entry) toMap;
  final T Function(String id, Map<String, Object?> map, String uid) fromMap;
}

abstract class RecordRepository<T> {
  Future<List<T>> loadAll(String uid);

  /// [fromKey]부터 [toKey]까지(양 끝 포함).
  Future<List<T>> loadRange(String uid, String fromKey, String toKey);

  /// 같은 id가 있으면 덮어쓴다.
  Future<void> save(String uid, T entry);

  Future<void> delete(String uid, String id);

  Future<void> deleteAll(String uid);
}

List<T> sortedRecords<T>(Iterable<T> items, RecordCodec<T> codec) {
  final list = items.toList();
  list.sort((a, b) {
    final byDate = codec.dateKeyOf(a).compareTo(codec.dateKeyOf(b));
    return byDate != 0 ? byDate : codec.idOf(a).compareTo(codec.idOf(b));
  });
  return list;
}

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
