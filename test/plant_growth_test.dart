import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/repositories/impl/memory_record_repository.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/domain/rules/dex_rules.dart';
import 'package:diet_project/ui/growth/viewmodel/plant_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// 식물 성장 규칙 — 기록이 돌보기 · 축 점수 · 시듦 · 도감과 이어지는지 확인한다.
void main() {
  Plant fresh() => Plant.starter('u1');

  group('Plant · 돌보기', () {
    test('돌보기를 누르면 경험치와 그 축 점수가 같은 만큼 오른다', () {
      final p = fresh();

      p.care('물 주기');
      p.care('햇빛 받기');
      p.care('영양 주기');

      expect(p.exp, 10 + 15 + 20);
      expect(p.axisScore[PlantAxis.water], 10);
      expect(p.axisScore[PlantAxis.sun], 15);
      expect(p.axisScore[PlantAxis.nutri], 20);
      expect(p.cares, {'물 주기': 2, '햇빛 받기': 1, '영양 주기': 1});
    });

    test('남은 횟수가 없으면 아무 일도 일어나지 않고, 축 점수는 100을 넘지 않는다', () {
      final p = fresh()
        ..cares['영양 주기'] = 0
        ..axisScore[PlantAxis.water] = 95;

      p.care('영양 주기');
      expect(p.exp, 0);
      expect(p.axisScore[PlantAxis.nutri], 0);

      p.care('물 주기'); // 95 + 10 → 100에서 멈춘다
      expect(p.axisScore[PlantAxis.water], 100);
    });

    test('기록하면 그 기록에 맞는 돌보기가 1회씩 충전된다 (최대 횟수까지)', () {
      final p = fresh()..cares.updateAll((_, _) => 0);

      p.recharge(RecordKind.water);
      p.recharge(RecordKind.exercise);
      p.recharge(RecordKind.meal);
      expect(p.cares, {'물 주기': 1, '햇빛 받기': 1, '영양 주기': 1});

      for (var i = 0; i < 10; i++) {
        p.recharge(RecordKind.water);
        p.recharge(RecordKind.exercise);
        p.recharge(RecordKind.meal);
      }
      expect(p.cares, {'물 주기': 3, '햇빛 받기': 2, '영양 주기': 2});
    });

    test('체중 기록은 돌보기를 충전하지 않는다', () {
      final p = fresh()..cares.updateAll((_, _) => 0);

      p.recharge(RecordKind.weight);

      expect(p.cares.values.every((v) => v == 0), isTrue);
    });

    test('아직 아무 축도 자라지 않았으면 균형이라 부르지 않는다', () {
      final p = fresh();

      expect(p.balanced, isFalse);
      expect(p.balanceHint, contains('돌보기'));

      p.care('물 주기');
      p.care('햇빛 받기');
      expect(p.balanced, isTrue); // 10 / 15 / 0 → 차이 15
      expect(p.balanceHint, contains('골고루'));
    });
  });

  group('DexRules · 도감 조건', () {
    DexContext ctx({
      RecordTally? tally,
      Map<PlantAxis, int>? axis,
      bool onboarded = false,
      int owned = 0,
    }) => DexContext(
      tally: tally ?? RecordTally(),
      axisScore: axis ?? {for (final a in PlantAxis.values) a: 0},
      onboardingDone: onboarded,
      ownedCount: owned,
      totalCount: 18,
    );

    DexProgress at(String id, DexContext c) => DexRules.evaluate(id, c);

    test('기록 횟수 · 누적량 · 연속 일수 조건은 닿으면 완료되고 그 전에는 비율을 보여준다', () {
      expect(at('sp_rose', ctx(tally: RecordTally(meals: 15))).progress, 50);
      expect(at('sp_rose', ctx(tally: RecordTally(meals: 29))).done, isFalse);
      expect(at('sp_rose', ctx(tally: RecordTally(meals: 30))).done, isTrue);
      expect(
        at('sp_daisy', ctx(tally: RecordTally(waterMl: 10000))).done,
        isTrue,
      );
      expect(
        at('sp_cactus', ctx(tally: RecordTally(exercises: 10))).done,
        isTrue,
      );
      expect(
        at('sp_conifer', ctx(tally: RecordTally(exerciseMinutes: 300))).done,
        isTrue,
      );
      expect(at('sp_bamboo', ctx(tally: RecordTally(weights: 5))).done, isTrue);
      expect(
        at('sp_lotus', ctx(tally: RecordTally(waterEntries: 50))).done,
        isTrue,
      );
      expect(
        at('sp_rice', ctx(tally: RecordTally(breakfasts: 10))).done,
        isTrue,
      );
      expect(
        at('sp_monstera', ctx(tally: RecordTally(bestStreakDays: 14))).done,
        isTrue,
      );
    });

    test('첫 기록으로 새싹이, 누적 20회로 고무나무가 열린다', () {
      expect(at('sp_sprout', ctx()).done, isFalse);
      expect(at('sp_sprout', ctx(tally: RecordTally(meals: 1))).done, isTrue);
      expect(
        at(
          'sp_rubber_tree',
          ctx(tally: RecordTally(meals: 10, exercises: 5, weights: 5)),
        ).done,
        isTrue,
      );
    });

    test('시작 안내를 마치면 튤립이, 축 하나가 100이 되면 벚꽃이 열린다', () {
      expect(at('sp_tulip', ctx()).done, isFalse);
      expect(at('sp_tulip', ctx(onboarded: true)).done, isTrue);
      expect(
        at(
          'sp_cherry_blossom',
          ctx(
            axis: {PlantAxis.water: 100, PlantAxis.sun: 0, PlantAxis.nutri: 0},
          ),
        ).done,
        isTrue,
      );
    });

    test('도감 80%를 모으면 무궁화가 열린다', () {
      expect(at('sp_rare_hibiscus', ctx(owned: 14)).done, isFalse); // 77%
      expect(at('sp_rare_hibiscus', ctx(owned: 15)).done, isTrue); // 83%
    });

    test('아직 셀 수 없는 조건은 준비 중이고 열리지 않는다', () {
      for (final id in DexRules.comingSoonIds) {
        final r = at(id, ctx(tally: RecordTally(meals: 999, exercises: 999)));
        expect(r.comingSoon, isTrue, reason: id);
        expect(r.done, isFalse, reason: id);
      }
    });

    test('도감 18종 모두에 조건이 있다 (계산하거나 준비 중이거나)', () {
      for (final sp in PlantSpecies.catalog) {
        final r = at(sp.id, ctx());
        expect(
          DexRules.isComingSoon(sp.id) == r.comingSoon,
          isTrue,
          reason: sp.id,
        );
      }
    });
  });

  group('PlantViewModel · 기록과 성장', () {
    late DateTime clock;
    late MemoryRecordRepository<Plant> plantRepo;
    late MemoryRecordRepository<DexEntry> dexRepo;
    late Set<String> recordedDays;

    PlantViewModel build() {
      plantRepo = MemoryRecordRepository(plantCodec);
      dexRepo = MemoryRecordRepository(dexEntryCodec);
      return PlantViewModel(
        plantRepo: plantRepo,
        dexRepo: dexRepo,
        saveDelay: Duration.zero,
        now: () => clock,
      );
    }

    String key(DateTime d) => AppState.dateKeyOf(d);

    PlantSyncInput input({int streak = 0, bool onboarded = false}) =>
        PlantSyncInput(
          today: DateTime(clock.year, clock.month, clock.day),
          hasRecordOn: (d) => recordedDays.contains(key(d)),
          streakDays: streak,
          onboardingDone: onboarded,
        );

    Future<PlantViewModel> started() async {
      final vm = build();
      await vm.loadForUid('u1');
      vm.syncDay(input());
      return vm;
    }

    setUp(() {
      clock = DateTime(2026, 10, 18, 9);
      recordedDays = {};
    });

    test('첫 기록으로 횟수가 세어지고, 돌보기가 충전되고, 새싹이 도감에 들어온다', () async {
      final vm = await started();
      vm.plant.cares.updateAll((_, _) => 0);
      expect(vm.dexOwned, 0);

      vm.onRecorded(RecordKind.meal, breakfast: true);

      expect(vm.plant.tally.meals, 1);
      expect(vm.plant.tally.breakfasts, 1);
      expect(vm.plant.cares['영양 주기'], 1);
      expect(
        vm.dexEntries.firstWhere((e) => e.speciesId == 'sp_sprout').owned,
        isTrue,
      );
    });

    test('식단 30번이면 장미가, 그 전에는 진행도만 오른다', () async {
      final vm = await started();

      for (var i = 0; i < 15; i++) {
        vm.onRecorded(RecordKind.meal);
      }
      var rose = vm.dexEntries.firstWhere((e) => e.speciesId == 'sp_rose');
      expect(rose.owned, isFalse);
      expect(rose.progress, 50);

      for (var i = 0; i < 15; i++) {
        vm.onRecorded(RecordKind.meal);
      }
      rose = vm.dexEntries.firstWhere((e) => e.speciesId == 'sp_rose');
      expect(rose.owned, isTrue);
      expect(rose.progress, 100);
    });

    test('물 · 운동 · 체중 기록도 각자의 누적에 더해진다', () async {
      final vm = await started();

      vm.onRecorded(RecordKind.water, ml: 250);
      vm.onRecorded(RecordKind.water, ml: 500);
      vm.onRecorded(RecordKind.exercise, minutes: 40);
      vm.onRecorded(RecordKind.weight);

      final t = vm.plant.tally;
      expect((t.waterEntries, t.waterMl), (2, 750));
      expect((t.exercises, t.exerciseMinutes), (1, 40));
      expect(t.weights, 1);
      expect(t.totalRecords, 4);
    });

    test('한 번 모은 식물은 줄어들지 않는다 (예시 도감도 그대로)', () {
      final vm = build(); // 예시 계정은 도감 8종을 모은 상태로 시작한다
      final before = vm.dexOwned;

      vm.onRecorded(RecordKind.meal);

      expect(vm.dexOwned, greaterThanOrEqualTo(before));
    });

    test('시작 안내를 마치면 튤립이 열린다', () async {
      final vm = await started();
      expect(
        vm.dexEntries.firstWhere((e) => e.speciesId == 'sp_tulip').owned,
        isFalse,
      );

      vm.syncDay(input(onboarded: true));

      expect(
        vm.dexEntries.firstWhere((e) => e.speciesId == 'sp_tulip').owned,
        isTrue,
      );
    });

    test('가장 긴 연속 기록이 갱신된다 (줄어들지 않는다)', () async {
      final vm = await started();

      vm.syncDay(input(streak: 5));
      vm.syncDay(input(streak: 2));

      expect(vm.plant.tally.bestStreakDays, 5);
    });

    test('기록이 바뀌면 바로 저장되고, 다시 켜면 이어진다', () async {
      final vm = await started();
      vm.onRecorded(RecordKind.meal);
      vm.onRecorded(RecordKind.water, ml: 300);
      await Future<void>.delayed(Duration.zero);

      final again = PlantViewModel(
        plantRepo: plantRepo,
        dexRepo: dexRepo,
        saveDelay: Duration.zero,
        now: () => clock,
      );
      await again.loadForUid('u1');

      expect(again.plant.tally.meals, 1);
      expect(again.plant.tally.waterMl, 300);
      expect(again.plant.startedKey, '2026-10-18');
      expect(
        again.dexEntries.firstWhere((e) => e.speciesId == 'sp_sprout').owned,
        isTrue,
      );
    });
  });

  group('PlantViewModel · 기록을 쉬면 시든다', () {
    late DateTime clock;
    late Set<String> recorded;
    late PlantViewModel vm;

    String key(DateTime d) => AppState.dateKeyOf(d);

    PlantSyncInput input() => PlantSyncInput(
      today: DateTime(clock.year, clock.month, clock.day),
      hasRecordOn: (d) => recorded.contains(key(d)),
      streakDays: 0,
      onboardingDone: false,
    );

    /// [daysAgo]일 전부터 키우기 시작한 식물.
    Future<void> startDaysAgo(int daysAgo) async {
      clock = DateTime(2026, 10, 18 - daysAgo, 9);
      vm = PlantViewModel(
        plantRepo: MemoryRecordRepository(plantCodec),
        dexRepo: MemoryRecordRepository(dexEntryCodec),
        saveDelay: Duration.zero,
        now: () => clock,
      );
      await vm.loadForUid('u1');
      clock = DateTime(2026, 10, 18, 9);
    }

    setUp(() => recorded = {});

    test('오늘 시작한 식물은 아직 쉰 날이 없어서 시들지 않는다', () async {
      await startDaysAgo(0);

      vm.syncDay(input());

      expect(vm.missedDays, 0);
      expect(vm.wilting, isFalse);
    });

    test('하루 쉬는 것은 괜찮고, 이틀째부터 시든다', () async {
      await startDaysAgo(5);
      recorded = {'2026-10-16'}; // 17일(어제)만 쉼

      vm.syncDay(input());
      expect(vm.missedDays, 1);
      expect(vm.wilting, isFalse);

      recorded = {'2026-10-15'}; // 16 · 17일을 쉼
      vm.syncDay(input());
      expect(vm.missedDays, 2);
      expect(vm.wilting, isTrue);
    });

    test('오늘 기록하면 바로 회복된다', () async {
      await startDaysAgo(5);
      vm.syncDay(input());
      expect(vm.wilting, isTrue);

      recorded = {'2026-10-18'};
      vm.syncDay(input());

      expect(vm.missedDays, 0);
      expect(vm.wilting, isFalse);
    });

    test('키우기 시작한 날보다 앞은 쉰 날로 세지 않는다', () async {
      await startDaysAgo(1); // 어제 시작 · 기록 없음

      vm.syncDay(input());

      expect(vm.missedDays, 1); // 어제 하루만
      expect(vm.wilting, isFalse);
    });

    test('"회복 돌보기"를 누르면 오늘은 시들지 않고, 다음 날 기록이 없으면 다시 시든다', () async {
      await startDaysAgo(5);
      vm.syncDay(input());
      expect(vm.wilting, isTrue);

      vm.revive();
      expect(vm.wilting, isFalse);

      vm.syncDay(input()); // 같은 날 다시 맞춰도 그대로
      expect(vm.wilting, isFalse);

      clock = DateTime(2026, 10, 19, 9); // 다음 날
      vm.syncDay(input());
      expect(vm.wilting, isTrue);
    });

    test('쉰 날은 최대 30일까지만 센다', () async {
      await startDaysAgo(100);

      vm.syncDay(input());

      expect(vm.missedDays, 30);
    });
  });

  group('PlantViewModel · 친구 물주기 하루 한도', () {
    test('날짜가 바뀌면 한도가 다시 시작한다', () async {
      var clock = DateTime(2026, 10, 18, 9);
      final vm = PlantViewModel(
        plantRepo: MemoryRecordRepository(plantCodec),
        dexRepo: MemoryRecordRepository(dexEntryCodec),
        saveDelay: Duration.zero,
        now: () => clock,
      );
      await vm.loadForUid('u1');

      vm.waterFriend('f1');
      vm.waterFriend('f2');
      vm.waterFriend('f3');
      vm.waterFriend('f4'); // 하루 3회까지
      expect(vm.wateredFriends, ['f1', 'f2', 'f3']);

      clock = DateTime(2026, 10, 19, 9);
      vm.waterFriend('f4');

      expect(vm.wateredFriends, ['f4']);
    });

    test('syncDay도 날짜가 바뀌면 오늘 물 준 친구를 비운다', () async {
      var clock = DateTime(2026, 10, 18, 9);
      final vm = PlantViewModel(
        plantRepo: MemoryRecordRepository(plantCodec),
        dexRepo: MemoryRecordRepository(dexEntryCodec),
        saveDelay: Duration.zero,
        now: () => clock,
      );
      await vm.loadForUid('u1');
      vm.waterFriend('f1');
      expect(vm.wateredFriends, ['f1']);

      clock = DateTime(2026, 10, 19, 9);
      vm.syncDay(
        PlantSyncInput(
          today: DateTime(2026, 10, 19),
          hasRecordOn: (_) => true,
          streakDays: 0,
          onboardingDone: false,
        ),
      );

      expect(vm.wateredFriends, isEmpty);
    });
  });

  group('DexCard · 준비 중 표시', () {
    DexCard card(String id, {bool owned = false}) => DexCard(
      PlantSpecies.catalog.firstWhere((sp) => sp.id == id),
      DexEntry(userId: 'u1', speciesId: id, owned: owned),
    );

    test('아직 셀 수 없는 조건의 식물은 준비 중으로 보인다', () {
      expect(card('sp_golden_rose').comingSoon, isTrue);
      expect(card('sp_clover').comingSoon, isTrue);
    });

    test('셀 수 있는 조건이거나 이미 모은 식물은 준비 중이 아니다', () {
      expect(card('sp_rose').comingSoon, isFalse);
      expect(card('sp_golden_rose', owned: true).comingSoon, isFalse);
    });
  });

  group('저장 형식', () {
    test('누적 횟수와 날짜 값까지 저장했다가 그대로 복원한다', () {
      final plant = Plant.starter('u1')
        ..startedKey = '2026-10-01'
        ..revivedKey = '2026-10-17'
        ..friendWaterKey = '2026-10-18'
        ..tally = RecordTally(
          meals: 12,
          breakfasts: 4,
          exercises: 3,
          exerciseMinutes: 95,
          waterEntries: 20,
          waterMl: 5500,
          weights: 2,
          bestStreakDays: 6,
        );

      final back = plantCodec.fromMap('state', plantCodec.toMap(plant), 'u1');

      expect(back.startedKey, '2026-10-01');
      expect(back.revivedKey, '2026-10-17');
      expect(back.friendWaterKey, '2026-10-18');
      expect(back.tally.meals, 12);
      expect(back.tally.exerciseMinutes, 95);
      expect(back.tally.waterMl, 5500);
      expect(back.tally.bestStreakDays, 6);
    });

    test('예전에 저장된 식물(누적 · 날짜 값 없음)도 읽는다', () {
      final back = plantCodec.fromMap('state', {
        'speciesId': 'sp_sprout',
        'exp': 120,
        'revived': true, // 예전 형식 — 날짜가 없어서 쓰지 않는다
      }, 'u1');

      expect(back.exp, 120);
      expect(back.tally.totalRecords, 0);
      expect(back.startedKey, '');
      expect(back.revivedKey, '');
    });
  });

  group('AppState 연결', () {
    test('식단 · 운동 · 물 · 체중을 기록하면 식물에 반영된다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      final before = s.plantViewModel.plant.tally.totalRecords;
      s.plantViewModel.plant.cares.updateAll((_, _) => 0);

      s.logMeal();
      s.onWaterAdded(250);
      s.exMinutes = 30;
      s.logExercise();
      s.onWeightLogged(60);

      final plant = s.plantViewModel.plant;
      expect(plant.tally.totalRecords - before, 4);
      expect(plant.cares, {'물 주기': 1, '햇빛 받기': 1, '영양 주기': 1});
      expect(plant.tally.exerciseMinutes, greaterThanOrEqualTo(30));
    });

    test('돌보기를 눌러 쓴 뒤에는 기록해야 다시 쓸 수 있다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      s.plantViewModel.plant.cares['영양 주기'] = 1;
      s.care('영양 주기');
      expect(s.cares['영양 주기'], 0);

      s.care('영양 주기'); // 횟수가 없어서 아무 일도 없다
      final expAfterEmpty = s.plantExp;
      s.care('영양 주기');
      expect(s.plantExp, expAfterEmpty);

      s.logMeal(); // 식단 기록 → 영양 주기 충전
      expect(s.cares['영양 주기'], 1);
    });
  });
}
