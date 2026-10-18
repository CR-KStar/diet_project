import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_project/utils/date_format.dart';
import 'package:diet_project/utils/app_state_format.dart';

/// 리포트가 집계에 쓰는 기록 모음 — AppState가 그때그때 최신 값으로 만들어 준다.
class ReportInputs {
  const ReportInputs({
    required this.today,
    required this.meals,
    required this.exercises,
    required this.weights,
    required this.fallbackWeightKg,
    required this.dailyTarget,
    required this.bowls,
    required this.hasRecordOn,
  });

  /// 오늘 (시간은 버리고 날짜만)
  final DateTime today;
  final List<MealLog> meals;
  final List<ExerciseLog> exercises;
  final List<WeightEntry> weights;

  /// 체중 기록이 하나도 없을 때 그래프에 쓰는 프로필의 현재 체중.
  final double fallbackWeightKg;
  final int dailyTarget;
  final List<Bowl> bowls;

  /// 그 날짜에 식단 · 운동 · 체중 · 물 중 하나라도 기록했는지.
  final bool Function(DateTime date) hasRecordOn;
}

/// 리포트 탭(주간 · 월간)에서 보여줄 값을 실제 기록으로 집계한다.
///
/// 기록은 직접 들고 있지 않고 [inputs]로 매번 받아서 계산만 한다. 여기서 들고 있는
/// 상태는 어떤 기간을 보고 있는지([period])뿐이다.
class ReportViewModel extends ChangeNotifier {
  ReportViewModel({required this.inputs});

  /// 계산에 쓰는 기록이 바뀌었을 때 화면이 다시 계산하도록 알린다 (AppState가 연결한다).
  void refresh() => notifyListeners();

  /// 집계에 쓸 최신 기록을 돌려주는 함수.
  final ReportInputs Function() inputs;

  ReportInputs get _in => inputs();
  DateTime get today => _in.today;

  String period = '주간';

  void setPeriod(String p) {
    period = p;
    notifyListeners();
  }

  // 리포트 탭(주간 · 월간) — 실제 기록을 집계한다.
  //
  // "주간"은 오늘을 포함한 최근 7일, "월간"은 이번 달 1일부터 오늘까지다.
  // _loadAccountData가 이번 달 + 지난달 기록만 불러오므로, 그 범위를 벗어난
  // 조회는 하지 않는다(지지난달과 비교하는 식의 통계는 만들지 않았다).
  static const _weekdayShort = ['월', '화', '수', '목', '금', '토', '일'];

