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

List<T> sortedRecords<T>(Iterable<T> items, RecordCodec<T> codec) {
  final list = items.toList();
  list.sort((a, b) {
    final byDate = codec.dateKeyOf(a).compareTo(codec.dateKeyOf(b));
    return byDate != 0 ? byDate : codec.idOf(a).compareTo(codec.idOf(b));
  });
  return list;
}
