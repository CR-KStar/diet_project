/// 체중 기록
class WeightEntry {
  WeightEntry({
    required this.id,
    required this.userId,
    required this.kg,
    required this.dateKey,
    required this.time,
  });

  final String id;
  final String userId;
  final double kg;
  final String dateKey;
  final String time;

  WeightEntry copyWith({double? kg}) => WeightEntry(
    id: id,
    userId: userId,
    kg: kg ?? this.kg,
    dateKey: dateKey,
    time: time,
  );
}