  List<DateTime> get _periodDays => period == '주간'
      ? [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))]
      : [
          for (var d = 1; d <= today.day; d++)
            DateTime(today.year, today.month, d),
        ];

  /// 이전 동일 기간(지난주 · 지난달) — 증감 비교에만 쓴다.
  List<DateTime> get _prevPeriodDays => period == '주간'
      ? [for (var i = 13; i >= 7; i--) today.subtract(Duration(days: i))]
      : [
          for (var d = 1; d <= DateTime(today.year, today.month, 0).day; d++)
            DateTime(today.year, today.month - 1, d),
        ];

  /// 월간일 때 달력 주 단위(최대 7일)로 묶는다. 주간은 하루씩 그대로 묶는다.
  List<List<DateTime>> get _periodBuckets {
    final days = _periodDays;
    if (period == '주간') {
      return [
        for (final d in days) [d],
      ];
    }
    return [
      for (var i = 0; i < days.length; i += 7)
        days.sublist(i, i + 7 > days.length ? days.length : i + 7),
    ];
  }

  int _kcalOn(DateTime d) {
    final key = formatDateKey(d);
    return _in.meals
        .where((m) => m.dateKey == key)
        .fold(0, (a, m) => a + m.kcal);
  }

  int _exerciseMinOn(DateTime d) {
    final key = formatDateKey(d);
    return _in.exercises
        .where((e) => e.dateKey == key)
        .fold(0, (a, e) => a + e.minutes);
  }

  /// [key] 날짜까지 기록된 것 중 가장 최근 체중(없으면 그 이후 가장 이른
  /// 기록, 그마저 없으면 프로필의 현재 체중) — 매일 재지 않아도 그래프가
  /// 끊기지 않게 이전 값을 이어서 보여준다.
  double _weightAsOf(String key) {
    WeightEntry? best;
    for (final w in _in.weights) {
      if (w.dateKey.compareTo(key) > 0) continue;
      if (best == null || w.dateKey.compareTo(best.dateKey) > 0) best = w;
    }
    if (best != null) return best.kg;
    WeightEntry? earliest;
    for (final w in _in.weights) {
      if (earliest == null || w.dateKey.compareTo(earliest.dateKey) < 0) {
        earliest = w;
      }
    }
    return earliest?.kg ?? _in.fallbackWeightKg;
  }

  List<({String label, int value, int pct})> get kcalBars {
    final buckets = _periodBuckets;
    return [
      for (var i = 0; i < buckets.length; i++) _kcalBarFor(buckets[i], i),
    ];
  }

  ({String label, int value, int pct}) _kcalBarFor(
    List<DateTime> days,
    int weekIndex,
  ) {
    final avg = days.isEmpty
        ? 0
        : (days.fold(0, (a, d) => a + _kcalOn(d)) / days.length).round();
    final label = period == '주간'
        ? _weekdayShort[days.first.weekday - 1]
        : '${weekIndex + 1}주';
    final pct = _in.dailyTarget > 0
        ? (avg / _in.dailyTarget * 100).round().clamp(0, 100)
        : 0;
    return (label: label, value: avg, pct: pct);
  }

  List<({String label, double kg})> get weightSeries {
    final buckets = _periodBuckets;
    return [
      for (var i = 0; i < buckets.length; i++)
        (
          label: period == '주간'
              ? '${buckets[i].first.month}/${buckets[i].first.day}'
              : '${i + 1}주',
          kg: _weightAsOf(formatDateKey(buckets[i].last)),
        ),
    ];
  }

  int get _avgKcalThisPeriod {
    final days = _periodDays;
    if (days.isEmpty) return 0;
    return (days.fold(0, (a, d) => a + _kcalOn(d)) / days.length).round();
  }

  int get _avgKcalPrevPeriod {
    final days = _prevPeriodDays;
    if (days.isEmpty) return 0;
    return (days.fold(0, (a, d) => a + _kcalOn(d)) / days.length).round();
  }

  String get avgKcal => AppStateFormat.comma(_avgKcalThisPeriod);

  String get periodDelta {
    final label = period == '주간' ? '지난주' : '지난달';
    // 비교할 이전 기록이 없으면 이번 평균 전체가 "증가분"으로 보이므로 비교하지 않는다.
    if (_avgKcalPrevPeriod == 0) return '$label 기록이 없어요';
    final delta = _avgKcalThisPeriod - _avgKcalPrevPeriod;
    if (delta == 0) return '$label과 비슷해요';
    final sign = delta > 0 ? '+' : '-';
    return '$label 대비 $sign${AppStateFormat.comma(delta.abs())}kcal';
  }

  int get avgExerciseMin {
    final days = _periodDays;
    if (days.isEmpty) return 0;
    return (days.fold(0, (a, d) => a + _exerciseMinOn(d)) / days.length)
        .round();
  }

  int get exerciseMinDelta {
    final days = _periodDays;
    final prevDays = _prevPeriodDays;
    if (days.isEmpty || prevDays.isEmpty) return 0;
    final now = days.fold(0, (a, d) => a + _exerciseMinOn(d)) / days.length;
    final prev =
        prevDays.fold(0, (a, d) => a + _exerciseMinOn(d)) / prevDays.length;
    return (now - prev).round();
  }

  /// 이 기간의 날짜 중, 하루 권장 칼로리 안으로 먹은(0kcal 초과 ~ 목표 이하)
  /// 날의 비율. 아예 기록하지 않은 날은 "달성"으로 치지 않는다.
  int get achieveRate {
    final days = _periodDays;
    if (days.isEmpty || _in.dailyTarget <= 0) return 0;
    final achieved = days.where((d) {
      final kcal = _kcalOn(d);
      return kcal > 0 && kcal <= _in.dailyTarget;
    }).length;
    return (achieved / days.length * 100).round();
  }

  int get recordDays => _periodDays.where(_in.hasRecordOn).length;
  int get recordGoalDays => period == '주간' ? 5 : 20;

  List<MealLog> get _periodMeals {
    final keys = _periodDays.map(formatDateKey).toSet();
    return _in.meals.where((m) => keys.contains(m.dateKey)).toList();
  }

  String get mostEatenFood {
    final meals = _periodMeals;
    if (meals.isEmpty) return '기록된 식단이 없어요';
    final counts = <String, int>{};
    for (final m in meals) {
      counts[m.name] = (counts[m.name] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return '${top.key} · ${top.value}회';
  }

  String get mostUsedBowl {
    final withBowl = _periodMeals.where((m) => m.bowlId != null);
    if (withBowl.isEmpty) return '사용한 그릇이 없어요';
    final counts = <String, int>{};
    for (final m in withBowl) {
      counts[m.bowlId!] = (counts[m.bowlId!] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    Bowl? matched;
    for (final b in _in.bowls) {
      if (b.id == top.key) {
        matched = b;
        break;
      }
    }
    return '${matched?.name ?? '삭제된 그릇'} · ${top.value}회';
  }

  String get mostUsedSauce {
    final withSauce = _periodMeals.where((m) => m.sauce.isNotEmpty);
    if (withSauce.isEmpty) return '기록된 소스가 없어요';
    final counts = <String, int>{};
    for (final m in withSauce) {
      counts[m.sauce] = (counts[m.sauce] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return '${top.key} · ${top.value}회';
  }

  /// 이 기간 동안 가장 부족했던(목표 대비 %가 가장 낮은) 영양소.
  String get lackingNutrient {
    final meals = _periodMeals;
    if (meals.isEmpty) return '기록된 식단이 없어요';
    final days = _periodDays.length;
    ({String name, int pct})? worst;
    for (final (:name, unit: _, :target) in Nutrients.all) {
      final pick = Nutrients.pick(name);
      final total = meals.fold(0.0, (a, m) => a + pick(m));
      final periodTarget = target * days;
      final pct = periodTarget <= 0 ? 0 : (total / periodTarget * 100).round();
      if (worst == null || pct < worst.pct) worst = (name: name, pct: pct);
    }
    if (worst == null || worst.pct >= 100) return '부족한 영양소가 없어요';
    return '${worst.name} ${worst.pct - 100}%';
  }

  static const _nutrientTip = {
    '단백질': '단백질이 부족해요. 닭가슴살이나 두부, 계란 위주 식사를 추천해요.',
    '탄수화물': '탄수화물이 부족해요. 현미밥이나 고구마를 곁들여보세요.',
    '지방': '지방이 부족해요. 견과류나 아보카도, 올리브오일을 더해보세요.',
    '식이섬유': '식이섬유가 부족해요. 채소나 통곡물 위주 식사를 추천해요.',
    '나트륨': '나트륨 섭취가 부족해요. 국물 요리를 곁들여도 좋아요.',
    '당류': '당류 섭취가 부족해요. 제철 과일을 간식으로 더해보세요.',
    '칼슘': '칼슘이 부족해요. 유제품이나 멸치, 두부를 추천해요.',
    '철분': '철분이 부족해요. 붉은 고기나 시금치를 추천해요.',
  };

  String get recommendedMeal {
    if (_periodMeals.isEmpty) {
      return '아직 기록된 식단이 없어요. 식사를 기록하면 맞춤 추천을 보여드려요.';
    }
    final lacking = lackingNutrient;
    for (final entry in _nutrientTip.entries) {
      if (lacking.startsWith(entry.key)) return entry.value;
    }
    return '이번 기간 영양소를 골고루 채웠어요. 지금처럼 유지해보세요!';
  }
}
