import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_project/data/services/meal_recommendation_service.dart';

/// 식단 추천 화면의 조건(부족한 영양소 · 끼니 · 선호 · 최대 칼로리 · 정렬)과
/// 추천 결과를 담당한다.
///
/// 추천은 AI(Cloud Functions)에게 받고, 아직 못 받았거나 실패했을 때는 아래
/// 규칙 기반 목록으로 대신한다. 외부 AI로 보내도 되는지 묻는 동의는 사진 분석과
/// 함께 쓰는 값이라 AppState가 갖고 있고, 여기서는 요청만 처리한다.
class RecommendationViewModel extends ChangeNotifier {
  RecommendationViewModel({required this._service});

  final MealRecommendationService _service;

  List<String> needs = ['식이섬유', '칼슘'];
  String recMeal = '저녁';
  List<String> recPrefs = ['채식 위주'];
  int recMaxKcal = 600;
  String recSort = '추천순';

  static const needOptions = [
    '탄수화물',
    '단백질',
    '지방',
    '식이섬유',
    '칼슘',
    '철분',
    '비타민D',
    '오메가3',
  ];

  static const _pool = <MealSuggestion>[
    MealSuggestion(
      name: '현미밥 · 두부구이 · 브로콜리',
      emoji: '🍚',
      kcal: 520,
      meta: '탄수화물 68g · 식이섬유 9g · 칼슘 240mg · 단백질 26g',
      covers: ['탄수화물', '식이섬유', '칼슘', '단백질'],
      prefs: ['채식 위주', '저나트륨'],
      meals: ['점심', '저녁'],
      tag: '집밥',
      why: '식이섬유와 칼슘을 한 끼로 함께 채울 수 있어요.',
    ),
    MealSuggestion(
      name: '연어 샐러드 · 통밀빵',
      emoji: '🥗',
      kcal: 480,
      meta: '오메가3 1.8g · 지방 22g · 식이섬유 7g · 단백질 30g',
      covers: ['오메가3', '지방', '식이섬유', '단백질'],
      prefs: ['고단백', '간편식'],
      meals: ['점심', '저녁'],
      tag: '15분',
      why: '조리 없이 준비할 수 있고 좋은 지방과 단백질이 넉넉해요.',
    ),
    MealSuggestion(
      name: '병아리콩 커리 · 현미',
      emoji: '🍛',
      kcal: 560,
      meta: '탄수화물 74g · 식이섬유 12g · 철분 5mg',
      covers: ['탄수화물', '식이섬유', '철분'],
      prefs: ['채식 위주'],
      meals: ['점심', '저녁'],
      tag: '든든',
      why: '탄수화물과 식이섬유를 한 번에 채워요.',
    ),
    MealSuggestion(
      name: '그릭요거트 · 아몬드 · 블루베리',
      emoji: '🫐',
      kcal: 280,
      meta: '칼슘 300mg · 단백질 18g',
      covers: ['칼슘', '단백질'],
      prefs: ['간편식'],
      meals: ['아침', '간식'],
      tag: '5분',
      why: '간식으로 칼슘과 단백질을 함께 챙길 수 있어요.',
    ),
    MealSuggestion(
      name: '닭가슴살 스테이크 · 시금치',
      emoji: '🍗',
      kcal: 430,
      meta: '단백질 38g · 철분 4mg',
      covers: ['단백질', '철분'],
      prefs: ['고단백', '저나트륨'],
      meals: ['점심', '저녁'],
      tag: '고단백',
      why: '단백질 목표가 남았을 때 가장 효율적이에요.',
    ),
    MealSuggestion(
      name: '오트밀 · 바나나 · 우유',
      emoji: '🥛',
      kcal: 320,
      meta: '탄수화물 52g · 식이섬유 8g · 칼슘 320mg',
      covers: ['탄수화물', '식이섬유', '칼슘'],
      prefs: ['간편식', '채식 위주'],
      meals: ['아침', '간식'],
      tag: '5분',
      why: '아침 탄수화물과 칼슘을 동시에 챙기는 조합이에요.',
    ),
    MealSuggestion(
      name: '고구마 · 삶은 달걀 · 그린샐러드',
      emoji: '🍠',
      kcal: 380,
      meta: '탄수화물 54g · 식이섬유 7g · 단백질 16g',
      covers: ['탄수화물', '식이섬유', '단백질'],
      prefs: ['간편식', '채식 위주'],
      meals: ['아침', '점심', '간식'],
      tag: '10분',
      why: '탄수화물이 부족한 날 혈당 부담이 적은 선택이에요.',
    ),
    MealSuggestion(
      name: '아보카도 통밀 토스트 · 달걀',
      emoji: '🥑',
      kcal: 420,
      meta: '지방 26g · 탄수화물 34g · 식이섬유 9g',
      covers: ['지방', '탄수화물', '식이섬유'],
      prefs: ['간편식', '채식 위주'],
      meals: ['아침', '점심'],
      tag: '10분',
      why: '지방이 부족할 때 불포화지방으로 채우기 좋아요.',
    ),
    MealSuggestion(
      name: '견과 한 줌 · 무가당 요거트',
      emoji: '🥜',
      kcal: 260,
      meta: '지방 19g · 칼슘 210mg · 단백질 12g',
      covers: ['지방', '칼슘', '단백질'],
      prefs: ['간편식'],
      meals: ['간식'],
      tag: '즉시',
      why: '간식으로 좋은 지방과 칼슘을 함께 보충해요.',
    ),
    MealSuggestion(
      name: '고등어 구이 · 현미밥',
      emoji: '🐟',
      kcal: 540,
      meta: '오메가3 2.2g · 비타민D 12µg · 단백질 32g',
      covers: ['오메가3', '비타민D', '단백질'],
      prefs: ['저나트륨'],
      meals: ['점심', '저녁'],
      tag: '집밥',
      why: '비타민D와 오메가3를 한 번에 채우는 메뉴예요.',
    ),
    MealSuggestion(
      name: '두부 김치 볶음 · 현미',
      emoji: '🍲',
      kcal: 470,
      meta: '단백질 24g · 식이섬유 8g',
      covers: ['단백질', '식이섬유'],
      prefs: ['채식 위주'],
      meals: ['점심', '저녁'],
      tag: '집밥',
      why: '익숙한 조합으로 단백질을 채울 수 있어요.',
    ),
    MealSuggestion(
      name: '새우 두부면 파스타',
      emoji: '🍝',
      kcal: 410,
      meta: '단백질 34g · 식이섬유 7g',
      covers: ['단백질', '식이섬유'],
      prefs: ['고단백', '간편식'],
      meals: ['점심', '저녁'],
      tag: '20분',
      why: '면이 먹고 싶을 때 칼로리 부담을 줄인 선택이에요.',
    ),
  ];

