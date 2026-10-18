/// 지금까지 남긴 기록의 누적 횟수 — 식물 도감의 "식단 30회", "운동 300분" 같은 조건을 세는 데 쓴다.
///
/// 앱에서 기록을 남길 때마다 하나씩 늘어나고, 줄어들지 않는다(기록을 지워도 이미 모은 것은 그대로다).
/// 이 기능이 생기기 전에 남긴 기록은 세지 않고, 이후부터 센다.
class RecordTally {
  RecordTally({
    this.meals = 0,
    this.breakfasts = 0,
    this.exercises = 0,
    this.exerciseMinutes = 0,
    this.waterEntries = 0,
    this.waterMl = 0,
    this.weights = 0,
    this.bestStreakDays = 0,
  });

  int meals;
  int breakfasts;
  int exercises;
  int exerciseMinutes;
  int waterEntries;
  int waterMl;
  int weights;

  /// 가장 길게 이어 간 연속 기록 일수.
  int bestStreakDays;

  /// 식단 · 운동 · 물 · 체중 기록을 모두 합친 횟수.
  int get totalRecords => meals + exercises + waterEntries + weights;

  RecordTally copy() => RecordTally(
    meals: meals,
    breakfasts: breakfasts,
    exercises: exercises,
    exerciseMinutes: exerciseMinutes,
    waterEntries: waterEntries,
    waterMl: waterMl,
    weights: weights,
    bestStreakDays: bestStreakDays,
  );
}
