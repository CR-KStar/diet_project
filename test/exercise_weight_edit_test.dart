import 'package:diet_project/app_composition.dart';
import 'package:diet_project/app_providers.dart';
import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/ui/record/viewmodel/exercise_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/weight_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// 저장 · 삭제 호출을 기록하고, 삭제를 실패시킬 수 있는 가짜 저장소.
class _Repo<T> implements RecordRepository<T> {
  final saved = <T>[];
  final deletedIds = <String>[];
  bool failDelete = false;

  @override
  Future<List<T>> loadAll(String uid) async => [];

  @override
  Future<List<T>> loadRange(String uid, String fromKey, String toKey) async =>
      [];

  @override
  Future<void> save(String uid, T entry) async => saved.add(entry);

  @override
  Future<void> delete(String uid, String id) async {
    if (failDelete) throw Exception('network down');
    deletedIds.add(id);
  }

  @override
  Future<void> deleteAll(String uid) async {}
}

ExerciseLog _ex(String id, {int minutes = 30}) => ExerciseLog(
  id: id,
  userId: 'u1',
  type: '달리기',
  minutes: minutes,
  intensity: ExerciseIntensity.moderate,
  kcal: 288,
  dateKey: '2026-10-18',
  time: '10:00',
);

WeightEntry _w(String id, {double kg = 60}) => WeightEntry(
  id: id,
  userId: 'u1',
  kg: kg,
  dateKey: '2026-10-18',
  time: '07:30',
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('칼로리 계산', () {
    test('kcalFor는 입력 화면과 같은 식이다 (시간 × 강도 × 종류)', () {
      expect(
        ExerciseViewModel.kcalFor(
          type: '달리기',
          minutes: 30,
          intensity: ExerciseIntensity.moderate,
        ),
        (30 * 8 * 1.2).round(),
      );
      // 모르는 종류는 계수 1.0
      expect(
        ExerciseViewModel.kcalFor(
          type: '훌라후프',
          minutes: 10,
          intensity: ExerciseIntensity.high,
        ),
        110,
      );
    });
  });

  group('ExerciseViewModel 수정 · 삭제', () {
    late _Repo<ExerciseLog> repo;
    late ExerciseViewModel vm;

    setUp(() {
      repo = _Repo<ExerciseLog>();
      vm = ExerciseViewModel(exerciseRepo: repo)
        ..uid = 'u1'
        ..exerciseLogs.clear();
    });

    test('updateExercise는 기록을 바꾸고 서버에도 저장한다', () async {
      vm.addExercise(_ex('a'));
      await _settle();
      repo.saved.clear();

      expect(vm.updateExercise(_ex('a').copyWith(minutes: 45)), isTrue);
      await _settle();

      expect(vm.exerciseLogs.single.minutes, 45);
      expect(repo.saved.single.minutes, 45);
      expect(vm.updateExercise(_ex('none')), isFalse);
    });

    test('deleteExercise는 지우고, 서버 삭제가 실패하면 같은 자리에 되돌린다', () async {
      vm.addExercise(_ex('a'));
      vm.addExercise(_ex('b'));
      vm.addExercise(_ex('c'));

      expect(vm.deleteExercise('a'), isTrue);
      await _settle();
      expect(vm.exerciseLogs.map((e) => e.id), ['b', 'c']);
      expect(repo.deletedIds, ['a']);

      repo.failDelete = true;
      var failed = 0;
      vm.onDeleteFailed = () => failed++;
      vm.deleteExercise('b');
      await _settle();
      expect(vm.exerciseLogs.map((e) => e.id), ['b', 'c']);
      expect(failed, 1);
      expect(vm.deleteExercise('none'), isFalse);
    });
  });

  group('WeightViewModel 수정 · 삭제', () {
    late _Repo<WeightEntry> repo;
    late WeightViewModel vm;

    setUp(() {
      repo = _Repo<WeightEntry>();
      vm = WeightViewModel(weightRepo: repo)
        ..uid = 'u1'
        ..weightEntries = [];
    });

    test('updateWeight는 값을 바꾸고 저장한다', () async {
      vm.weightEntries = [_w('a')];

      expect(vm.updateWeight(_w('a').copyWith(kg: 59.4)), isTrue);
      await _settle();

      expect(vm.weightEntries.single.kg, 59.4);
      expect(repo.saved.single.kg, 59.4);
      expect(vm.updateWeight(_w('none')), isFalse);
    });

    test('deleteWeight는 지우고, 서버 삭제가 실패하면 되돌린다', () async {
      vm.weightEntries = [_w('a'), _w('b')];

      vm.deleteWeight('a');
      await _settle();
      expect(vm.weightEntries.map((e) => e.id), ['b']);
      expect(repo.deletedIds, ['a']);

      repo.failDelete = true;
      var failed = 0;
      vm.onDeleteFailed = () => failed++;
      vm.deleteWeight('b');
      await _settle();
      expect(vm.weightEntries.map((e) => e.id), ['b']);
      expect(failed, 1);
    });
  });

  group('AppState 수정 · 삭제', () {
    AppState newState() => AppState(
      dependencies: memoryDependencies(now: () => DateTime(2026, 10, 18)),
    );

    test('updateExercise는 칼로리를 새 값으로 다시 계산한다', () {
      final state = newState();
      state.exType = '달리기';
      state.exMinutes = 30;
      state.logExercise();
      final id = state.exerciseViewModel.exerciseLogs.last.id;

      state.updateExercise(
        id,
        type: '걷기',
        minutes: 60,
        intensity: ExerciseIntensity.low,
      );

      final e = state.exerciseViewModel.exerciseLogs.last;
      expect(e.type, '걷기');
      expect(e.minutes, 60);
      expect(e.kcal, (60 * 5 * 0.7).round());
    });

    test('updateExercise는 빈 종류나 0분을 그대로 받지 않는다', () {
      final state = newState();
      state.exType = '달리기';
      state.exMinutes = 30;
      state.logExercise();
      final id = state.exerciseViewModel.exerciseLogs.last.id;

      state.updateExercise(
        id,
        type: '   ',
        minutes: 0,
        intensity: ExerciseIntensity.moderate,
      );

      final e = state.exerciseViewModel.exerciseLogs.last;
      expect(e.type, '달리기');
      expect(e.minutes, 1);
    });

    test('deleteExercise는 오늘 운동 시간에서 빠진다', () {
      final state = newState();
      state.exMinutes = 30;
      state.logExercise();
      final before = state.todayExerciseMinutes;
      final id = state.exerciseViewModel.exerciseLogs.last.id;

      state.deleteExercise(id);

      expect(state.todayExerciseMinutes, before - 30);
    });

    test('updateWeight와 deleteWeight는 체중 기록을 바꾸고 지운다', () {
      final state = newState();
      state.weightViewModel.setWeightInput(61.2);
      state.weightViewModel.logWeight();
      final w = state.weightViewModel.weightEntries.last;

      state.updateWeight(w.id, 60.1);
      expect(state.weightViewModel.weightEntries.last.kg, 60.1);

      state.deleteWeight(w.id);
      expect(
        state.weightViewModel.weightEntries.where((e) => e.id == w.id),
        isEmpty,
      );
    });
  });

  group('기록 탭 화면', () {
    Future<AppState> pumpRecords(WidgetTester tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final state = AppState(
        dependencies: memoryDependencies(now: () => DateTime(2026, 10, 18)),
      );
      state.exType = '달리기';
      state.exMinutes = 30;
      state.logExercise();
      state.weightViewModel.setWeightInput(61.2);
      state.weightViewModel.logWeight();
      state.navigationViewModel.go('records');
      await tester.pumpWidget(
        AppProviders(
          state: state,
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      return state;
    }

    testWidgets('그날의 운동과 체중이 목록에 나온다', (tester) async {
      await pumpRecords(tester);

      expect(find.text('달리기 30분'), findsOneWidget);
      expect(find.text('61.2 kg'), findsOneWidget);
    });

    testWidgets('운동을 눌러 시간을 고치고 저장하면 목록에 반영된다', (tester) async {
      final state = await pumpRecords(tester);

      await tester.tap(find.text('달리기 30분'));
      await tester.pumpAndSettle();
      expect(find.text('운동 수정'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), '45');
      await tester.pump();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(find.text('운동 수정'), findsNothing);
      expect(find.text('달리기 45분'), findsOneWidget);
      expect(state.exerciseViewModel.exerciseLogs.last.minutes, 45);
    });

    testWidgets('운동 삭제는 확인창에서 삭제를 눌러야 지워진다', (tester) async {
      final state = await pumpRecords(tester);
      final before = state.exerciseViewModel.exerciseLogs.length;

      await tester.tap(find.text('달리기 30분'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('운동 기록 삭제'));
      await tester.pumpAndSettle();
      expect(find.text('운동 기록을 삭제할까요?'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(state.exerciseViewModel.exerciseLogs.length, before);

      await tester.tap(find.text('운동 기록 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(state.exerciseViewModel.exerciseLogs.length, before - 1);
      expect(find.text('달리기 30분'), findsNothing);
    });

    testWidgets('체중을 눌러 값을 고치고 저장하면 목록에 반영된다', (tester) async {
      final state = await pumpRecords(tester);

      await tester.tap(find.text('61.2 kg'));
      await tester.pumpAndSettle();
      expect(find.text('체중 수정'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '60.5');
      await tester.pump();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(find.text('60.5 kg'), findsOneWidget);
      expect(state.weightViewModel.weightEntries.last.kg, 60.5);
    });

    testWidgets('체중 삭제는 확인창에서 삭제를 눌러야 지워진다', (tester) async {
      final state = await pumpRecords(tester);
      final before = state.weightViewModel.weightEntries.length;

      await tester.tap(find.text('61.2 kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('체중 기록 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(state.weightViewModel.weightEntries.length, before - 1);
      expect(find.text('61.2 kg'), findsNothing);
    });
  });
}
