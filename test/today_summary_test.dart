import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/home/viewmodel/today_summary.dart';
import 'package:flutter_test/flutter_test.dart';

MealLog _meal(
  MealType type,
  int kcal, {
  double protein = 0,
  double carb = 0,
  double fat = 0,
  double sodium = 0,
}) => MealLog(
  id: 'm_${type.name}_$kcal',
  userId: User.meId,
  mealType: type,
  name: '식사',
  meta: '',
  kcal: kcal,
  dateKey: '2026-10-18',
  proteinG: protein,
  carbG: carb,
  fatG: fat,
  sodiumMg: sodium,
);

void main() {
  group('TodaySummary · 칼로리', () {
    test('먹은 칼로리 · 남은 칼로리 · 권장량 대비 비율', () {
      final s = TodaySummary(
        meals: [_meal(MealType.breakfast, 500), _meal(MealType.lunch, 700)],
        dailyTarget: 2000,
      );

      expect(s.intakeKcal, 1200);
      expect(s.remainKcal, 800);
      expect(s.intakeRatio, 0.6);
    });

    test('권장량을 넘기면 남은 칼로리는 음수, 비율은 1.0에서 멈춘다', () {
      final s = TodaySummary(
        meals: [_meal(MealType.dinner, 2500)],
        dailyTarget: 2000,
      );

      expect(s.remainKcal, -500);
      expect(s.intakeRatio, 1.0);
    });

    test('기록이 없으면 0이고, 권장량이 0이면 비율도 0이다', () {
      expect(const TodaySummary(meals: [], dailyTarget: 2000).intakeKcal, 0);
      expect(const TodaySummary(meals: [], dailyTarget: 2000).intakeRatio, 0);
      expect(
        TodaySummary(
          meals: [_meal(MealType.lunch, 500)],
          dailyTarget: 0,
        ).intakeRatio,
        0,
      );
    });
  });

  group('TodaySummary · 영양소', () {
    final summary = TodaySummary(
      meals: [
        _meal(MealType.breakfast, 300, protein: 10, carb: 50, sodium: 100),
        _meal(MealType.lunch, 600, protein: 30, carb: 70, fat: 20, sodium: 900),
        _meal(MealType.lunch, 200, protein: 5),
      ],
      dailyTarget: 2000,
    );

    test('8종을 정해진 순서로, 기준 권장치와 함께 보여 준다', () {
      final stats = summary.nutrientStats;

      expect(stats.map((n) => n.name), [
        '단백질', '탄수화물', '지방', '식이섬유', '나트륨', '당류', '칼슘', '철분', //
      ]);
      expect(stats.first.target, 100);
      expect(stats.first.unit, 'g');
      expect(stats[4].unit, 'mg');
    });

    test('전체 합계와 끼니별 합계를 계산한다', () {
      final protein = summary.nutrientStats.first;

      expect(protein.value, 45);
      expect(protein.breakfast, 10);
      expect(protein.lunch, 35);
      expect(protein.dinner, 0);
      expect(protein.snack, 0);
      expect(protein.pct, 45);
    });

    test('80% 미만이면 부족(isLow)으로 본다', () {
      final stats = {for (final n in summary.nutrientStats) n.name: n};

      expect(stats['단백질']!.isLow, isTrue); // 45%
      expect(stats['나트륨']!.isLow, isTrue); // 1000 / 2000 = 50%
    });

    test('3대 영양소 합계', () {
      expect(summary.proteinG, 45);
      expect(summary.carbG, 120);
      expect(summary.fatG, 20);
    });

    test('3대 영양소가 칼로리에서 차지하는 비율', () {
      // 단백질 180kcal · 탄수화물 480kcal · 지방 180kcal → 총 840
      final ratio = summary.macroRatio;

      expect(ratio.proteinPct, 21);
      expect(ratio.carbPct, 57);
      expect(ratio.fatPct, 21);
    });

    test('영양소 기록이 없으면 비율은 모두 0이다', () {
      final s = TodaySummary(
        meals: [_meal(MealType.lunch, 450)], // 분석 없이 저장한 식단
        dailyTarget: 2000,
      );

      expect(s.macroRatio, (proteinPct: 0, carbPct: 0, fatPct: 0));
      expect(s.nutrientStats.every((n) => n.value == 0), isTrue);
    });
  });

  group('AppState 연결', () {
    test('예시 계정의 오늘 수치가 오늘의 식단 4건으로 계산된다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));

      expect(s.intakeKcal, 320 + 450 + 480 + 200);
      expect(s.remainKcal, s.dailyTarget - s.intakeKcal);
      expect(s.todayNutrientStats, hasLength(8));
      expect(s.todayProteinG, 9 + 28 + 38 + 17);
    });

    test('식단을 기록하면 오늘 수치가 바로 바뀐다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      final before = s.intakeKcal;

      s.logMeal();

      expect(s.intakeKcal, greaterThan(before));
    });

    test('기록 탭에서 다른 날짜를 보고 있어도 오늘 수치는 그대로다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      final before = s.intakeKcal;

      s.selectDay(17);

      expect(s.intakeKcal, before);
    });
  });
}
