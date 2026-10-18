import 'package:diet_project/domain/models/models.dart';

/// 부족한 영양소 · 끼니 · 선호 조건을 보내 메뉴를 추천받는 서비스.
/// 화면 쪽(ViewModel)은 이 인터페이스만 알고, 실제 호출 방법(Cloud Functions)은 구현이 안다.
abstract class MealRecommendationService {
  Future<List<AiMealSuggestion>> recommend({
    required List<String> needs,
    required String meal,
    required List<String> prefs,
    required int maxKcal,
  });
}
