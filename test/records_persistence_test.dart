import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/common.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/profile_repository.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/data/repositories/water_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _account = AuthAccount(uid: 'uid_1', provider: LoginProvider.google, displayName: '지민');
const _today = '2026-09-21';

class _FakeAuth implements AuthService {
  @override
  AuthAccount? get currentAccount => _account;

  @override
  Future<AuthAccount?> restoreAccount() async => _account;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => _account;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {
    await beforeDelete?.call();
  }
}

/// 불러오기 · 저장이 실패하도록 만들 수 있고, 불러오기 횟수를 세는 저장소.
class _Flaky<T> extends MemoryRecordRepository<T> {
  _Flaky(super.codec, {this.failLoad = false, this.failSave = false});

  final bool failLoad;
  final bool failSave;
  int rangeLoads = 0;
  int saves = 0;

  @override
  Future<List<T>> loadAll(String uid) async {
    if (failLoad) throw Exception('network down');
    return super.loadAll(uid);
  }

  @override
  Future<List<T>> loadRange(String uid, String fromKey, String toKey) async {
    rangeLoads++;
    if (failLoad) throw Exception('network down');
    return super.loadRange(uid, fromKey, toKey);
  }

  @override
  Future<void> save(String uid, T entry) async {
    saves++;
    if (failSave) throw Exception('network down');
    return super.save(uid, entry);
  }
}

/// 앱을 껐다 켜도 남는 "서버" 역할 — 저장소들을 함께 들고 있다.
class _Server {
  final profiles = MemoryProfileRepository();
  final water = MemoryWaterRepository();
  final weight = _Flaky(weightCodec);
  final exercise = _Flaky(exerciseCodec);
  final meals = _Flaky(mealCodec);
  final bowls = _Flaky(bowlCodec);
  final routines = _Flaky(routineCodec);
  final plant = _Flaky(plantCodec);

  AppState app({DateTime Function()? now}) => AppState(
        auth: _FakeAuth(),
        profiles: profiles,
        waterRepo: water,
        weightRepo: weight,
        exerciseRepo: exercise,
        mealRepo: meals,
        bowlRepo: bowls,
        routineRepo: routines,
        plantRepo: plant,
        now: now ?? () => DateTime(2026, 9, 21, 14, 5),
      );
}

Future<AppState> _start(_Server server, {DateTime Function()? now}) async {
  final s = server.app(now: now);
  await s.restoreSession();
  return s;
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 700));

