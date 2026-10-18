import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart' show Color;

/// 영양소 하나의 오늘 합계 — 목표 대비 비율과 끼니별 분해까지 담는다.
class NutrientStat {
  const NutrientStat({
    required this.name,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  final String name;
  final String unit;
  final double value;
  final double target;
  final Color color;
  final double breakfast;
  final double lunch;
  final double dinner;
  final double snack;

  int get pct => target <= 0 ? 0 : (value / target * 100).round();

  /// 80% 이상이면 "적정", 그 아래면 "부족"으로 본다 — 간단한 기준이라
  /// 100%를 초과해도 "적정"으로 표시된다(초과 자체를 경고로 다루진 않는다).
  bool get isLow => pct < 80;
}

/// 홈과 영양소 상세 화면이 보여주는 "오늘" 수치 — 먹은 칼로리 · 남은 칼로리 ·
/// 영양소 합계 · 3대 영양소 비율을 오늘의 식단에서 계산한다.
///
/// target(하루 권장치)은 성별 · 체중 등에 맞춘 개인화 목표가 아니라 일반
/// 성인 기준 고정값이다 — 개인 맞춤 목표는 별도 기능으로 남겨둔다.
/// 사진 분석 없이 저장한 식단(예: 분석 실패 후 대체값 450kcal로 저장)은
/// 영양소가 전부 0으로 잡혀서, 그만큼 실제보다 적게 보일 수 있다.
class TodaySummary {
  const TodaySummary({required this.meals, required this.dailyTarget});

  /// 고정된 오늘 날짜의 식단 (기록 탭에서 넘겨보는 날짜와는 무관하다).
  final List<MealLog> meals;
  final int dailyTarget;

  int get intakeKcal => meals.fold(0, (sum, m) => sum + m.kcal);
  int get remainKcal => dailyTarget - intakeKcal;
  double get intakeRatio =>
      dailyTarget > 0 ? (intakeKcal / dailyTarget).clamp(0.0, 1.0) : 0.0;

  static const _colors = <String, Color>{
    '단백질': AppColor.primary,
    '탄수화물': AppColor.warn,
    '지방': AppColor.warnDeep,
    '식이섬유': AppColor.teal,
    '나트륨': AppColor.alert,
    '당류': Color(0xFFF48FB1),
    '칼슘': Color(0xFF90A4EE),
    '철분': Color(0xFFB08BE0),
  };

  double _sum(double Function(MealLog) pick, [MealType? type]) => meals
      .where((m) => type == null || m.mealType == type)
      .fold(0.0, (a, m) => a + pick(m));

  /// 8종 영양소 오늘 합계 — 홈 카드(위 5개)와 영양소 상세 화면(전체)에서 같이 쓴다.
  List<NutrientStat> get nutrientStats => [
    for (final (:name, :unit, :target) in Nutrients.all)
      NutrientStat(
        name: name,
        unit: unit,
        target: target,
        color: _colors[name]!,
        value: _sum(Nutrients.pick(name)),
        breakfast: _sum(Nutrients.pick(name), MealType.breakfast),
        lunch: _sum(Nutrients.pick(name), MealType.lunch),
        dinner: _sum(Nutrients.pick(name), MealType.dinner),
        snack: _sum(Nutrients.pick(name), MealType.snack),
      ),
  ];

  double get proteinG => _sum(Nutrients.pick('단백질'));
  double get carbG => _sum(Nutrients.pick('탄수화물'));
  double get fatG => _sum(Nutrients.pick('지방'));

  /// 3대 영양소가 각각 오늘 칼로리에서 차지하는 비율(%). 기록이 없으면 0.
  ({int proteinPct, int carbPct, int fatPct}) get macroRatio {
    final proteinKcal = proteinG * 4;
    final carbKcal = carbG * 4;
    final fatKcal = fatG * 9;
    final total = proteinKcal + carbKcal + fatKcal;
    if (total <= 0) return (proteinPct: 0, carbPct: 0, fatPct: 0);
    return (
      proteinPct: (proteinKcal / total * 100).round(),
      carbPct: (carbKcal / total * 100).round(),
      fatPct: (fatKcal / total * 100).round(),
    );
  }
}