  /// 조건 기반 추천 결과 (점수 내림차순 또는 칼로리 오름차순)
  List<AiMealSuggestion>? aiRecommendations;
  bool loadingRecommendations = false;
  String? recommendationError;

  /// AI에게 지금 조건(needs · recMeal · recPrefs · recMaxKcal)으로 추천을 요청한다.
  Future<void> fetchAiRecommendations() async {
    loadingRecommendations = true;
    recommendationError = null;
    notifyListeners();
    try {
      aiRecommendations = await _service.recommend(
        needs: needs,
        meal: recMeal,
        prefs: recPrefs,
        maxKcal: recMaxKcal,
      );
    } catch (e, stack) {
      debugPrint('식단 추천을 받지 못했어요: $e\n$stack');
      recommendationError = '추천을 불러오지 못했어요. 다시 시도해주세요.';
    } finally {
      loadingRecommendations = false;
      notifyListeners();
    }
  }

  List<({MealSuggestion meal, int score, bool offMeal})> get recommendations {
    final ai = aiRecommendations;
    if (ai != null) {
      final scored = [
        for (final s in ai)
          (
            meal: MealSuggestion(
              name: s.name,
              emoji: s.emoji,
              kcal: s.kcal,
              meta: s.meta,
              covers: s.covers,
              prefs: s.prefs,
              meals: s.meals,
              tag: s.tag,
              why: s.why,
            ),
            score: s.score,
            offMeal: !s.meals.contains(recMeal),
          ),
      ];
      scored.sort(
        (a, b) => recSort == '칼로리 낮은 순'
            ? a.meal.kcal.compareTo(b.meal.kcal)
            : b.score.compareTo(a.score),
      );
      return scored;
    }

    // AI 추천을 아직 못 받아왔을 때(로딩 중 · 실패)는 예전 규칙 기반 추천으로 대체한다.
    int raw(MealSuggestion m) =>
        m.covers.where(needs.contains).length * 30 +
        m.prefs.where(recPrefs.contains).length * 14 +
        20;

    final matched = _pool
        .where((m) => m.kcal <= recMaxKcal && m.meals.contains(recMeal))
        .toList();
    final base = matched.length >= 3
        ? matched
        : _pool.where((m) => m.kcal <= recMaxKcal).toList();
    if (base.isEmpty) return [];

    final top = base.map(raw).reduce((a, b) => a > b ? a : b).clamp(1, 9999);

    final scored = base.map((m) {
      final off = !m.meals.contains(recMeal);
      final s = ((raw(m) / top) * 96).round() - (off ? 18 : 0);
      return (meal: m, score: s < 52 ? 52 : s, offMeal: off);
    }).toList();

    scored.sort(
      (a, b) => recSort == '칼로리 낮은 순'
          ? a.meal.kcal.compareTo(b.meal.kcal)
          : b.score.compareTo(a.score),
    );
    return scored;
  }

  void toggleNeed(String n) {
    needs.contains(n) ? needs.remove(n) : needs.add(n);
    notifyListeners();
  }

  void togglePref(String p) {
    recPrefs.contains(p) ? recPrefs.remove(p) : recPrefs.add(p);
    notifyListeners();
  }

  void setRecMeal(String m) {
    recMeal = m;
    notifyListeners();
  }

  void setRecMaxKcal(int v) {
    recMaxKcal = v;
    notifyListeners();
  }

  void setRecSort(String s) {
    recSort = s;
    notifyListeners();
  }
}
