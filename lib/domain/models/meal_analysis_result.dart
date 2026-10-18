/// 식사 사진을 AI가 분석한 결과 — 음식 이름 · 칼로리 · 영양소 추정값.
class MealAnalysisResult {
  const MealAnalysisResult({
    required this.name,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.fiberG,
    required this.sodiumMg,
    required this.sugarG,
    required this.calciumMg,
    required this.ironMg,
    required this.confidence,
    required this.needsReview,
  });

  final String name;
  final int kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double fiberG;
  final double sodiumMg;
  final double sugarG;
  final double calciumMg;
  final double ironMg;
  final double confidence;
  final bool needsReview;
}
