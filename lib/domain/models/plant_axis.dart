/// 식물 성장의 세 축. Plant.axisScore의 키이고, Mission이 어느 축과 이어지는지도
/// 이 값으로 가리킵니다. (문자열로 들고 있으면 'water'와 '물'처럼 표기가 갈라져
/// 서로 다른 축으로 취급되기 때문에 enum으로 고정합니다.)
enum PlantAxis {
  water('물'),
  sun('햇빛'),
  nutri('영양');

  const PlantAxis(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
