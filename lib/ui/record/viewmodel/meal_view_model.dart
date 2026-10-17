import 'dart:convert';
import 'dart:async';
import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class MealViewModel extends ChangeNotifier {
  MealViewModel({
    required RecordRepository<MealLog> mealRepo,
    DateTime Function()? now,
  }) : _mealRepo = mealRepo,
       _now = now ?? DateTime.now;

  final RecordRepository<MealLog> _mealRepo;
  final DateTime Function() _now;
  final MealAnalysisService _mealAnalysisService = MealAnalysisService();

  String get _todayKey {
    final n = _now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String get _clockTime {
    final n = _now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  String _keyDaysAgo(int days) {
    final n = _now();
    final d = DateTime(n.year, n.month, n.day - days);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String? uid;
  String get _uid => uid ?? User.meId;
  late final List<MealLog> mealLogs = [..._demoPastMeals()];

  List<MealLog> mealsOn(String dateKey) =>
      mealLogs.where((m) => m.userId == _uid && m.dateKey == dateKey).toList();

  /// 오늘의 식단
  List<MealLog> get todayMeals => mealsOn(_todayKey);

  void addMeal(MealLog log) {
    mealLogs.add(log);
    notifyListeners();
    _saveMeal(log);
  }

  /// 예시 모드에서 달력 · 리포트가 비어 보이지 않도록 지난 6일치 식단을 채운다.
  /// (실제 계정은 로그인 시 예시 기록이 비워진다.)
  List<MealLog> _demoPastMeals() {
    const kcals = [
      (320, 520, 560),
      (350, 480, 610),
      (300, 560, 520),
      (340, 450, 640),
      (330, 600, 580),
      (360, 500, 540),
    ];
    const names = [
      ('그릭요거트 · 베리', '현미 비빔밥', '연어 포케 볼'),
      ('통밀 토스트 · 달걀', '닭가슴살 샐러드', '두부 스테이크'),
      ('오트밀 · 바나나', '샌드위치', '야채 볶음밥'),
      ('고구마 · 우유', '잡곡밥 · 제육볶음', '닭가슴살 샐러드'),
      ('바나나 스무디', '곤약 쫄면', '연어 구이 · 채소'),
      ('오트밀 · 블루베리', '월남쌈', '두부 샐러드'),
    ];
    const types = [MealType.breakfast, MealType.lunch, MealType.dinner];
    final out = <MealLog>[];
    for (var i = 0; i < kcals.length; i++) {
      final key = _keyDaysAgo(i+1);
      final k = [kcals[i].$1, kcals[i].$2, kcals[i].$3];
      final n = [names[i].$1, names[i].$2, names[i].$3];
      for (var m = 0; m < 3; m++) {
        out.add(
          MealLog(
            id: 'meal_seed_${i}_$m',
            userId: User.meId,
            mealType: types[m],
            name: n[m],
            meta: '집밥',
            kcal: k[m],
            dateKey: key,
            proteinG: k[m] * 0.06,
            carbG: k[m] * 0.11,
            fatG: k[m] * 0.03,
            fiberG: k[m] * 0.012,
            sodiumMg: k[m] * 1.3,
            sugarG: k[m] * 0.02,
            calciumMg: k[m] * 0.2,
            ironMg: k[m] * 0.006,
          ),
        );
      }
    }
    return out;
  }

  void _saveMeal(MealLog log) {
    if (uid == null) return;
    unawaited(
      _mealRepo.save(uid!, log).catchError((Object e, StackTrace stack) {
        debugPrint('식단 기록 저장 실패 : $e\n$stack');
      }),
    );
  }

  bool analyzingPhoto = false;
  String? photoAnalysisError;

  /// 방금 찍거나 고른 사진 원본 — 화면에 실제로 보여주는 용도.
  Uint8List? pickedPhotoBytes;
  String? aiMealName;
  int? _aiKcal;
  double? aiProteinG;
  double? aiCarbG;
  double? aiFatG;
  double? aiFiberG;
  double? aiSodiumMg;
  double? aiSugarG;
  double? aiCalciumMg;
  double? aiIronMg;
  bool needsPhotoReview = false;

  /// AI가 사진만 보고 추정한 기본 칼로리 (부가 정보 반영 전)
  int get baseKcal => _aiKcal ?? 450;

  Future<void> pickAndAnalyzeMealPhoto(ImageSource source, {Bowl? bowl}) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, imageQuality: 70);
    if (photo == null) return;

    analyzingPhoto = true;
    photoAnalysisError = null;
    notifyListeners();

    try {
      final bytes = await photo.readAsBytes();
      pickedPhotoBytes = bytes;
      final result = await _mealAnalysisService.analyze(
        imageBase64: base64Encode(bytes),
        mediaType: photo.mimeType ?? 'image/jpeg',
        bowl: bowl == null
            ? null
            : (name: bowl.name, capacityMl: bowl.capacityMl),
      );

      aiMealName = result.name;
      _aiKcal = result.kcal;
      aiProteinG = result.proteinG;
      aiCarbG = result.carbG;
      aiFatG = result.fatG;
      aiFiberG = result.fiberG;
      aiSodiumMg = result.sodiumMg;
      aiSugarG = result.sugarG;
      aiCalciumMg = result.calciumMg;
      aiIronMg = result.ironMg;
      needsPhotoReview = result.needsReview;
    } catch (e) {
      photoAnalysisError = '사진 분석에 실패했어요. 다시 시도해주세요';
      debugPrint('사진 분석 실패: $e');
    } finally {
      analyzingPhoto = false;
      notifyListeners();
    }
  }
}
