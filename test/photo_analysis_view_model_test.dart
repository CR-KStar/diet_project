import 'dart:typed_data';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';
import 'package:diet_project/ui/record/viewmodel/photo_analysis_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

MealAnalysisResult _result({
  String name = '비빔밥',
  int kcal = 620,
  bool needsReview = false,
}) => MealAnalysisResult(
  name: name,
  kcal: kcal,
  proteinG: 21,
  carbG: 90,
  fatG: 14,
  fiberG: 6,
  sodiumMg: 900,
  sugarG: 8,
  calciumMg: 120,
  ironMg: 3,
  confidence: 0.8,
  needsReview: needsReview,
);

/// 받은 요청을 기록하고, 결과 · 실패를 정할 수 있는 가짜 분석 서비스.
class _FakeService extends MealAnalysisService {
  MealAnalysisResult result = _result();
  bool fail = false;
  int calls = 0;
  String? lastBase64;
  String? lastMediaType;
  ({String name, int capacityMl})? lastBowl;

  @override
  Future<MealAnalysisResult> analyze({
    required String imageBase64,
    required String mediaType,
    ({String name, int capacityMl})? bowl,
  }) async {
    calls++;
    lastBase64 = imageBase64;
    lastMediaType = mediaType;
    lastBowl = bowl;
    if (fail) throw Exception('network down');
    return result;
  }
}

