import 'dart:io';
import 'dart:typed_data';

import 'package:diet_project/app_composition.dart';
import 'package:diet_project/app_providers.dart';
import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/data/services/impl/file_meal_photo_store.dart';
import 'package:diet_project/data/services/impl/memory_meal_photo_store.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// 1x1 투명 PNG — Image.memory가 실제로 그릴 수 있는 가장 작은 이미지.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _FakeAnalysis implements MealAnalysisService {
  @override
  Future<MealAnalysisResult> analyze({
    required String imageBase64,
    required String mediaType,
    ({String name, int capacityMl})? bowl,
  }) async => const MealAnalysisResult(
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
    confidence: 0.9,
    needsReview: false,
  );
}

AppState _state(MemoryMealPhotoStore store) => AppState(
  dependencies: memoryDependencies(
    mealAnalysisService: _FakeAnalysis(),
    mealPhotoStore: store,
    now: () => DateTime(2026, 10, 18),
  ),
  photoPicker: (source) async => XFile.fromData(_png, mimeType: 'image/png'),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('FileMealPhotoStore (실제 파일)', () {
    late Directory tmp;
    late FileMealPhotoStore store;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('meal_photos_test');
      store = FileMealPhotoStore(baseDir: () async => Directory(tmp.path));
    });
    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('저장한 사진을 다시 읽을 수 있고, 새 보관소로 열어도 파일에 남아 있다', () async {
      await store.save('meal_1', _png);

      expect(await store.load('meal_1'), _png);
      // 앱을 껐다 켠 것처럼 새 객체로 열어도 디스크에 있어야 한다.
      final reopened = FileMealPhotoStore(
        baseDir: () async => Directory(tmp.path),
      );
      expect(await reopened.load('meal_1'), _png);
    });

    test('없는 사진은 null이고, delete는 없어도 오류가 아니다', () async {
      expect(await store.load('none'), isNull);
      await store.delete('none');
    });

    test('delete는 그 사진만 지운다', () async {
      await store.save('a', _png);
      await store.save('b', _png);

      await store.delete('a');

      expect(
        await FileMealPhotoStore(
          baseDir: () async => Directory(tmp.path),
        ).load('a'),
        isNull,
      );
      expect(await store.load('b'), _png);
    });

    test('deleteAll은 모두 지운다', () async {
      await store.save('a', _png);
      await store.save('b', _png);

      await store.deleteAll();

      final fresh = FileMealPhotoStore(
        baseDir: () async => Directory(tmp.path),
      );
      expect(await fresh.load('a'), isNull);
      expect(await fresh.load('b'), isNull);
    });

    test('경로가 섞인 id는 저장하지도 읽지도 않는다', () async {
      await store.save('../evil', _png);

      expect(await store.load('../evil'), isNull);
      expect(File('${tmp.parent.path}/evil.jpg').existsSync(), isFalse);
    });
  });

  group('저장 형식', () {
    test('photoId는 저장했다가 읽으면 그대로 돌아온다', () {
      final state = AppState(dependencies: memoryDependencies());
      state.logMeal();
      final base = state.todayMeals.last;
      final withPhoto = base.copyWith(); // copyWith는 photoId를 지키는지 확인용

      final map = mealCodec.toMap(withPhoto);
      expect(map['photoId'], isNull);

      final restored = mealCodec.fromMap('m1', {
        ...map,
        'photoId': 'meal_77',
      }, 'u1');
      expect(restored.photoId, 'meal_77');
      expect(restored.copyWith(name: '바꿈').photoId, 'meal_77');
    });

    test('예전 기록(photoId 없음)도 읽는다', () {
      final restored = mealCodec.fromMap('m1', {'name': '밥'}, 'u1');
      expect(restored.photoId, isNull);
    });
  });

  group('AppState · 식단 사진 보관', () {
    test('사진을 찍어 기록하면 이 기기에 사진이 보관되고 기록에 photoId가 붙는다', () async {
      final store = MemoryMealPhotoStore();
      final state = _state(store);
      await state.pickAndAnalyzeMealPhoto(ImageSource.gallery);

      state.logMeal();
      await _settle();

      final m = state.todayMeals.last;
      expect(m.photoId, isNotNull);
      expect(await store.load(m.photoId!), _png);
    });

    test('사진 없이 직접 기록하면 photoId가 없다', () async {
      final store = MemoryMealPhotoStore();
      final state = _state(store);

      state.logMeal();

      expect(state.todayMeals.last.photoId, isNull);
    });

    test('식단을 고쳐도 사진은 그대로다', () async {
      final store = MemoryMealPhotoStore();
      final state = _state(store);
      await state.pickAndAnalyzeMealPhoto(ImageSource.gallery);
      state.logMeal();
      await _settle();
      final before = state.todayMeals.last;

      state.updateMeal(
        before.id,
        name: '새 이름',
        kcal: 100,
        mealType: before.mealType,
      );

      final after = state.mealViewModel.mealById(before.id)!;
      expect(after.photoId, before.photoId);
      expect(await store.load(after.photoId!), _png);
    });

    test('식단을 삭제하면 그 사진도 지운다', () async {
      final store = MemoryMealPhotoStore();
      final state = _state(store);
      await state.pickAndAnalyzeMealPhoto(ImageSource.gallery);
      state.logMeal();
      await _settle();
      final m = state.todayMeals.last;

      state.deleteMeal(m.id);
      await _settle();

      expect(await store.load(m.photoId!), isNull);
    });
  });

  group('기록 화면의 사진', () {
    Future<AppState> pumpRecords(
      WidgetTester tester, {
      required bool withPhoto,
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

      final store = MemoryMealPhotoStore();
      final state = _state(store);
      if (withPhoto) await state.pickAndAnalyzeMealPhoto(ImageSource.gallery);
      state.logMeal();
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

    testWidgets('사진으로 기록한 식단은 목록 왼쪽 네모칸에 사진이 나온다', (tester) async {
      await pumpRecords(tester, withPhoto: true);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('사진 없이 기록한 식단은 자리표시만 나온다', (tester) async {
      await pumpRecords(tester, withPhoto: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('사진 파일이 깨져 있어도 오류 없이 자리표시로 보인다', (tester) async {
      final state = await pumpRecords(tester, withPhoto: true);
      // 보관된 사진을 깨진 데이터로 바꿔서 같은 화면을 다시 그린다.
      await state.mealPhotoStore.save(
        state.todayMeals.last.photoId!,
        Uint8List.fromList(const [1, 2, 3]),
      );
      state.navigationViewModel.go('home');
      await tester.pump(const Duration(milliseconds: 300));
      state.navigationViewModel.go('records');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(PhotoPlaceholder), findsWidgets);
    });

    testWidgets('식단 상세에는 큰 사진이 나온다', (tester) async {
      final state = await pumpRecords(tester, withPhoto: true);
      state.openMeal(state.todayMeals.last);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
