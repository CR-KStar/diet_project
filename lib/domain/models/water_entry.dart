/// 물 섭취 기록
class WaterEntry {
  WaterEntry({
    required this.id,
    required this.userId,
    required this.ml,
    required this.dateKey,
    required this.time,
  });

  final String id;
  final String userId;
  int ml;

  /// 마신 날짜 — 'yyyy-MM-dd'
  final String dateKey;

  /// 마신 시각 — 'HH:mm'
  final String time;
}
