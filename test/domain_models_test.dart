import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/ui/record/viewmodel/weight_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Plant · PlantAxis', () {
    final plant = Plant(
      userId: User.meId,
      axisScore: {PlantAxis.water: 82, PlantAxis.sun: 45, PlantAxis.nutri: 68},
      cares: {},
    );

    test('가장 약한 축을 enum으로 돌려준다', () {
      expect(plant.weakestAxis, PlantAxis.sun);
      expect(plant.balanced, isFalse);
    });

    test('안내 문구에는 축의 한글 이름이 들어간다', () {
      expect(plant.balanceHint, contains('햇빛'));
      expect(plant.balanceHint, isNot(contains('sun')));
    });

    test('키우는 종은 speciesId로 카탈로그와 연결된다', () {
      expect(plant.speciesId, 'sp_sprout');
      expect(plant.speciesInfo.name, '새싹');
    });
  });

  group('기록 모델', () {
    test('MealLog는 enum을 보관하고 화면용 문구를 돌려준다', () {
      const log = MealLog(
        id: 'm1',
        userId: User.meId,
        mealType: MealType.dinner,
        name: '샐러드',
        meta: '',
        kcal: 300,
        dateKey: '08-19',
      );
      expect(log.type, '저녁');
    });

    test('Routine.meta는 강도 문구를 보여준다', () {
      final routine = Routine(
        id: 'r1',
        userId: User.meId,
        name: '아침 러닝',
        type: '달리기',
        minutes: 30,
        intensity: ExerciseIntensity.high,
      );
      expect(routine.meta, '달리기 · 30분 · 높음');
    });
  });

  group('AppState.todayRegistry', () {
    test('처음에는 오늘 저장한 운동 · 체중이 없다 (체중 시드는 어제 기록)', () {
      final s = AppState();
      expect(s.todayRegistry.exerciseLogs, isEmpty);
      expect(s.todayRegistry.weightEntry, isNull);
    });

    test('운동과 체중을 저장하면 하루 요약에 합쳐진다', () {
      final weight = WeightViewModel(
        weightRepo: MemoryRecordRepository(weightCodec),
      );
      final s = AppState(weightViewModel: weight)
        ..exType = '달리기'
        ..exMinutes = 30;
      weight.setWeightInput(56.4);
      s.logExercise();
      weight.logWeight();

      final registry = s.todayRegistry;
      expect(registry.userId, User.meId);
      expect(registry.exerciseLogs, hasLength(1));
      expect(registry.totalExerciseMinutes, 30);
      expect(registry.weightEntry?.kg, 56.4);
    });

    test('체중 화면 "최근 7일"은 날짜별로 실제 기록한 체중을 보여준다', () {
      final now = DateTime(2026, 9, 21, 9);
      final weight = WeightViewModel(
        weightRepo: MemoryRecordRepository(weightCodec),
        now: () => now,
      );
      final s = AppState(weightViewModel: weight, now: () => now);

      var days = s.recentWeightDays;
      expect(days, hasLength(7));
      expect(days.last.isToday, isTrue);
      expect(days.last.kg, isNull); // 오늘은 아직 기록 전
      expect(days[5].kg, 56.9); // 어제 = 예시 기록
      expect(days.first.kg, 57.6); // 예시: 6일 전부터 서서히 감소

      weight.setWeightInput(56.4);
      weight.logWeight();
      days = s.recentWeightDays;
      expect(days.last.kg, 56.4);
      expect(days.last.day, 21);
    });

    test('기록 탭에서 다른 날짜를 넘겨봐도 오늘 요약은 그대로다', () {
      final s = AppState(now: () => DateTime(2026, 9, 21));
      final before = s.todayRegistry;

      s.month = 9;
      s.day = 20;
      final after = s.todayRegistry;

      expect(after.dateKey, before.dateKey);
      expect(after.totalIntakeKcal, before.totalIntakeKcal);
      expect(s.intakeKcal, before.totalIntakeKcal);
    });
  });
}
