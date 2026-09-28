import 'package:cloud_functions/cloud_functions.dart';

/// recommendMeals 함수가 돌려주는 추천 메뉴 하나.
class AiMealSuggestion {
  const AiMealSuggestion({
    required this.name,
    required this.emoji,
    required this.kcal,
    required this.meta,
    required this.covers,
    required this.prefs,
    required this.meals,
    required this.tag,
    required this.why,
    required this.score,
  });

  final String name;
  final String emoji;
  final int kcal;
  final String meta;
  final List<String> covers;
  final List<String> prefs;
  final List<String> meals;
  final String tag;
  final String why;
  final int score;

  factory AiMealSuggestion.fromMap(Map<String, dynamic> map) =>
      AiMealSuggestion(
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        kcal: (map['kcal'] as num).toInt(),
        meta: map['meta'] as String,
        covers: (map['covers'] as List).cast<String>(),
        prefs: (map['prefs'] as List).cast<String>(),
        meals: (map['meals'] as List).cast<String>(),
        tag: map['tag'] as String,
        why: map['why'] as String,
        score: (map['score'] as num).toInt(),
      );
}

/// Cloud Functions의 recommendMeals를 호출하는 서비스.
class MealRecommendationService {
  MealRecommendationService({FirebaseFunctions? functions})
    : _injected = functions;

  final FirebaseFunctions? _injected;

  // AppState가 만들어지는 시점(테스트 포함)엔 Firebase가 아직 초기화되지
  // 않았을 수 있어서, 실제로 호출할 때만 늦게 가져온다.
  FirebaseFunctions get _functions => _injected ?? FirebaseFunctions.instance;

  Future<List<AiMealSuggestion>> recommend({
    required List<String> needs,
    required String meal,
    required List<String> prefs,
    required int maxKcal,
  }) async {
    final callable = _functions.httpsCallable('recommendMeals');
    final result = await callable.call<Map<String, dynamic>>({
      'needs': needs,
      'recMeal': meal,
      'recPrefs': prefs,
      'recMaxKcal': maxKcal,
    });
    final list = (result.data['recommendations'] as List).cast<Map>();
    return [
      for (final m in list)
        AiMealSuggestion.fromMap(Map<String, dynamic>.from(m)),
    ];
  }
}