void main() {
  late _FakeService service;
  late PhotoAnalysisViewModel vm;
  XFile? picked;
  ImageSource? askedSource;

  setUp(() {
    service = _FakeService();
    picked = XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/png',
    );
    askedSource = null;
    vm = PhotoAnalysisViewModel(
      service: service,
      picker: (source) async {
        askedSource = source;
        return picked;
      },
    );
  });

  group('PhotoAnalysisViewModel', () {
    test('분석 전에는 결과가 없고, 기본 칼로리는 450이다', () {
      expect(vm.aiMealName, isNull);
      expect(vm.aiProteinG, isNull);
      expect(vm.needsPhotoReview, isFalse);
      expect(vm.pickedPhotoBytes, isNull);
      expect(vm.baseKcal, 450);
    });

    test('사진을 고르면 분석을 요청하고 결과를 보여 준다', () async {
      service.result = _result(name: '김치찌개', kcal: 480, needsReview: true);

      await vm.pickAndAnalyze(ImageSource.gallery);

      expect(askedSource, ImageSource.gallery);
      expect(vm.pickedPhotoBytes, [1, 2, 3]);
      expect(vm.aiMealName, '김치찌개');
      expect(vm.baseKcal, 480);
      expect(vm.aiProteinG, 21);
      expect(vm.aiCarbG, 90);
      expect(vm.aiFatG, 14);
      expect(vm.aiFiberG, 6);
      expect(vm.aiSodiumMg, 900);
      expect(vm.aiSugarG, 8);
      expect(vm.aiCalciumMg, 120);
      expect(vm.aiIronMg, 3);
      expect(vm.needsPhotoReview, isTrue);
      expect(vm.photoAnalysisError, isNull);
    });

    test('사진은 base64로, 파일 형식과 그릇 정보와 함께 보낸다', () async {
      final bowl = Bowl(
        id: 'b',
        userId: User.meId,
        name: '회사 도시락',
        capacityMl: 500,
        portion: '1인분',
        material: '플라스틱',
        shape: '도시락',
      );

      await vm.pickAndAnalyze(ImageSource.camera, bowl: bowl);

      expect(service.lastBase64, 'AQID');
      expect(service.lastMediaType, 'image/png');
      expect(service.lastBowl, (name: '회사 도시락', capacityMl: 500));
    });

    test('파일 형식을 모르면 jpeg로 보내고, 그릇이 없으면 그릇 정보도 보내지 않는다', () async {
      picked = XFile.fromData(Uint8List.fromList([9]));

      await vm.pickAndAnalyze(ImageSource.camera);

      expect(service.lastMediaType, 'image/jpeg');
      expect(service.lastBowl, isNull);
    });

    test('분석하는 동안 analyzingPhoto가 켜졌다가 끝나면 꺼진다', () async {
      final states = <bool>[];
      vm.addListener(() => states.add(vm.analyzingPhoto));

      await vm.pickAndAnalyze(ImageSource.gallery);

      expect(states, [true, false]);
    });

    test('고르기를 취소하면 아무 일도 일어나지 않는다', () async {
      picked = null;
      var notified = 0;
      vm.addListener(() => notified++);

      await vm.pickAndAnalyze(ImageSource.gallery);

      expect(service.calls, 0);
      expect(notified, 0);
      expect(vm.analyzingPhoto, isFalse);
    });

    test('분석이 실패하면 오류 문구를 보여 주고 결과는 비어 있다', () async {
      service.fail = true;

      await vm.pickAndAnalyze(ImageSource.gallery);

      expect(vm.photoAnalysisError, '사진 분석에 실패했어요. 다시 시도해주세요.');
      expect(vm.aiMealName, isNull);
      expect(vm.analyzingPhoto, isFalse);
      expect(vm.baseKcal, 450);
    });

    test('다시 시도해서 성공하면 오류 문구가 사라진다', () async {
      service.fail = true;
      await vm.pickAndAnalyze(ImageSource.gallery);

      service.fail = false;
      await vm.pickAndAnalyze(ImageSource.gallery);

      expect(vm.photoAnalysisError, isNull);
      expect(vm.aiMealName, '비빔밥');
    });

    test('reset: 사진과 분석 결과를 모두 비운다', () async {
      await vm.pickAndAnalyze(ImageSource.gallery);

      vm.reset();

      expect(vm.pickedPhotoBytes, isNull);
      expect(vm.aiMealName, isNull);
      expect(vm.aiProteinG, isNull);
      expect(vm.needsPhotoReview, isFalse);
      expect(vm.baseKcal, 450);
    });
  });

  group('AppState 연결', () {
    late AppState s;

    setUp(() {
      s = AppState(photoAnalysisViewModel: vm);
    });

    test('분석할 때 지금 고른 그릇을 함께 보낸다', () async {
      await s.pickAndAnalyzeMealPhoto(ImageSource.gallery);

      expect(service.lastBowl, (
        name: s.currentBowl!.name,
        capacityMl: s.currentBowl!.capacityMl,
      ));
      expect(s.aiMealName, '비빔밥');
      expect(s.baseKcal, 620);
    });

    test('분석 결과로 식단을 기록하면 영양소가 담기고, 결과는 비워진다', () async {
      await s.pickAndAnalyzeMealPhoto(ImageSource.gallery);
      final before = s.todayMeals.length;

      s.logMeal();

      final log = s.todayMeals.last;
      expect(s.todayMeals, hasLength(before + 1));
      expect(log.name, '비빔밥');
      expect(log.proteinG, 21);
      expect(log.sodiumMg, 900);
      // 다음 끼니에 이번 분석값을 다시 쓰지 않는다.
      expect(s.aiMealName, isNull);
      expect(s.pickedPhotoBytes, isNull);
      expect(s.baseKcal, 450);
    });

    test('분석 없이 기록하면 "직접 기록"으로 남고 영양소는 0이다', () {
      s.logMeal();

      final log = s.todayMeals.last;
      expect(log.name, '식사 (직접 기록)');
      expect(log.proteinG, 0);
      expect(log.carbG, 0);
    });

    test('분석 상태가 바뀌면 화면이 구독하는 ViewModel에 전달된다', () async {
      var notified = 0;
      s.photoAnalysisViewModel.addListener(() => notified++);

      await s.pickAndAnalyzeMealPhoto(ImageSource.gallery);

      expect(notified, greaterThanOrEqualTo(2)); // 분석 시작 · 끝
    });
  });
}
