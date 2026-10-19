import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/home/viewmodel/recommendation_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_project/data/services/meal_recommendation_service.dart';

AiMealSuggestion _ai(
  String name, {
  int kcal = 400,
  int score = 80,
  List<String> meals = const ['저녁'],
}) => AiMealSuggestion(
  name: name,
  emoji: '🍚',
  kcal: kcal,
  meta: '',
  covers: const ['식이섬유'],
  prefs: const [],
  meals: meals,
  tag: '집밥',
  why: '',
  score: score,
);

/// 부른 횟수와 받은 조건을 기록하고, 결과 · 실패를 정할 수 있는 가짜 서비스.
class _FakeService implements MealRecommendationService {
  _FakeService();

  List<AiMealSuggestion> result = [];
  bool fail = false;
  int calls = 0;
  Map<String, Object?>? lastRequest;

  @override
  Future<List<AiMealSuggestion>> recommend({
    required List<String> needs,
    required String meal,
    required List<String> prefs,
    required int maxKcal,
  }) async {
    calls++;
    lastRequest = {
      'needs': [...needs],
      'meal': meal,
      'prefs': [...prefs],
      'maxKcal': maxKcal,
    };
    if (fail) throw Exception('network down');
    return result;
  }
}

void main() {
  late _FakeService service;
  late RecommendationViewModel vm;

  setUp(() {
    service = _FakeService();
    vm = RecommendationViewModel(service: service);
  });

  group('RecommendationViewModel · 조건', () {
    test('부족한 영양소와 선호는 누를 때마다 켜지고 꺼진다', () {
      var notified = 0;
      vm.addListener(() => notified++);

      vm.toggleNeed('철분');
      expect(vm.needs, contains('철분'));
      vm.toggleNeed('철분');
      expect(vm.needs, isNot(contains('철분')));

      vm.togglePref('고단백');
      expect(vm.recPrefs, contains('고단백'));
      vm.togglePref('고단백');
      expect(vm.recPrefs, isNot(contains('고단백')));

      expect(notified, 4);
    });

    test('끼니 · 최대 칼로리 · 정렬을 바꾸면 알린다', () {
      var notified = 0;
      vm.addListener(() => notified++);

      vm
        ..setRecMeal('아침')
        ..setRecMaxKcal(350)
        ..setRecSort('칼로리 낮은 순');

      expect(vm.recMeal, '아침');
      expect(vm.recMaxKcal, 350);
      expect(vm.recSort, '칼로리 낮은 순');
      expect(notified, 3);
    });
  });

  group('RecommendationViewModel · 규칙 기반 추천 (AI 결과가 없을 때)', () {
    test('칼로리 한도 안의 메뉴만, 점수 높은 순으로 보여 준다', () {
      final recs = vm.recommendations;

      expect(recs, isNotEmpty);
      expect(recs.every((r) => r.meal.kcal <= vm.recMaxKcal), isTrue);
      final scores = recs.map((r) => r.score).toList();
      expect([...scores]..sort((a, b) => b.compareTo(a)), scores);
      expect(scores.every((s) => s >= 52 && s <= 96), isTrue);
    });

    test('"칼로리 낮은 순"으로 바꾸면 칼로리 오름차순이다', () {
      vm.setRecSort('칼로리 낮은 순');

      final kcals = vm.recommendations.map((r) => r.meal.kcal).toList();
      expect([...kcals]..sort(), kcals);
    });

    test('한도가 너무 낮아 맞는 메뉴가 없으면 빈 목록이다', () {
      vm.setRecMaxKcal(100);

      expect(vm.recommendations, isEmpty);
    });

    test('고른 끼니에 맞는 메뉴가 3개보다 적으면 다른 끼니 메뉴도 섞고 표시한다', () {
      // 330kcal 이하 아침 메뉴는 2개뿐이라, 끼니와 상관없이 330kcal 이하 메뉴까지 넓힌다.
      vm.setRecMeal('아침');
      vm.setRecMaxKcal(330);

      final recs = vm.recommendations;
      expect(recs.where((r) => r.offMeal), isNotEmpty);
      expect(
        recs.where((r) => !r.offMeal).every((r) => r.meal.meals.contains('아침')),
        isTrue,
      );
    });

    test('고른 영양소를 더 많이 채우는 메뉴가 위에 온다', () {
      vm
        ..needs.clear()
        ..needs.addAll(['오메가3', '비타민D'])
        ..recPrefs.clear();
      vm.setRecMeal('저녁');

      expect(vm.recommendations.first.meal.name, contains('고등어'));
    });
  });

  group('RecommendationViewModel · AI 추천', () {
    test('현재 조건으로 요청하고, 받은 결과를 보여 준다', () async {
      service.result = [_ai('A', score: 70), _ai('B', score: 90)];
      vm
        ..setRecMeal('점심')
        ..setRecMaxKcal(500);

      await vm.fetchAiRecommendations();

      expect(service.lastRequest, {
        'needs': ['식이섬유', '칼슘'],
        'meal': '점심',
        'prefs': ['채식 위주'],
        'maxKcal': 500,
      });
      expect(vm.recommendations.map((r) => r.meal.name), ['B', 'A']);
      expect(vm.recommendationError, isNull);
    });

    test('불러오는 동안 loading이 켜졌다가 끝나면 꺼진다', () async {
      final states = <bool>[];
      vm.addListener(() => states.add(vm.loadingRecommendations));

      await vm.fetchAiRecommendations();

      expect(states, [true, false]);
    });

    test('칼로리 낮은 순 정렬은 AI 결과에도 적용된다', () async {
      service.result = [
        _ai('무거움', kcal: 600, score: 99),
        _ai('가벼움', kcal: 200, score: 60),
      ];
      vm.setRecSort('칼로리 낮은 순');

      await vm.fetchAiRecommendations();

      expect(vm.recommendations.map((r) => r.meal.name), ['가벼움', '무거움']);
    });

    test('고른 끼니가 아닌 메뉴는 offMeal로 표시한다', () async {
      service.result = [
        _ai('저녁용', meals: ['저녁']),
        _ai('아침용', meals: ['아침']),
      ];

      await vm.fetchAiRecommendations();

      final byName = {for (final r in vm.recommendations) r.meal.name: r};
      expect(byName['저녁용']!.offMeal, isFalse);
      expect(byName['아침용']!.offMeal, isTrue);
    });

    test('실패하면 오류 문구를 알리고, 규칙 기반 추천으로 대신한다', () async {
      service.fail = true;

      await vm.fetchAiRecommendations();

      expect(vm.recommendationError, '추천을 불러오지 못했어요. 다시 시도해주세요.');
      expect(vm.aiRecommendations, isNull);
      expect(vm.loadingRecommendations, isFalse);
      expect(vm.recommendations, isNotEmpty);
    });

    test('다시 시도해서 성공하면 오류 문구가 사라진다', () async {
      service.fail = true;
      await vm.fetchAiRecommendations();

      service
        ..fail = false
        ..result = [_ai('A')];
      await vm.fetchAiRecommendations();

      expect(vm.recommendationError, isNull);
      expect(vm.recommendations.single.meal.name, 'A');
    });
  });

  group('AppState 연결', () {
    test('동의한 상태로 추천 화면에 들어가면 AI 추천을 한 번 불러온다', () async {
      final s = AppState(mealRecommendationService: service);
      await s.setAiConsent(true);

      s.navigationViewModel.go('recommend');
      await Future<void>.delayed(Duration.zero);
      s.navigationViewModel.go('home');
      s.navigationViewModel.go('recommend'); // 이미 받아 둔 결과가 있으면 다시 부르지 않는다
      await Future<void>.delayed(Duration.zero);

      expect(service.calls, 1);
    });

    test('동의 전에는 추천 화면에 들어가도 AI에 요청하지 않는다', () async {
      final s = AppState(mealRecommendationService: service);

      s.navigationViewModel.go('recommend');
      await Future<void>.delayed(Duration.zero);

      expect(service.calls, 0);
      expect(s.recommendations, isNotEmpty); // 규칙 기반 추천은 보인다
    });

    test('추천 조건이 바뀌면 화면이 구독하는 ViewModel에 전달된다', () {
      final s = AppState(mealRecommendationService: service);
      var notified = 0;
      s.recommendationViewModel.addListener(() => notified++);

      s.setRecMeal('아침');

      expect(notified, 1);
      expect(s.recMeal, '아침');
    });
  });
}
