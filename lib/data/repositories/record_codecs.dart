import 'package:diet_project/domain/models/models.dart';

import 'record_repository.dart';

// 저장된 값의 타입이 예상과 달라도(직접 고친 문서 등) 앱이 멈추지 않게, 타입이 맞을 때만 씁니다.
String _str(Object? v, [String fallback = '']) => v is String ? v : fallback;
int _int(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
double _dbl(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : fallback;
bool _bool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;
Map<String, Object?> _map(Object? v) =>
    v is Map ? v.cast<String, Object?>() : const {};

/// 체중 기록 — users/{uid}/weight
final weightCodec = RecordCodec<WeightEntry>(
  idOf: (e) => e.id,
  dateKeyOf: (e) => e.dateKey,
  toMap: (e) => {'kg': e.kg, 'time': e.time, 'dateKey': e.dateKey},
  fromMap: (id, m, uid) => WeightEntry(
    id: id,
    userId: uid,
    kg: _dbl(m['kg']),
    dateKey: _str(m['dateKey']),
    time: _str(m['time']),
  ),
);

/// 운동 기록 — users/{uid}/exercise
final exerciseCodec = RecordCodec<ExerciseLog>(
  idOf: (e) => e.id,
  dateKeyOf: (e) => e.dateKey,
  toMap: (e) => {
    'type': e.type,
    'minutes': e.minutes,
    'intensity': e.intensity.name,
    'kcal': e.kcal,
    'dateKey': e.dateKey,
    'time': e.time,
  },
  fromMap: (id, m, uid) => ExerciseLog(
    id: id,
    userId: uid,
    type: _str(m['type']),
    minutes: _int(m['minutes']),
    intensity:
        ExerciseIntensity.values.asNameMap()[m['intensity']] ??
        ExerciseIntensity.moderate,
    kcal: _int(m['kcal']),
    dateKey: _str(m['dateKey']),
    time: _str(m['time']),
  ),
);

/// 식단 기록 — users/{uid}/meals
final mealCodec = RecordCodec<MealLog>(
  idOf: (e) => e.id,
  dateKeyOf: (e) => e.dateKey,
  toMap: (e) => {
    'mealType': e.mealType.name,
    'name': e.name,
    'meta': e.meta,
    'kcal': e.kcal,
    'dateKey': e.dateKey,
    'bowlId': e.bowlId,
    'sauce': e.sauce,
    'needsReview': e.needsReview,
    'proteinG': e.proteinG,
    'carbG': e.carbG,
    'fatG': e.fatG,
    'fiberG': e.fiberG,
    'sodiumMg': e.sodiumMg,
    'sugarG': e.sugarG,
    'calciumMg': e.calciumMg,
    'ironMg': e.ironMg,
  },
  fromMap: (id, m, uid) => MealLog(
    id: id,
    userId: uid,
    mealType: MealType.values.asNameMap()[m['mealType']] ?? MealType.lunch,
    name: _str(m['name']),
    meta: _str(m['meta']),
    kcal: _int(m['kcal']),
    dateKey: _str(m['dateKey']),
    bowlId: m['bowlId'] is String ? m['bowlId'] as String : null,
    sauce: _str(m['sauce']),
    needsReview: _bool(m['needsReview']),
    proteinG: _dbl(m['proteinG']),
    carbG: _dbl(m['carbG']),
    fatG: _dbl(m['fatG']),
    fiberG: _dbl(m['fiberG']),
    sodiumMg: _dbl(m['sodiumMg']),
    sugarG: _dbl(m['sugarG']),
    calciumMg: _dbl(m['calciumMg']),
    ironMg: _dbl(m['ironMg']),
  ),
);

/// 그릇 — users/{uid}/bowls (날짜 없음)
final bowlCodec = RecordCodec<Bowl>(
  idOf: (e) => e.id,
  dateKeyOf: (_) => '',
  toMap: (e) => {
    'name': e.name,
    'capacityMl': e.capacityMl,
    'portion': e.portion,
    'material': e.material,
    'shape': e.shape,
    'memo': e.memo,
    'isDefault': e.isDefault,
    'icon': e.icon,
  },
  fromMap: (id, m, uid) => Bowl(
    id: id,
    userId: uid,
    name: _str(m['name']),
    capacityMl: _int(m['capacityMl'], 400),
    portion: _str(m['portion']),
    material: _str(m['material']),
    shape: _str(m['shape']),
    memo: _str(m['memo']),
    isDefault: _bool(m['isDefault']),
    icon: _str(m['icon'], '🥣'),
  ),
);

/// 운동 루틴 — users/{uid}/routines (날짜 없음)
final routineCodec = RecordCodec<Routine>(
  idOf: (e) => e.id,
  dateKeyOf: (_) => '',
  toMap: (e) => {
    'name': e.name,
    'type': e.type,
    'minutes': e.minutes,
    'intensity': e.intensity.name,
    'icon': e.icon,
    'used': e.used,
    'weeklyUsed': e.weeklyUsed,
  },
  fromMap: (id, m, uid) => Routine(
    id: id,
    userId: uid,
    name: _str(m['name']),
    type: _str(m['type']),
    minutes: _int(m['minutes'], 30),
    intensity:
        ExerciseIntensity.values.asNameMap()[m['intensity']] ??
        ExerciseIntensity.moderate,
    icon: _str(m['icon'], '💪'),
    used: _int(m['used']),
    weeklyUsed: _int(m['weeklyUsed']),
  ),
);

/// 식물 상태 — users/{uid}/plant/state (계정마다 문서 하나)
const plantDocId = 'state';

Map<String, int> _intMap(Object? v) => {
  for (final e in _map(v).entries)
    if (e.value is num) e.key: (e.value as num).toInt(),
};

final plantCodec = RecordCodec<Plant>(
  idOf: (_) => plantDocId,
  dateKeyOf: (_) => '',
  toMap: (p) => {
    'speciesId': p.speciesId,
    'exp': p.exp,
    'axisScore': {for (final e in p.axisScore.entries) e.key.name: e.value},
    'cares': p.cares,
    'missedDays': p.missedDays,
    'revived': p.revived,
    'wateredFriendIds': p.wateredFriendIds,
    'inventory': p.inventory,
    'giftTickets': p.giftTickets,
  },
  fromMap: (id, m, uid) {
    final starter = Plant.starter(uid);
    final axis = _intMap(m['axisScore']);
    final friends = m['wateredFriendIds'];
    return Plant(
      userId: uid,
      speciesId: _str(m['speciesId'], starter.speciesId),
      exp: _int(m['exp']),
      axisScore: {for (final a in PlantAxis.values) a: axis[a.name] ?? 0},
      cares: {...starter.cares, ..._intMap(m['cares'])},
      missedDays: _int(m['missedDays']),
      revived: _bool(m['revived']),
      wateredFriendIds: friends is List
          ? [
              for (final f in friends)
                if (f is String) f,
            ]
          : <String>[],
      inventory: {...starter.inventory, ..._intMap(m['inventory'])},
      giftTickets: _int(m['giftTickets']),
    );
  },
);

/// 도감 수집 상태 — users/{uid}/dexEntries/{종 id}
final dexEntryCodec = RecordCodec<DexEntry>(
  idOf: (e) => e.speciesId,
  dateKeyOf: (_) => '',
  toMap: (e) => {'owned': e.owned, 'progress': e.progress},
  fromMap: (id, m, uid) => DexEntry(
    userId: uid,
    speciesId: id,
    owned: _bool(m['owned']),
    progress: _int(m['progress']),
  ),
);
