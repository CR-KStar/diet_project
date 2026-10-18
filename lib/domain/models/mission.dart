import 'package:diet_project/domain/models/plant_axis.dart';

/// 오늘의 미션
class Mission {
  const Mission({
    required this.id,
    required this.category,
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
    required this.exp,
    required this.axis,
    required this.route,
    this.special,
  });

  final String id;
  final String category;
  final String title;
  final double current;
  final double target;
  final String unit;
  final int exp;

  /// 이 미션이 올려주는 식물 성장 축 (Plant.axisScore의 키)
  final PlantAxis axis;
  final String route;
  final String? special;

  bool get done => current >= target;
  double get ratio => (current / target).clamp(0.0, 1.0);
}
