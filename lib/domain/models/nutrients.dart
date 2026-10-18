import 'activity_records.dart';

/// 추적하는 영양소 8종의 이름 · 단위 · 하루 권장치와, 식단 한 건에서 그 영양소의 양을 꺼내는 방법.
///
/// 권장치는 성별 · 체중 등에 맞춘 개인화 목표가 아니라 일반 성인 기준 고정값이다.
/// 홈의 영양소 카드와 리포트가 같은 기준을 쓰도록 한곳에 둔다.
abstract final class Nutrients {
  static const all = <({String name, String unit, double target})>[
    (name: '단백질', unit: 'g', target: 100),
    (name: '탄수화물', unit: 'g', target: 220),
    (name: '지방', unit: 'g', target: 60),
    (name: '식이섬유', unit: 'g', target: 25),
    (name: '나트륨', unit: 'mg', target: 2000),
    (name: '당류', unit: 'g', target: 50),
    (name: '칼슘', unit: 'mg', target: 700),
    (name: '철분', unit: 'mg', target: 14),
  ];

  /// [name] 영양소의 양을 식단 한 건에서 꺼내는 함수.
  static double Function(MealLog) pick(String name) => switch (name) {
    '단백질' => (m) => m.proteinG,
    '탄수화물' => (m) => m.carbG,
    '지방' => (m) => m.fatG,
    '식이섬유' => (m) => m.fiberG,
    '나트륨' => (m) => m.sodiumMg,
    '당류' => (m) => m.sugarG,
    '칼슘' => (m) => m.calciumMg,
    _ => (m) => m.ironMg,
  };
}
