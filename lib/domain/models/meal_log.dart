import 'package:diet_project/domain/models/meal_type.dart';

/// 식단 기록
class MealLog {
  const MealLog({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.name,
    required this.meta,
    required this.kcal,
    required this.dateKey,
    this.bowlId,
    this.sauce = '',
    this.needsReview = false,
    this.proteinG = 0,
    this.carbG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.sodiumMg = 0,
    this.sugarG = 0,
    this.calciumMg = 0,
    this.ironMg = 0,
  });

  final String id;
  final String userId;

  /// 끼니 종류는 enum으로 보관하고, 화면은 기존처럼 `type` 문구를 읽습니다.
  final MealType mealType;
  String get type => mealType.label;
  final String name;
  final String meta;
  final int kcal;
  final String dateKey;
  final String? bowlId;

  /// 부가 정보 입력에서 고른 소스/양념 — 리포트의 "자주 쓴 소스" 통계에 쓴다.
  final String sauce;
  final bool needsReview;

  /// AI 사진 분석이 추정한 영양소. 분석 없이 기록했으면(예: 대체값 450kcal로
  /// 그냥 저장) 전부 0이다 — 영양소 합계 화면에서는 그만큼 실제보다 적게 잡힌다.
  final double proteinG;
  final double carbG;
  final double fatG;
  final double fiberG;
  final double sodiumMg;
  final double sugarG;
  final double calciumMg;
  final double ironMg;

  /// 사용자가 고칠 수 있는 값만 바꾼 새 기록을 만든다. 나머지(영양소 · 그릇 · 날짜 …)는 그대로다.
  MealLog copyWith({
    MealType? mealType,
    String? name,
    int? kcal,
    bool? needsReview,
  }) => MealLog(
    id: id,
    userId: userId,
    mealType: mealType ?? this.mealType,
    name: name ?? this.name,
    meta: meta,
    kcal: kcal ?? this.kcal,
    dateKey: dateKey,
    bowlId: bowlId,
    sauce: sauce,
    needsReview: needsReview ?? this.needsReview,
    proteinG: proteinG,
    carbG: carbG,
    fatG: fatG,
    fiberG: fiberG,
    sodiumMg: sodiumMg,
    sugarG: sugarG,
    calciumMg: calciumMg,
    ironMg: ironMg,
  );
}
