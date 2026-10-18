import 'package:diet_project/domain/models/models.dart';

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
