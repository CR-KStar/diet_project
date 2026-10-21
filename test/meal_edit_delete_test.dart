import 'dart:typed_data';

import 'package:diet_project/app_composition.dart';
import 'package:diet_project/app_providers.dart';
import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/ui/record/viewmodel/meal_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// 저장 · 삭제 호출을 기록하고, 삭제를 실패시킬 수 있는 가짜 저장소.
class _RecordingRepo implements RecordRepository<MealLog> {
  final saved = <MealLog>[];
  final deletedIds = <String>[];
  bool failDelete = false;

  @override
  Future<List<MealLog>> loadAll(String uid) async => [];

  @override
  Future<List<MealLog>> loadRange(
    String uid,
    String fromKey,
    String toKey,
  ) async => [];

  @override
  Future<void> save(String uid, MealLog entry) async => saved.add(entry);

  @override
  Future<void> delete(String uid, String id) async {
    if (failDelete) throw Exception('network down');
    deletedIds.add(id);
  }

  @override
  Future<void> deleteAll(String uid) async {}
}

MealLog _meal(String id, {bool needsReview = false}) => MealLog(
  id: id,
  userId: 'u1',
  mealType: MealType.lunch,
  name: '비빔밥',
  meta: '기록',
  kcal: 600,
  dateKey: '2026-10-18',
  needsReview: needsReview,
);

/// AI 분석 결과를 정해서 돌려주는 가짜 서비스.
class _FakeAnalysis implements MealAnalysisService {
  _FakeAnalysis({required this.needsReview});

  final bool needsReview;

  @override
  Future<MealAnalysisResult> analyze({
    required String imageBase64,
    required String mediaType,
    ({String name, int capacityMl})? bowl,
  }) async => MealAnalysisResult(
    name: '김치찌개',
    kcal: 480,
    proteinG: 25,
    carbG: 30,
    fatG: 20,
    fiberG: 4,
    sodiumMg: 1200,
    sugarG: 5,
    calciumMg: 80,
    ironMg: 3,
    confidence: needsReview ? 0.4 : 0.9,
    needsReview: needsReview,
  );
}

