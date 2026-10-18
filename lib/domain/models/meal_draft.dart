import 'package:diet_project/domain/models/bowl_fill_level.dart';
import 'package:diet_project/domain/models/meal_context.dart';
import 'package:diet_project/domain/models/meal_type.dart';
import 'package:diet_project/domain/models/portion_size.dart';

/// 식단을 저장하기 전, 기록 화면에서만 유지하는 입력값입니다.
class MealDraft {
  MealDraft({
    this.name = '',
    this.mealType = MealType.lunch,
    this.context = MealContext.lunchbox,
    this.portion = PortionSize.full,
    this.fillLevel = BowlFillLevel.full,
    this.portionPercent = 100,
    this.proteinType,
    this.sauce,
    this.cookingMethod,
    this.carbohydrateType,
    this.customMealTypeLabel,
    this.customContextLabel,
    this.bowlId,
    List<String>? tags,
    this.memo = '',
  }) : tags = tags ?? [];

  String name;
  MealType mealType;
  MealContext context;
  PortionSize portion;
  BowlFillLevel fillLevel;
  int portionPercent;
  String? proteinType;
  String? sauce;
  String? cookingMethod;
  String? carbohydrateType;
  String? customMealTypeLabel;
  String? customContextLabel;
  String? bowlId;
  List<String> tags;
  String memo;
}
