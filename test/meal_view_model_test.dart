import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/record/viewmodel/meal_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_project/data/repositories/impl/memory_record_repository.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';

/// 저장이 항상 실패하는 저장소 — 저장 실패 알림을 확인하는 데 쓴다.
class _FailingRepo extends MemoryRecordRepository<MealLog> {
  _FailingRepo() : super(mealCodec);

  @override
  Future<void> save(String uid, MealLog entry) async =>
      throw Exception('network down');
}

MealLog _meal(String id, String dateKey, {String userId = User.meId}) =>
    MealLog(
      id: id,
      userId: userId,
      mealType: MealType.lunch,
      name: '테스트 식사',
      meta: '',
      kcal: 300,
      dateKey: dateKey,
    );

void main() {
  final now = DateTime(2026, 10, 18, 12);
  const today = '2026-10-18';

  MealViewModel build({RecordRepository<MealLog>? repo}) => MealViewModel(
    mealRepo: repo ?? MemoryRecordRepository(mealCodec),
    now: () => now,
  );

  group('MealViewModel', () {
    test('처음에는 오늘 4건과 지난 6일치 예시 식단을 가진다', () {
      final vm = build();
      expect(vm.todayMeals, hasLength(4));
      expect(vm.mealsOn('2026-10-17'), hasLength(3)); // 어제
      expect(vm.mealsOn('2026-10-12'), hasLength(3)); // 6일 전
      expect(vm.mealsOn('2026-10-11'), isEmpty); // 7일 전부터는 없다
    });

    test('예시 점심 이름은 고정이다', () {
      final vm = build();
      final lunch = vm.todayMeals.firstWhere((m) => m.id == 'meal_seed_lunch');
      expect(lunch.name, '현미밥 · 닭가슴살 도시락');
    });

    test('addMeal은 목록에 더하고 알린다', () {
      final vm = build();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.addMeal(_meal('m_new', today));

      expect(vm.todayMeals.map((m) => m.id), contains('m_new'));
      expect(notified, 1);
    });

    test('로그인 전(데모)에는 서버에 저장하지 않고, 로그인하면 저장한다', () async {
      final repo = MemoryRecordRepository(mealCodec);
      final vm = build(repo: repo);

      vm.addMeal(_meal('m_demo', today));
      await Future<void>.delayed(Duration.zero);
      expect(await repo.loadAll('uid_1'), isEmpty);

      vm.uid = 'uid_1';
      vm.addMeal(_meal('m_real', today, userId: 'uid_1'));
      await Future<void>.delayed(Duration.zero);
      expect((await repo.loadAll('uid_1')).map((m) => m.id), ['m_real']);
    });

    test('다른 사용자의 식단은 보이지 않는다', () {
      final vm = build();
      vm.addMeal(_meal('m_other', today, userId: 'someone_else'));
      expect(vm.todayMeals.map((m) => m.id), isNot(contains('m_other')));
    });

    test('clear는 예시 기록을 모두 비운다', () {
      final vm = build()..clear();
      expect(vm.todayMeals, isEmpty);
      expect(vm.mealLogs, isEmpty);
    });

    test('mergeLoaded는 이미 있는 기록을 중복해서 넣지 않는다', () {
      final vm = build()..clear();
      vm.mergeLoaded([_meal('a', today), _meal('b', today)]);
      vm.mergeLoaded([_meal('b', today), _meal('c', today)]);
      expect(vm.mealLogs.map((m) => m.id), ['a', 'b', 'c']);
    });

    test('mealById는 id로 찾고, 없거나 null이면 null이다', () {
      final vm = build();
      expect(vm.mealById('meal_seed_breakfast')?.name, '오트밀 · 바나나');
      expect(vm.mealById('없는 id'), isNull);
      expect(vm.mealById(null), isNull);
    });

    test('저장이 실패하면 onSaveFailed로 알린다', () async {
      final vm = build(repo: _FailingRepo())..uid = 'uid_1';
      var failed = 0;
      vm.onSaveFailed = () => failed++;

      vm.addMeal(_meal('m_fail', today, userId: 'uid_1'));
      await Future<void>.delayed(Duration.zero);

      expect(failed, 1);
      // 저장이 실패해도 화면의 목록에는 남는다.
      expect(vm.mealLogs.map((m) => m.id), contains('m_fail'));
    });
  });
}