Future<AppState> _stateWithPhotoMeal({required bool needsReview}) async {
  final state = AppState(
    dependencies: memoryDependencies(
      mealAnalysisService: _FakeAnalysis(needsReview: needsReview),
      now: () => DateTime(2026, 10, 18),
    ),
    photoPicker: (source) async =>
        XFile.fromData(Uint8List.fromList([1, 2, 3]), mimeType: 'image/png'),
  );
  await state.pickAndAnalyzeMealPhoto(ImageSource.gallery);
  state.logMeal();
  return state;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('MealViewModel 수정 · 삭제', () {
    late _RecordingRepo repo;
    late MealViewModel vm;

    setUp(() {
      repo = _RecordingRepo();
      vm = MealViewModel(mealRepo: repo)
        ..uid = 'u1'
        ..mealLogs.clear();
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('updateMeal은 목록의 기록을 바꾸고 서버에도 저장한다', () async {
      vm.addMeal(_meal('a'));
      await settle();
      repo.saved.clear();

      final ok = vm.updateMeal(_meal('a').copyWith(name: '김치찌개', kcal: 480));
      await settle();

      expect(ok, isTrue);
      expect(vm.mealById('a')!.name, '김치찌개');
      expect(vm.mealById('a')!.kcal, 480);
      expect(repo.saved.single.name, '김치찌개');
    });

    test('없는 id를 고치거나 지우면 false이고 아무것도 하지 않는다', () async {
      expect(vm.updateMeal(_meal('none')), isFalse);
      expect(vm.deleteMeal('none'), isFalse);
      await settle();
      expect(repo.deletedIds, isEmpty);
    });

    test('deleteMeal은 목록에서 지우고 서버에서도 지운다', () async {
      vm.addMeal(_meal('a'));
      vm.addMeal(_meal('b'));

      expect(vm.deleteMeal('a'), isTrue);
      await settle();

      expect(vm.mealLogs.map((m) => m.id), ['b']);
      expect(repo.deletedIds, ['a']);
    });

    test('서버에서 지우지 못하면 같은 자리에 되돌리고 알린다', () async {
      vm.addMeal(_meal('a'));
      vm.addMeal(_meal('b'));
      vm.addMeal(_meal('c'));
      repo.failDelete = true;
      var failed = 0;
      vm.onDeleteFailed = () => failed++;

      vm.deleteMeal('b');
      await settle();

      expect(vm.mealLogs.map((m) => m.id), ['a', 'b', 'c']);
      expect(failed, 1);
    });

    test('로그인하지 않은 체험 상태에서는 서버를 부르지 않고 목록만 지운다', () async {
      vm.uid = null;
      vm.mealLogs.add(_meal('a'));

      expect(vm.deleteMeal('a'), isTrue);
      await settle();

      expect(vm.mealLogs, isEmpty);
      expect(repo.deletedIds, isEmpty);
    });
  });

  group('AppState · 확인 필요 표시', () {
    test('AI가 확신하지 못했을 때만 "확인 필요"가 붙는다', () async {
      final flagged = await _stateWithPhotoMeal(needsReview: true);
      expect(flagged.todayMeals.last.needsReview, isTrue);

      final sure = await _stateWithPhotoMeal(needsReview: false);
      expect(sure.todayMeals.last.needsReview, isFalse);
    });

    test('사진 분석 없이 직접 기록하면 "확인 필요"가 붙지 않는다', () {
      final state = AppState(dependencies: memoryDependencies());
      state.logMeal();
      expect(state.todayMeals.last.needsReview, isFalse);
    });

    test('confirmMeal은 표시만 떼고 내용은 그대로 둔다', () async {
      final state = await _stateWithPhotoMeal(needsReview: true);
      final before = state.todayMeals.last;

      state.confirmMeal(before.id);

      final after = state.todayMeals.last;
      expect(after.needsReview, isFalse);
      expect(after.name, before.name);
      expect(after.kcal, before.kcal);
    });
  });

  group('AppState · 식단 수정 · 삭제', () {
    test('updateMeal은 이름 · 칼로리 · 끼니를 바꾸고 확인 필요를 뗀다', () async {
      final state = await _stateWithPhotoMeal(needsReview: true);
      final id = state.todayMeals.last.id;
      state.navigationViewModel.setEditing(true);

      state.updateMeal(
        id,
        name: '  된장찌개 ',
        kcal: 321,
        mealType: MealType.dinner,
      );

      final m = state.mealViewModel.mealById(id)!;
      expect(m.name, '된장찌개');
      expect(m.kcal, 321);
      expect(m.mealType, MealType.dinner);
      expect(m.needsReview, isFalse);
      expect(state.navigationViewModel.editing, isFalse);
    });

    test('이름을 비워서 저장해도 기존 이름을 지키고, 칼로리는 음수가 되지 않는다', () async {
      final state = await _stateWithPhotoMeal(needsReview: false);
      final m = state.todayMeals.last;

      state.updateMeal(m.id, name: '   ', kcal: -5, mealType: m.mealType);

      final after = state.mealViewModel.mealById(m.id)!;
      expect(after.name, m.name);
      expect(after.kcal, 0);
    });

    test('deleteMeal은 기록을 지우고 기록 탭으로 돌아간다', () async {
      final state = await _stateWithPhotoMeal(needsReview: false);
      final before = state.todayMeals.length;
      final id = state.todayMeals.last.id;
      state.navigationViewModel.go('mealDetail');

      state.deleteMeal(id);

      expect(state.todayMeals.length, before - 1);
      expect(state.mealViewModel.mealById(id), isNull);
      expect(state.navigationViewModel.screen, 'records');
    });
  });

  group('식단 상세 화면', () {
    Future<AppState> pumpDetail(
      WidgetTester tester, {
      required bool needsReview,
    }) async {
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final state = await _stateWithPhotoMeal(needsReview: needsReview);
      state.openMeal(state.todayMeals.last);
      await tester.pumpWidget(
        AppProviders(
          state: state,
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      return state;
    }

    testWidgets('확인이 필요한 기록은 "맞아요"로 표시를 뗀다', (tester) async {
      final state = await pumpDetail(tester, needsReview: true);
      expect(find.text('확인 필요'), findsOneWidget);

      await tester.tap(find.text('맞아요'));
      await tester.pump();

      expect(find.text('확인 필요'), findsNothing);
      expect(state.todayMeals.last.needsReview, isFalse);
    });

    testWidgets('수정하기로 이름을 바꿔 저장하면 상세에 반영된다', (tester) async {
      final state = await pumpDetail(tester, needsReview: false);

      await tester.tap(find.text('수정하기'));
      await tester.pump();
      expect(find.text('식단 수정'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '된장찌개');
      await tester.pump();
      await tester.tap(find.text('저장'));
      await tester.pump();

      expect(find.text('식단 수정'), findsNothing);
      expect(find.text('된장찌개'), findsOneWidget);
      expect(state.todayMeals.last.name, '된장찌개');
    });

    testWidgets('수정 중 취소하면 바뀐 내용 없이 상세로 돌아간다', (tester) async {
      final state = await pumpDetail(tester, needsReview: false);
      final name = state.todayMeals.last.name;

      await tester.tap(find.text('수정하기'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '바뀐 이름');
      await tester.tap(find.text('취소'));
      await tester.pump();

      expect(find.text('식단 상세'), findsOneWidget);
      expect(find.text(name), findsOneWidget);
      expect(state.todayMeals.last.name, name);
    });

    testWidgets('식단 삭제는 확인창에서 삭제를 눌러야 지워진다', (tester) async {
      final state = await pumpDetail(tester, needsReview: false);
      final before = state.todayMeals.length;

      await tester.tap(find.text('식단 삭제'));
      await tester.pumpAndSettle();
      expect(find.text('식단을 삭제할까요?'), findsOneWidget);

      // 취소하면 그대로다.
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(state.todayMeals.length, before);

      await tester.tap(find.text('식단 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(state.todayMeals.length, before - 1);
      expect(state.navigationViewModel.screen, 'records');
    });
  });
}
