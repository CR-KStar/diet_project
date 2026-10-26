import 'package:diet_project/app_composition.dart';
import 'package:diet_project/app_providers.dart';
import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/services/impl/memory_meal_photo_store.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/domain/repositories/water_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

const _account = AuthAccount(
  uid: 'u1',
  provider: LoginProvider.google,
  displayName: '지민',
);

class _FakeAuth implements AuthService {
  @override
  bool get isDemo => false;

  @override
  AuthAccount? get currentAccount => _account;

  @override
  Future<AuthAccount?> restoreAccount() async => _account;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => _account;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {}
}

/// deleteAll 호출을 기록하고 실패시킬 수 있는 가짜 기록 저장소.
class _Repo<T> implements RecordRepository<T> {
  final deleteAllUids = <String>[];
  bool failDeleteAll = false;

  @override
  Future<List<T>> loadAll(String uid) async => [];

  @override
  Future<List<T>> loadRange(String uid, String fromKey, String toKey) async =>
      [];

  @override
  Future<void> save(String uid, T entry) async {}

  @override
  Future<void> delete(String uid, String id) async {}

  @override
  Future<void> deleteAll(String uid) async {
    if (failDeleteAll) throw Exception('network down');
    deleteAllUids.add(uid);
  }
}

class _WaterRepo implements WaterRepository {
  final deleteAllUids = <String>[];

  @override
  Future<List<WaterEntry>> loadDay(String uid, String dateKey) async => [];

  @override
  Future<void> save(String uid, WaterEntry entry) async {}

  @override
  Future<void> delete(String uid, String entryId) async {}

  @override
  Future<void> deleteAll(String uid) async => deleteAllUids.add(uid);
}

class _Setup {
  _Setup()
    : meals = _Repo<MealLog>(),
      exercises = _Repo<ExerciseLog>(),
      weights = _Repo<WeightEntry>(),
      water = _WaterRepo(),
      photos = MemoryMealPhotoStore();

  final _Repo<MealLog> meals;
  final _Repo<ExerciseLog> exercises;
  final _Repo<WeightEntry> weights;
  final _WaterRepo water;
  final MemoryMealPhotoStore photos;

  /// 로그인한 상태로, 기록을 네 종류 모두 하나씩 남기고 사진도 한 장 보관해 둔다.
  Future<AppState> signedInWithRecords() async {
    final state = AppState(
      dependencies: memoryDependencies(
        auth: _FakeAuth(),
        mealRepo: meals,
        exerciseRepo: exercises,
        weightRepo: weights,
        waterRepo: water,
        mealPhotoStore: photos,
        now: () => DateTime(2026, 10, 18),
      ),
    );
    await state.restoreSession();
    _addRecords(state);
    return state;
  }

  Future<AppState> demoWithRecords() async {
    final state = AppState(
      dependencies: memoryDependencies(
        mealPhotoStore: photos,
        now: () => DateTime(2026, 10, 18),
      ),
    );
    _addRecords(state);
    return state;
  }

  void _addRecords(AppState state) {
    state.logMeal();
    state.exMinutes = 30;
    state.logExercise();
    state.weightViewModel.setWeightInput(61.2);
    state.weightViewModel.logWeight();
    state.waterViewModel.setWaterInput(300);
    state.waterViewModel.addWater();
    photos.save('photo_1', Uint8List.fromList(const [1, 2, 3]));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('로그인 상태: 서버에서 네 종류를 지우고, 기기의 기록 · 사진도 비운다', () async {
    final setup = _Setup();
    final state = await setup.signedInWithRecords();
    final expBefore = state.plantViewModel.plant.exp;
    expect(state.todayMeals, isNotEmpty);
    expect(await setup.photos.load('photo_1'), isNotNull);

    final done = await state.deleteAllRecords();

    expect(done, isTrue);
    expect(setup.meals.deleteAllUids, ['u1']);
    expect(setup.exercises.deleteAllUids, ['u1']);
    expect(setup.weights.deleteAllUids, ['u1']);
    expect(setup.water.deleteAllUids, ['u1']);
    expect(state.mealViewModel.mealLogs, isEmpty);
    expect(state.exerciseViewModel.exerciseLogs, isEmpty);
    expect(state.weightViewModel.weightEntries, isEmpty);
    expect(state.waterViewModel.waterEntries, isEmpty);
    expect(await setup.photos.load('photo_1'), isNull);
    // 식물 · 프로필은 그대로다.
    expect(state.plantViewModel.plant.exp, expBefore);
    expect(state.account?.uid, 'u1');
  });

  test('서버에서 지우지 못하면 기기의 기록과 사진은 그대로 두고 false를 돌려준다', () async {
    final setup = _Setup();
    final state = await setup.signedInWithRecords();
    setup.exercises.failDeleteAll = true;
    final mealsBefore = state.mealViewModel.mealLogs.length;

    final done = await state.deleteAllRecords();

    expect(done, isFalse);
    expect(state.mealViewModel.mealLogs.length, mealsBefore);
    expect(state.exerciseViewModel.exerciseLogs, isNotEmpty);
    expect(state.weightViewModel.weightEntries, isNotEmpty);
    expect(await setup.photos.load('photo_1'), isNotNull);
    expect(state.takeNotice(), contains('기록을 모두 지우지 못했어요'));
  });

  test('실패한 뒤 다시 누르면 이어서 지워진다', () async {
    final setup = _Setup();
    final state = await setup.signedInWithRecords();
    setup.exercises.failDeleteAll = true;
    expect(await state.deleteAllRecords(), isFalse);

    setup.exercises.failDeleteAll = false;
    expect(await state.deleteAllRecords(), isTrue);
    expect(state.exerciseViewModel.exerciseLogs, isEmpty);
  });

  test('체험 상태(로그인 안 함)에서는 서버를 부르지 않고 기기의 예시 기록만 비운다', () async {
    final setup = _Setup();
    final state = await setup.demoWithRecords();

    final done = await state.deleteAllRecords();

    expect(done, isTrue);
    expect(setup.meals.deleteAllUids, isEmpty);
    expect(state.mealViewModel.mealLogs, isEmpty);
    expect(await setup.photos.load('photo_1'), isNull);
  });

  testWidgets('설정의 "기록 전체 삭제"는 확인창에서 "모두 삭제"를 눌러야 지운다', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final setup = _Setup();
    final state = await setup.demoWithRecords();
    state.navigationViewModel.go('privacy');
    await tester.pumpWidget(
      AppProviders(
        state: state,
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.ensureVisible(find.text('기록 전체 삭제'));
    await tester.tap(find.text('기록 전체 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('기록을 모두 지울까요?'), findsOneWidget);

    // 취소하면 아무것도 지우지 않는다.
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(state.mealViewModel.mealLogs, isNotEmpty);

    await tester.tap(find.text('기록 전체 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 삭제'));
    await tester.pumpAndSettle();

    expect(state.mealViewModel.mealLogs, isEmpty);
    expect(state.exerciseViewModel.exerciseLogs, isEmpty);
    expect(find.text('기록을 모두 지웠어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
