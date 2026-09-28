import 'package:cloud_functions/cloud_functions.dart';

/// analyzeMealPhoto 함수가 돌려주는 분석 결과.
class MealAnalysisResult {
  const MealAnalysisResult({
    required this.name,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.fiberG,
    required this.sodiumMg,
    required this.sugarG,
    required this.calciumMg,
    required this.ironMg,
    required this.confidence,
    required this.needsReview,
  });

  final String name;
  final int kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double fiberG;
  final double sodiumMg;
  final double sugarG;
  final double calciumMg;
  final double ironMg;
  final double confidence;
  final bool needsReview;

  factory MealAnalysisResult.fromMap(Map<String, dynamic> map) =>
      MealAnalysisResult(
        name: map['name'] as String,
        kcal: (map['kcal'] as num).toInt(),
        proteinG: (map['protein_g'] as num).toDouble(),
        carbG: (map['carb_g'] as num).toDouble(),
        fatG: (map['fat_g'] as num).toDouble(),
        fiberG: (map['fiber_g'] as num).toDouble(),
        sodiumMg: (map['sodium_mg'] as num).toDouble(),
        sugarG: (map['sugar_g'] as num).toDouble(),
        calciumMg: (map['calcium_mg'] as num).toDouble(),
        ironMg: (map['iron_mg'] as num).toDouble(),
        confidence: (map['confidence'] as num).toDouble(),
        needsReview: map['needs_review'] as bool,
      );
}

/// Cloud Functions의 analyzeMealPhoto를 호출하는 서비스.
class MealAnalysisService {
  MealAnalysisService({FirebaseFunctions? functions}) : _injected = functions;

  final FirebaseFunctions? _injected;

  // AppState 생성 시점(테스트 포함)에는 Firebase가 아직 초기화되지 않았을 수
  // 있어서, FirebaseFunctions.instance는 실제로 analyze()를 호출할 때만
  // 늦게(lazily) 가져온다.
  FirebaseFunctions get _functions => _injected ?? FirebaseFunctions.instance;

  Future<MealAnalysisResult> analyze({
    required String imageBase64,
    required String mediaType,
    ({String name, int capacityMl})? bowl,
  }) async {
    final callable = _functions.httpsCallable('analyzeMealPhoto');
    final result = await callable.call<Map<String, dynamic>>({
      'imageBase64': imageBase64,
      'mediaType': mediaType,
      if (bowl != null)
        'bowl': {'name': bowl.name, 'capacityMl': bowl.capacityMl},
    });
    return MealAnalysisResult.fromMap(Map<String, dynamic>.from(result.data));
  }
}
