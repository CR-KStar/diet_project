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

  String? uid;
  String get _uid => uid ?? User.meId;

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
