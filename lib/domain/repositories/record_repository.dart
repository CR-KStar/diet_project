abstract class RecordRepository<T> {
  Future<List<T>> loadAll(String uid);

  /// [fromKey]부터 [toKey]까지(양 끝 포함).
  Future<List<T>> loadRange(String uid, String fromKey, String toKey);

  /// 같은 id가 있으면 덮어쓴다.
  Future<void> save(String uid, T entry);

  Future<void> delete(String uid, String id);

  Future<void> deleteAll(String uid);
}
