import 'enums.dart';

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

/// 운동을 저장하기 전 입력하는 값입니다.
class ExerciseDraft {
  ExerciseDraft({
    this.type = '달리기',
    this.minutes = 30,
    this.intensity = ExerciseIntensity.moderate,
  });

  String type;
  int minutes;
  ExerciseIntensity intensity;
}

/// 챌린지를 만들기 전 입력하는 값입니다.
class ChallengeDraft {
  ChallengeDraft({
    this.type = ChallengeType.water,
    this.dailyTarget = 2000,
    this.durationDays = 14,
    this.visibility = ChallengeVisibility.private,
    this.reward = ChallengeReward.plantExperience,
    List<String>? invitedUserIds,
  }) : invitedUserIds = invitedUserIds ?? [];

  ChallengeType type;
  int dailyTarget;
  int durationDays;
  ChallengeVisibility visibility;
  ChallengeReward reward;
  List<String> invitedUserIds;
}
