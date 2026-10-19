import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/report_settings/viewmodel/report_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_project/app_composition.dart';

/// 2026-10-18(일요일)을 "오늘"로 고정한다.
/// 주간 = 10/12(월) ~ 10/18(일), 지난주 = 10/5 ~ 10/11, 월간 = 10/1 ~ 10/18, 지난달 = 9월 전체.
final _today = DateTime(2026, 10, 18);

MealLog _meal(
  String dateKey, {
  int kcal = 500,
  String name = '식사',
  String? bowlId,
  String sauce = '',
  double protein = 0,
  double carb = 0,
  double fat = 0,
  double fiber = 0,
  double sodium = 0,
  double sugar = 0,
  double calcium = 0,
  double iron = 0,
}) => MealLog(
  id: 'm_${dateKey}_$name${bowlId ?? ''}$sauce$kcal',
  userId: User.meId,
  mealType: MealType.lunch,
  name: name,
  meta: '',
  kcal: kcal,
  dateKey: dateKey,
  bowlId: bowlId,
  sauce: sauce,
  proteinG: protein,
  carbG: carb,
  fatG: fat,
  fiberG: fiber,
  sodiumMg: sodium,
  sugarG: sugar,
  calciumMg: calcium,
  ironMg: iron,
);

ExerciseLog _exercise(String dateKey, int minutes) => ExerciseLog(
  id: 'e_${dateKey}_$minutes',
  userId: User.meId,
  type: '달리기',
  minutes: minutes,
  intensity: ExerciseIntensity.moderate,
  kcal: 100,
  dateKey: dateKey,
  time: '07:00',
);

WeightEntry _weight(String dateKey, double kg) => WeightEntry(
  id: 'w_$dateKey',
  userId: User.meId,
  kg: kg,
  dateKey: dateKey,
  time: '07:00',
);

Bowl _bowl(String id, String name) => Bowl(
  id: id,
  userId: User.meId,
  name: name,
  capacityMl: 500,
  portion: '1인분',
  material: '플라스틱',
  shape: '원형',
);

