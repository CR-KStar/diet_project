import 'package:diet_project/domain/models/models.dart';

/// 물 기록을 저장하고 불러오는 저장소. (기록 한 건이 문서 하나입니다.)
abstract class WaterRepository {
  /// 이 계정이 [dateKey] 날짜에 남긴 물 기록 (마신 순서대로).
  Future<List<WaterEntry>> loadDay(String uid, String dateKey);

  /// 같은 id가 있으면 덮어씁니다 (용량을 고쳤을 때).
  Future<void> save(String uid, WaterEntry entry);

  Future<void> delete(String uid, String entryId);

  /// 이 계정의 물 기록을 전부 지웁니다 (계정 삭제 때 사용).
  Future<void> deleteAll(String uid);
}

/// 저장 형식. 날짜와 시각도 문서 안에 함께 넣어 두어, 날짜로 골라 불러올 수 있게 합니다.
Map<String, Object?> waterToMap(WaterEntry e) => {
  'ml': e.ml,
  'time': e.time,
  'dateKey': e.dateKey,
};

/// 저장된 값에서 복원합니다. 타입이 예상과 달라도 앱이 멈추지 않게 기본값을 씁니다.
WaterEntry waterFromMap(
  String id,
  Map<String, Object?> map, {
  required String userId,
}) {
  final ml = map['ml'];
  return WaterEntry(
    id: id,
    userId: userId,
    ml: ml is num ? ml.toInt() : 0,
    dateKey: map['dateKey'] is String ? map['dateKey'] as String : '',
    time: map['time'] is String ? map['time'] as String : '',
  );
}

/// 마신 순서 — 기록 id에 만든 시각이 들어 있어서 id 순서가 곧 시간 순서입니다.
int compareWaterOrder(WaterEntry a, WaterEntry b) => a.id.compareTo(b.id);

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
