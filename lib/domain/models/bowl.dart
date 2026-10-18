/// 기록용 템플릿: 그릇
class Bowl {
  Bowl({
    required this.id,
    required this.userId,
    required this.name,
    required this.capacityMl,
    required this.portion,
    required this.material,
    required this.shape,
    this.memo = '',
    this.isDefault = false,
    this.icon = '🥣',
  });

  final String id;
  final String userId;
  String name;
  int capacityMl;
  String portion;
  String material;
  String shape;
  String memo;
  bool isDefault;
  String icon;

  double get capacityFactor =>
      capacityMl >= 800 ? 1.2 : (capacityMl >= 450 ? 1.0 : 0.6);
  String get meta => '$capacityMl ml · $portion · $material';
}