Future<void> _pumpScreen(WidgetTester tester, AppState state, String screen) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  state.go(screen);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: AppShell()),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('저장 형식 (codec)', () {
    test('체중 · 운동 · 식단 · 그릇 · 루틴 · 식물이 저장했다가 그대로 복원된다', () {
      final weight = weightCodec.fromMap('w', weightCodec.toMap(WeightEntry(id: 'w', userId: 'u', kg: 56.4, dateKey: _today, time: '14:05')), 'u');
      expect([weight.kg, weight.dateKey, weight.time], [56.4, _today, '14:05']);

      final ex = exerciseCodec.fromMap(
        'e',
        exerciseCodec.toMap(ExerciseLog(id: 'e', userId: 'u', type: '달리기', minutes: 30, intensity: ExerciseIntensity.high, kcal: 300, dateKey: _today, time: '09:00')),
        'u',
      );
      expect([ex.type, ex.minutes, ex.intensity, ex.kcal], ['달리기', 30, ExerciseIntensity.high, 300]);

      final meal = mealCodec.fromMap(
        'm',
        mealCodec.toMap(const MealLog(id: 'm', userId: 'u', mealType: MealType.dinner, name: '샐러드', meta: '메모', kcal: 480, dateKey: _today, bowlId: 'b1', needsReview: true)),
        'u',
      );
      expect([meal.mealType, meal.name, meal.kcal, meal.bowlId, meal.needsReview], [MealType.dinner, '샐러드', 480, 'b1', true]);

      final bowl = bowlCodec.fromMap('b', bowlCodec.toMap(Bowl(id: 'b', userId: 'u', name: '도시락', capacityMl: 500, portion: '1인분', material: '유리', shape: '사각', isDefault: true)), 'u');
      expect([bowl.name, bowl.capacityMl, bowl.isDefault], ['도시락', 500, true]);

      final routine = routineCodec.fromMap('r', routineCodec.toMap(Routine(id: 'r', userId: 'u', name: '아침', type: '걷기', minutes: 25, intensity: ExerciseIntensity.low)), 'u');
      expect([routine.type, routine.minutes, routine.intensity], ['걷기', 25, ExerciseIntensity.low]);

      final plant = Plant.starter('u')
        ..exp = 240
        ..axisScore[PlantAxis.sun] = 45
        ..cares['물 주기'] = 1
        ..wateredFriendIds = ['f1'];
      final back = plantCodec.fromMap(plantDocId, plantCodec.toMap(plant), 'u');
      expect([back.exp, back.axisScore[PlantAxis.sun], back.cares['물 주기'], back.wateredFriendIds], [240, 45, 1, ['f1']]);
    });

    test('저장된 값의 타입이 이상해도 기본값으로 복원한다', () {
      final weight = weightCodec.fromMap('w', {'kg': '많이', 'dateKey': 3}, 'u');
      expect([weight.kg, weight.dateKey], [0, '']);

      final ex = exerciseCodec.fromMap('e', {'intensity': '없는강도', 'minutes': 'x'}, 'u');
      expect([ex.intensity, ex.minutes], [ExerciseIntensity.moderate, 0]);

      final meal = mealCodec.fromMap('m', {'mealType': 7, 'bowlId': 3}, 'u');
      expect([meal.mealType, meal.bowlId], [MealType.lunch, null]);

      final plant = plantCodec.fromMap(plantDocId, {'axisScore': '깨짐', 'cares': 5, 'wateredFriendIds': 'x'}, 'u');
      expect(plant.axisScore.values, everyElement(0));
      expect(plant.cares['물 주기'], 3); // 시작값
      expect(plant.wateredFriendIds, isEmpty);
    });
  });

  group('체중', () {
    test('기록하면 계정에 저장되고, 프로필의 현재 체중도 함께 저장된다', () async {
      final server = _Server();
      final s = await _start(server);
      s.weightInput = 55.8;

      s.logWeight();
      await Future<void>.delayed(Duration.zero);

      final saved = (await server.weight.loadAll('uid_1')).single;
      expect([saved.kg, saved.dateKey, saved.time, saved.userId], [55.8, _today, '14:05', 'uid_1']);
      expect((await server.profiles.load('uid_1'))?.profile.weightKg, 55.8);
    });

    test('다시 켜면 체중 기록이 불러와지고 입력 기본값이 마지막 체중이 된다', () async {
      final server = _Server();
      final first = await _start(server);
      first.weightInput = 55.8;
      first.logWeight();

      final second = await _start(server);

      expect(second.weightEntries.map((e) => e.kg), [55.8]);
      expect(second.latestWeightKg, 55.8);
      expect(second.weightInput, 55.8);
      expect(second.todayRegistry.weightEntry?.kg, 55.8);
    });
  });

  group('운동', () {
    test('기록하면 보고 있는 날짜로 저장되고, 다시 켜면 불러와진다', () async {
      final server = _Server();
      final first = await _start(server);
      first.exType = '달리기';
      first.exMinutes = 30;
      first.logExercise();

      final second = await _start(server);

      final log = second.todayRegistry.exerciseLogs.single;
      expect([log.type, log.minutes, log.dateKey, log.userId, log.time], ['달리기', 30, _today, 'uid_1', '14:05']);
      expect(second.todayExerciseMinutes, 30);
    });

    test('지난달로 넘기면 그 달의 기록을 불러오고, 같은 달은 다시 불러오지 않는다', () async {
      final server = _Server();
      await server.exercise.save(
        'uid_1',
        ExerciseLog(id: 'ex_old', userId: 'uid_1', type: '요가', minutes: 40, intensity: ExerciseIntensity.low, kcal: 100, dateKey: '2026-07-05', time: '08:00'),
      );
      final s = await _start(server);
      expect(s.hasRecordOn(DateTime(2026, 7, 5)), isFalse); // 아직 안 불러온 달

      s.prevMonth(); // 8월 (이미 불러옴)
      s.prevMonth(); // 7월
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(s.hasRecordOn(DateTime(2026, 7, 5)), isTrue);

      final calls = server.exercise.rangeLoads;
      s.nextMonth();
      s.prevMonth();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(server.exercise.rangeLoads, calls);
    });

    test('루틴 저장과 삭제가 계정에 반영된다', () async {
      final server = _Server();
      final s = await _start(server);
      s.exType = '걷기';
      s.exMinutes = 25;

      s.saveCurrentAsRoutine();
      await Future<void>.delayed(Duration.zero);
      expect((await server.routines.loadAll('uid_1')).single.type, '걷기');

      s.removeRoutine(s.routines.single);
      await Future<void>.delayed(Duration.zero);
      expect(await server.routines.loadAll('uid_1'), isEmpty);
    });
  });

  group('식단', () {
    test('기록하면 계정 · 오늘 날짜로 저장되고 오늘 식단에 나타난다', () async {
      final server = _Server();
      final s = await _start(server);

      s.logMeal();
      await Future<void>.delayed(Duration.zero);

      expect(s.todayMeals, hasLength(1)); // 실제 계정 id로 걸러져도 보인다
      final saved = (await server.meals.loadAll('uid_1')).single;
      expect([saved.dateKey, saved.userId, saved.mealType], [_today, 'uid_1', MealType.lunch]);
    });

    test('다시 켜면 오늘 먹은 식단이 불러와지고 칼로리에 반영된다', () async {
      final server = _Server();
      final first = await _start(server);
      first.logMeal();
      final kcal = first.intakeKcal;

      final second = await _start(server);

      expect(second.todayMeals, hasLength(1));
      expect(second.intakeKcal, kcal);
      expect(second.intakeKcal, greaterThan(0));
    });

    test('그릇이 하나도 없어도 식단을 기록할 수 있다', () async {
      final server = _Server();
      final s = await _start(server);

      expect(s.currentBowl, isNull);
      expect(() => s.adjustedKcal, returnsNormally);

      s.logMeal();
      expect((await server.meals.loadAll('uid_1')).single.bowlId, isNull);
    });

    test('그릇을 고르고 기록하면 식단이 그 그릇을 가리키고, 다시 켜도 연결이 유지된다', () async {
      final server = _Server();
      final first = await _start(server);
      first.startAddBowl();
      first.draftBowl.name = '회사 도시락';
      first.draftBowl.isDefault = true;
      expect(first.saveBowl(), isTrue);
      first.logMeal();

      final second = await _start(server);

      final meal = second.todayMeals.single;
      expect(meal.bowlId, second.bowls.single.id);
      expect(second.bowls.single.name, '회사 도시락');
    });
  });

  group('그릇', () {
    test('추가 · 수정 · 삭제가 저장되고, 기본 그릇을 바꾸면 이전 기본 그릇도 함께 저장된다', () async {
      final server = _Server();
      final s = await _start(server);

      s.startAddBowl();
      s.draftBowl.name = '집 밥그릇';
      s.draftBowl.isDefault = true;
      s.saveBowl();
      s.startAddBowl();
      s.draftBowl.name = '샐러드 볼';
      s.draftBowl.isDefault = true; // 기본 그릇이 바뀐다
      s.saveBowl();
      await Future<void>.delayed(Duration.zero);

      final stored = {for (final b in await server.bowls.loadAll('uid_1')) b.name: b.isDefault};
      expect(stored, {'집 밥그릇': false, '샐러드 볼': true});

      s.startEditBowl(1);
      s.draftBowl.name = '큰 샐러드 볼';
      s.saveBowl();
      s.removeBowl(0);
      await Future<void>.delayed(Duration.zero);

      final after = await server.bowls.loadAll('uid_1');
      expect(after.map((b) => b.name), ['큰 샐러드 볼']);
    });
  });

  group('식물', () {
    test('새 계정은 시작 식물로 시작한다 (예시 식물이 아니다)', () async {
      final s = await _start(_Server());

      expect(s.plantExp, 0);
      expect(s.plantLevel, 1);
      expect(s.plant.userId, 'uid_1');
    });

    test('돌보기 · 아이템 사용이 잠깐 뒤에 한 번 저장되고, 다시 켜면 이어진다', () async {
      final server = _Server();
      final first = await _start(server);

      first.care('물 주기');
      first.care('물 주기');
      first.useInventoryItem('물방울');
      await _settle();

      expect(server.plant.saves, 1); // 연달아 해도 한 번만 저장
      final second = await _start(server);
      expect(second.plantExp, first.plantExp);
      expect(second.plantExp, greaterThan(0));
      expect(second.cares['물 주기'], 1);
      expect(second.inventory['물방울'], 2);
    });

    test('미션을 수동 완료하면 받은 경험치가 저장된다', () async {
      final server = _Server();
      final first = await _start(server);
      first.completeMissionManually(first.missions.first);
      await _settle();

      final second = await _start(server);
      expect(second.plantExp, first.plantExp);
      expect(second.plantExp, greaterThan(0));
    });

    test('식물을 불러오지 못하면 원래 식물을 덮어쓰지 않도록 저장을 멈추고 안내한다', () async {
      final server = _Server();
      final flaky = _Flaky(plantCodec, failLoad: true);
      final s = AppState(
        auth: _FakeAuth(),
        plantRepo: flaky,
        now: () => DateTime(2026, 9, 21),
      );
      await s.restoreSession();

      s.care('물 주기');
      await _settle();

      expect(flaky.saves, 0);
      expect(s.takeNotice(), contains('식물'));
      expect(server.plant.saves, 0);
    });
  });

  group('실패했을 때', () {
    test('저장에 실패하면 화면 기록은 두고 종류를 밝혀 안내한다', () async {
      final s = AppState(
        auth: _FakeAuth(),
        weightRepo: _Flaky(weightCodec, failSave: true),
        now: () => DateTime(2026, 9, 21),
      );
      await s.restoreSession();

      s.logWeight();
      await Future<void>.delayed(Duration.zero);

      expect(s.weightEntries, hasLength(1));
      expect(s.takeNotice(), contains('체중 기록'));
    });

    test('기록을 불러오지 못해도 로그인은 막지 않고 안내만 한다', () async {
      final s = AppState(
        auth: _FakeAuth(),
        exerciseRepo: _Flaky(exerciseCodec, failLoad: true),
        weightRepo: _Flaky(weightCodec, failLoad: true),
        now: () => DateTime(2026, 9, 21),
      );

      expect(await s.restoreSession(), isTrue);

      expect(s.account, isNotNull);
      expect(s.takeNotice(), isNotNull);
    });
  });

  test('계정을 삭제하면 모든 종류의 기록이 함께 지워진다', () async {
    final server = _Server();
    final s = await _start(server);
    s.addWater(250);
    s.weightInput = 55.0;
    s.logWeight();
    s.logExercise();
    s.logMeal();
    s.startAddBowl();
    s.draftBowl.name = '그릇';
    s.saveBowl();
    s.saveCurrentAsRoutine();
    s.care('물 주기');
    await _settle();
    expect(server.plant.saves, greaterThan(0));

    expect(await s.deleteAccount(), isTrue);

    expect(await server.water.loadDay('uid_1', _today), isEmpty);
    expect(await server.weight.loadAll('uid_1'), isEmpty);
    expect(await server.exercise.loadAll('uid_1'), isEmpty);
    expect(await server.meals.loadAll('uid_1'), isEmpty);
    expect(await server.bowls.loadAll('uid_1'), isEmpty);
    expect(await server.routines.loadAll('uid_1'), isEmpty);
    expect(await server.plant.loadAll('uid_1'), isEmpty);
    expect(await server.profiles.load('uid_1'), isNull);
  });

  group('화면의 저장 버튼이 실제로 저장까지 이어진다', () {
    testWidgets('"운동 저장"', (tester) async {
      final server = _Server();
      final state = await _start(server);
      await _pumpScreen(tester, state, 'exercise');

      await tester.ensureVisible(find.text('운동 저장'));
      await tester.tap(find.text('운동 저장'));
      await tester.pump();

      expect(await server.exercise.loadAll('uid_1'), hasLength(1));
    });

    testWidgets('"지금 입력한 내용을 루틴으로 저장"', (tester) async {
      final server = _Server();
      final state = await _start(server);
      await _pumpScreen(tester, state, 'exercise');

      await tester.ensureVisible(find.text('지금 입력한 내용을 루틴으로 저장'));
      await tester.tap(find.text('지금 입력한 내용을 루틴으로 저장'));
      await tester.pump();

      expect(await server.routines.loadAll('uid_1'), hasLength(1));
    });

    testWidgets('"체중 저장"', (tester) async {
      final server = _Server();
      final state = await _start(server);
      state.bodyShots['SIDE'] = true; // 눈바디 2장 촬영 완료
      await _pumpScreen(tester, state, 'weight');

      await tester.ensureVisible(find.text('체중 저장'));
      await tester.tap(find.text('체중 저장'));
      await tester.pump();

      expect(await server.weight.loadAll('uid_1'), hasLength(1));
    });

    testWidgets('식단 "저장하기"', (tester) async {
      final server = _Server();
      final state = await _start(server);
      await _pumpScreen(tester, state, 'capture');

      await tester.ensureVisible(find.text('저장하기'));
      await tester.tap(find.text('저장하기'));
      await tester.pump();

      expect(await server.meals.loadAll('uid_1'), hasLength(1));
    });

    testWidgets('식물 돌보기 버튼', (tester) async {
      final server = _Server();
      final state = await _start(server);
      await _pumpScreen(tester, state, 'plant');

      // '물 주기'는 친구에게 물 주기 버튼에도 있어서, 내 식물 돌보기 카드의 버튼(첫 번째)을 지정한다.
      final careButton = find.widgetWithText(SmallButton, '물 주기').first;
      await tester.ensureVisible(careButton);
      await tester.tap(careButton);
      await tester.pump(const Duration(milliseconds: 700)); // 저장 대기 시간

      expect(state.plantExp, greaterThan(0));
      expect(await server.plant.loadAll('uid_1'), hasLength(1));
    });
  });
}
