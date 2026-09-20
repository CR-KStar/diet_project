/// UI 문구와 분리해 고정된 선택지를 안전하게 표현하는 타입입니다.
enum DietGoal { loseWeight, maintainWeight, gainMuscle }

extension DietGoalText on DietGoal {
  String get label => switch (this) {
    DietGoal.loseWeight => '체중 감량',
    DietGoal.maintainWeight => '체중 유지',
    DietGoal.gainMuscle => '근육 증가',
  };
}

enum ActivityLevel { low, moderate, high }

extension ActivityLevelText on ActivityLevel {
  String get label => switch (this) {
    ActivityLevel.low => '적음',
    ActivityLevel.moderate => '보통',
    ActivityLevel.high => '많음',
  };
}

enum Gender { female, male, undisclosed }

extension GenderText on Gender {
  String get label => switch (this) {
    Gender.female => '여성',
    Gender.male => '남성',
    Gender.undisclosed => '공개 안 함',
  };
}
enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeText on MealType {
  String get label => switch (this) {
    MealType.breakfast => '아침',
    MealType.lunch => '점심',
    MealType.dinner => '저녁',
    MealType.snack => '간식',
  };
}

enum MealContext { home, lunchbox, diningOut, delivery, other }

extension MealContextText on MealContext {
  String get label => switch (this) {
    MealContext.home => '집밥',
    MealContext.lunchbox => '도시락',
    MealContext.diningOut => '외식',
    MealContext.delivery => '배달',
    MealContext.other => '기타',
  };
}

enum PortionSize { full, half, third, custom }

extension PortionSizeText on PortionSize {
  String get label => switch (this) {
    PortionSize.full => '전체',
    PortionSize.half => '반절',
    PortionSize.third => '1/3',
    PortionSize.custom => '직접',
  };
}

enum BowlFillLevel { full, half, third }

extension BowlFillLevelText on BowlFillLevel {
  String get label => switch (this) {
    BowlFillLevel.full => '가득',
    BowlFillLevel.half => '반',
    BowlFillLevel.third => '1/3',
  };
}
enum ExerciseIntensity { low, moderate, high }

extension ExerciseIntensityText on ExerciseIntensity {
  String get label => switch (this) {
    ExerciseIntensity.low => '낮음',
    ExerciseIntensity.moderate => '보통',
    ExerciseIntensity.high => '높음',
  };
}
enum ChallengeType { water, exercise, mealRecord, protein }

extension ChallengeTypeText on ChallengeType {
  String get label => switch (this) {
    ChallengeType.water => '물 마시기',
    ChallengeType.exercise => '운동 시간',
    ChallengeType.mealRecord => '식단 기록',
    ChallengeType.protein => '단백질',
  };
}

enum ChallengeReward { plantExperience, badge, none }

extension ChallengeRewardText on ChallengeReward {
  String get label => switch (this) {
    ChallengeReward.plantExperience => '식물 EXP',
    ChallengeReward.badge => '배지',
    ChallengeReward.none => '없음',
  };
}

enum ChallengeVisibility { private, public }
enum ShareScope { private, friends }

extension ShareScopeText on ShareScope {
  String get label => switch (this) {
    ShareScope.private => '비공개',
    ShareScope.friends => '친구만',
  };
}

/// 식물 성장의 세 축. Plant.axisScore의 키이고, Mission이 어느 축과 이어지는지도
/// 이 값으로 가리킵니다. (문자열로 들고 있으면 'water'와 '물'처럼 표기가 갈라져
/// 서로 다른 축으로 취급되기 때문에 enum으로 고정합니다.)
enum PlantAxis { water, sun, nutri }

extension PlantAxisText on PlantAxis {
  String get label => switch (this) {
    PlantAxis.water => '물',
    PlantAxis.sun => '햇빛',
    PlantAxis.nutri => '영양',
  };
}

/// 소셜 로그인 방식. 화면 문구는 label로 읽습니다.
enum LoginProvider { google, apple }

extension LoginProviderText on LoginProvider {
  String get label => switch (this) {
    LoginProvider.google => 'Google',
    LoginProvider.apple => 'Apple',
  };
}
