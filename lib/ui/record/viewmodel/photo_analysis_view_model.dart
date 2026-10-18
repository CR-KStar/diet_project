import 'dart:convert';

import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';

/// 사진을 고르는 방법 — 테스트에서는 갤러리 · 카메라 대신 가짜를 넣는다.
typedef PhotoPicker = Future<XFile?> Function(ImageSource source);

Future<XFile?> _pickWithImagePicker(ImageSource source) =>
    ImagePicker().pickImage(source: source, imageQuality: 70);

/// 식사 사진을 고르고 AI로 음식과 영양소를 추정하는 일을 담당한다.
///
/// 분석 결과는 식단을 저장할 때 그대로 쓰이고, 저장이 끝나면 [reset]으로 비운다.
/// 어느 그릇으로 먹었는지, 부가 정보를 반영한 칼로리가 얼마인지는 식단 입력값과
/// 만나는 부분이라 AppState가 맡고, 여기서는 사진 분석만 다룬다.
class PhotoAnalysisViewModel extends ChangeNotifier {
  PhotoAnalysisViewModel({
    required MealAnalysisService service,
    PhotoPicker? picker,
  }) : _service = service,
       _picker = picker ?? _pickWithImagePicker;

  final MealAnalysisService _service;
  final PhotoPicker _picker;

  bool analyzingPhoto = false;
  String? photoAnalysisError;

  /// 방금 찍거나 고른 사진 원본 — 화면에 실제로 보여주는 용도.
  Uint8List? pickedPhotoBytes;

  /// 마지막으로 받은 분석 결과. 아직 분석하지 않았으면 null.
  MealAnalysisResult? _result;

  String? get aiMealName => _result?.name;
  double? get aiProteinG => _result?.proteinG;
  double? get aiCarbG => _result?.carbG;
  double? get aiFatG => _result?.fatG;
  double? get aiFiberG => _result?.fiberG;
  double? get aiSodiumMg => _result?.sodiumMg;
  double? get aiSugarG => _result?.sugarG;
  double? get aiCalciumMg => _result?.calciumMg;
  double? get aiIronMg => _result?.ironMg;
  bool get needsPhotoReview => _result?.needsReview ?? false;

  /// AI가 사진만 보고 추정한 기본 칼로리 (부가 정보 반영 전).
  /// 분석 전(직접 기록)에는 450kcal로 시작한다.
  int get baseKcal => _result?.kcal ?? 450;

  /// 사진을 고르고 즉시 AI 분석을 요청한다. 고르기를 취소하면 아무것도 하지 않는다.
  Future<void> pickAndAnalyze(ImageSource source, {Bowl? bowl}) async {
    final photo = await _picker(source);
    if (photo == null) return;

    analyzingPhoto = true;
    photoAnalysisError = null;
    notifyListeners();

    try {
      final bytes = await photo.readAsBytes();
      pickedPhotoBytes = bytes;
      _result = await _service.analyze(
        imageBase64: base64Encode(bytes),
        mediaType: photo.mimeType ?? 'image/jpeg',
        bowl: bowl == null
            ? null
            : (name: bowl.name, capacityMl: bowl.capacityMl),
      );
    } catch (e) {
      photoAnalysisError = '사진 분석에 실패했어요. 다시 시도해주세요.';
      debugPrint('사진 분석 실패: $e');
    } finally {
      analyzingPhoto = false;
      notifyListeners();
    }
  }

  /// 이번 분석 결과를 비운다 — 다음 끼니를 새 사진 없이 저장해도 방금 분석값을
  /// 재사용하지 않고 0(분석 안 함)으로 시작하게 한다.
  void reset() {
    pickedPhotoBytes = null;
    _result = null;
    notifyListeners();
  }
}