void main() {
  var meals = <MealLog>[];
  var exercises = <ExerciseLog>[];
  var weights = <WeightEntry>[];
  var bowls = <Bowl>[];
  var dailyTarget = 2000;
  var fallbackKg = 70.0;

  late ReportViewModel vm;

  setUp(() {
    meals = [];
    exercises = [];
    weights = [];
    bowls = [];
    dailyTarget = 2000;
    fallbackKg = 70.0;
    vm = ReportViewModel(
      inputs: () => ReportInputs(
        today: _today,
        meals: meals,
        exercises: exercises,
        weights: weights,
        fallbackWeightKg: fallbackKg,
        dailyTarget: dailyTarget,
        bowls: bowls,
        hasRecordOn: (d) {
          final key = AppState.dateKeyOf(d);
          return meals.any((m) => m.dateKey == key) ||
              exercises.any((e) => e.dateKey == key) ||
              weights.any((w) => w.dateKey == key);
        },
      ),
    );
  });

  group('ReportViewModel · 기간', () {
    test('처음에는 주간이고, 바꾸면 알린다', () {
      var notified = 0;
      vm.addListener(() => notified++);
      expect(vm.period, '주간');

      vm.setPeriod('월간');

      expect(vm.period, '월간');
      expect(notified, 1);
    });

    test('주간은 하루씩 7칸, 요일 이름으로 보여 준다', () {
      final bars = vm.kcalBars;

      expect(bars, hasLength(7));
      expect(bars.map((b) => b.label), ['월', '화', '수', '목', '금', '토', '일']);
    });

    test('월간은 1일부터 오늘까지를 7일씩 묶어 "n주"로 보여 준다', () {
      vm.setPeriod('월간');

      final bars = vm.kcalBars;
      expect(bars.map((b) => b.label), ['1주', '2주', '3주']); // 18일 = 7 + 7 + 4
    });

    test('기록 목표 일수는 주간 5일, 월간 20일이다', () {
      expect(vm.recordGoalDays, 5);
      vm.setPeriod('월간');
      expect(vm.recordGoalDays, 20);
    });
  });

  group('ReportViewModel · 칼로리', () {
    test('하루 평균 칼로리와 목표 대비 비율(최대 100%)을 계산한다', () {
      meals = [
        _meal('2026-10-18', kcal: 1000),
        _meal('2026-10-17', kcal: 6000),
      ];

      final bars = vm.kcalBars;
      expect(bars.last.value, 1000); // 일
      expect(bars.last.pct, 50);
      expect(bars[5].value, 6000); // 토
      expect(bars[5].pct, 100); // 넘어도 100%에서 멈춘다
      expect(bars.first.value, 0);
      expect(vm.avgKcal, '1,000'); // (1000 + 6000) / 7
    });

    test('월간 막대는 그 주의 하루 평균이다', () {
      vm.setPeriod('월간');
      meals = [_meal('2026-10-01', kcal: 700), _meal('2026-10-02', kcal: 700)];

      expect(vm.kcalBars.first.value, 200); // 1400 / 7일
      expect(vm.kcalBars[1].value, 0);
    });

    test('권장 칼로리가 0이면 비율은 0이다', () {
      dailyTarget = 0;
      meals = [_meal('2026-10-18', kcal: 1000)];

      expect(vm.kcalBars.last.pct, 0);
      expect(vm.achieveRate, 0);
    });

    test('지난주 기록이 없으면 비교하지 않는다', () {
      meals = [_meal('2026-10-18', kcal: 1000)];

      expect(vm.periodDelta, '지난주 기록이 없어요');
      vm.setPeriod('월간');
      expect(vm.periodDelta, '지난달 기록이 없어요');
    });

    test('지난주와 비교해 늘었는지 줄었는지 보여 준다', () {
      meals = [
        _meal('2026-10-08', kcal: 700), // 지난주 하루 평균 100
        _meal('2026-10-18', kcal: 1400), // 이번주 하루 평균 200
      ];
      expect(vm.periodDelta, '지난주 대비 +100kcal');

      meals = [_meal('2026-10-08', kcal: 1400), _meal('2026-10-18', kcal: 700)];
      expect(vm.periodDelta, '지난주 대비 -100kcal');

      meals = [_meal('2026-10-08', kcal: 700), _meal('2026-10-18', kcal: 700)];
      expect(vm.periodDelta, '지난주과 비슷해요');
    });

    test('월간 비교 대상은 지난달 전체다', () {
      vm.setPeriod('월간');
      meals = [
        _meal('2026-09-15', kcal: 3000), // 9월 30일로 나누면 100
        _meal('2026-10-18', kcal: 3600), // 10월 18일로 나누면 200
      ];

      expect(vm.periodDelta, '지난달 대비 +100kcal');
    });

    test('달성률은 기록한 날 중 권장 칼로리 이하로 먹은 날의 비율이다', () {
      meals = [
        _meal('2026-10-18', kcal: 1800), // 달성
        _meal('2026-10-17', kcal: 2000), // 달성(목표 이하)
        _meal('2026-10-16', kcal: 2500), // 초과
        // 나머지 4일은 기록이 없어서 달성으로 치지 않는다.
      ];

      expect(vm.achieveRate, 29); // 2 / 7
    });
  });

  group('ReportViewModel · 운동 · 기록 일수', () {
    test('하루 평균 운동 시간과 지난주 대비 증감을 계산한다', () {
      exercises = [
        _exercise('2026-10-18', 70), // 이번주 평균 10분
        _exercise('2026-10-08', 35), // 지난주 평균 5분
      ];

      expect(vm.avgExerciseMin, 10);
      expect(vm.exerciseMinDelta, 5);
    });

    test('기록이 없으면 모두 0이다', () {
      expect(vm.avgExerciseMin, 0);
      expect(vm.exerciseMinDelta, 0);
      expect(vm.recordDays, 0);
      expect(vm.achieveRate, 0);
    });

    test('기록한 날 수는 식단 · 운동 · 체중 중 하나라도 있는 날을 센다', () {
      meals = [_meal('2026-10-18')];
      exercises = [_exercise('2026-10-17', 30)];
      weights = [_weight('2026-10-16', 60)];
      meals.add(_meal('2026-10-18', name: '간식')); // 같은 날 두 번이어도 하루

      expect(vm.recordDays, 3);
    });
  });

  group('ReportViewModel · 체중', () {
    test('기록이 없는 날은 그 전 체중을 이어서 보여 준다', () {
      weights = [_weight('2026-10-13', 65), _weight('2026-10-16', 64)];

      final series = vm.weightSeries;
      expect(series.map((p) => p.label).first, '10/12');
      expect(series.map((p) => p.kg), [
        65, // 10/12: 이전 기록이 없어 가장 이른 기록(10/13)으로 채운다
        65,
        65,
        65,
        64,
        64,
        64,
      ]);
    });

    test('체중 기록이 하나도 없으면 프로필 체중을 쓴다', () {
      fallbackKg = 72.5;

      expect(vm.weightSeries.every((p) => p.kg == 72.5), isTrue);
    });

    test('월간은 그 주 마지막 날 기준 체중을 "n주"로 보여 준다', () {
      vm.setPeriod('월간');
      weights = [_weight('2026-10-03', 66), _weight('2026-10-09', 65)];

      final series = vm.weightSeries;
      expect(series.map((p) => p.label), ['1주', '2주', '3주']);
      expect(series.map((p) => p.kg), [66, 65, 65]);
    });
  });

  group('ReportViewModel · 가장 많이 한 것', () {
    test('기록이 없으면 안내 문구를 보여 준다', () {
      expect(vm.mostEatenFood, '기록된 식단이 없어요');
      expect(vm.mostUsedBowl, '사용한 그릇이 없어요');
      expect(vm.mostUsedSauce, '기록된 소스가 없어요');
      expect(vm.lackingNutrient, '기록된 식단이 없어요');
      expect(vm.recommendedMeal, contains('아직 기록된 식단이 없어요'));
    });

    test('가장 많이 먹은 음식 · 그릇 · 소스와 횟수를 보여 준다', () {
      bowls = [_bowl('b1', '회사 도시락'), _bowl('b2', '집 밥그릇')];
      meals = [
        _meal('2026-10-18', name: '비빔밥', bowlId: 'b1', sauce: '고추장'),
        _meal('2026-10-17', name: '비빔밥', bowlId: 'b1', sauce: '고추장'),
        _meal('2026-10-16', name: '샐러드', bowlId: 'b2', sauce: '발사믹'),
      ];

      expect(vm.mostEatenFood, '비빔밥 · 2회');
      expect(vm.mostUsedBowl, '회사 도시락 · 2회');
      expect(vm.mostUsedSauce, '고추장 · 2회');
    });

    test('지운 그릇은 "삭제된 그릇"으로 보여 준다', () {
      meals = [_meal('2026-10-18', bowlId: 'gone')];

      expect(vm.mostUsedBowl, '삭제된 그릇 · 1회');
    });

    test('기간 밖의 기록은 세지 않는다', () {
      meals = [_meal('2026-10-11', name: '지난주 음식')]; // 주간 범위 밖

      expect(vm.mostEatenFood, '기록된 식단이 없어요');
      vm.setPeriod('월간');
      expect(vm.mostEatenFood, '지난주 음식 · 1회');
    });
  });

  group('ReportViewModel · 부족한 영양소', () {
    test('가장 낮은 영양소와 그에 맞는 추천 문구를 보여 준다', () {
      // 단백질만 채우고 나머지는 0 → 가장 먼저 0%인 탄수화물이 부족.
      meals = [_meal('2026-10-18', protein: 700)];

      expect(vm.lackingNutrient, '탄수화물 -100%');
      expect(vm.recommendedMeal, contains('탄수화물이 부족해요'));
    });

    test('모든 영양소가 목표를 채우면 부족한 영양소가 없다', () {
      meals = [
        _meal(
          '2026-10-18',
          protein: 700,
          carb: 1540,
          fat: 420,
          fiber: 175,
          sodium: 14000,
          sugar: 350,
          calcium: 4900,
          iron: 98,
        ),
      ];

      expect(vm.lackingNutrient, '부족한 영양소가 없어요');
      expect(vm.recommendedMeal, contains('골고루 채웠어요'));
    });
  });

  group('AppState 연결', () {
    test('리포트 화면에 들어가면 주간으로 돌아온다', () {
      final s = AppState(dependencies: memoryDependencies(now: () => _today));
      s.setPeriod('월간');

      s.navigationViewModel.go('report');

      expect(s.period, '주간');
    });

    test('기간을 바꾸면 화면이 구독하는 ViewModel에 전달된다', () {
      final s = AppState(dependencies: memoryDependencies(now: () => _today));
      var notified = 0;
      s.reportViewModel.addListener(() => notified++);

      s.setPeriod('월간');

      expect(notified, 1);
      expect(s.period, '월간');
    });

    test('예시 계정의 최근 7일 기록이 리포트에 집계된다', () {
      final s = AppState(dependencies: memoryDependencies(now: () => _today));

      expect(s.kcalBars, hasLength(7));
      expect(s.recordDays, 7);
      expect(s.mostEatenFood, isNot('기록된 식단이 없어요'));
    });

    test('식단을 기록하면 리포트의 오늘 막대가 바뀐다', () {
      final s = AppState(dependencies: memoryDependencies(now: () => _today));
      final before = s.kcalBars.last.value;

      s.logMeal();

      expect(s.kcalBars.last.value, greaterThan(before));
    });
  });
}
