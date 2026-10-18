import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';

/// 기록 탭과 홈이 오늘/선택한 날의 값을 계산하는 데 쓰는 기록 모음 —
/// AppState가 그때그때 최신 값으로 만들어 준다.
class RecordsSnapshot {
  const RecordsSnapshot({
    required this.meals,
    required this.exercises,
    required this.weights,
    required this.waterEntries,
    required this.mealsOn,
    required this.exercisesOn,
    required this.dailyTarget,
    required this.profileWeightKg,
    required this.latestLoggedWeightKg,
    required this.mealById,
  });

  /// 날짜 구분 없이 저장된 기록 전체 (기록한 날이 있는지 볼 때 쓴다).
  final List<MealLog> meals;
  final List<ExerciseLog> exercises;
  final List<WeightEntry> weights;
  final List<WaterEntry> waterEntries;

  /// 특정 날짜([dateKey])의 내 기록.
  final List<MealLog> Function(String dateKey) mealsOn;
  final List<ExerciseLog> Function(String dateKey) exercisesOn;

  final int dailyTarget;

  /// 체중 기록이 하나도 없을 때 보여주는 프로필의 현재 체중.
  final double profileWeightKg;

  /// 가장 최근에 저장한 체중 (기록이 없으면 null).
  final double? latestLoggedWeightKg;

  /// id로 식단 한 건을 찾고 없으면 null.
  final MealLog? Function(String? id) mealById;
}

/// 기록 탭의 달력(보고 있는 달 · 날짜)과, "그날 기록이 있는가 · 며칠 연속인가" 같은
/// 기록 여부 계산을 담당한다.
///
/// 기록은 직접 들고 있지 않고 [snapshot]으로 매번 받아서 계산만 한다. 다른 달로 넘어가면
/// 그 달 기록을 불러오도록 [onViewedMonthChanged]로 알린다.
class RecordsViewModel extends ChangeNotifier {
  RecordsViewModel({
    required this.snapshot,
    DateTime Function()? now,
    this.onViewedMonthChanged,
  }) : _now = now ?? DateTime.now;

  final RecordsSnapshot Function() snapshot;
  final DateTime Function() _now;

  /// 보고 있는 달이 바뀌었을 때 (그 달 기록을 불러오는 데 쓴다).
  void Function(int year, int month)? onViewedMonthChanged;

  /// 계산에 쓰는 기록이 바뀌었을 때 화면이 다시 계산하도록 알린다 (AppState가 연결한다).
  void refresh() => notifyListeners();

  static String dateKeyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 오늘 (시간은 버리고 날짜만)
  DateTime get today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  late int year = today.year;
  late int month = today.month;
  late int day = today.day;

  String get todayKey => dateKeyOf(today);
  String get selectedKey => dateKeyOf(DateTime(year, month, day));
  bool get viewingToday => selectedKey == todayKey;

  /// 이전 달로 — 과거는 제한 없이 넘겨볼 수 있다.
  void prevMonth() {
    final first = DateTime(year, month - 1, 1);
    year = first.year;
    month = first.month;
    day = day.clamp(1, DateTime(year, month + 1, 0).day);
    notifyListeners();
    onViewedMonthChanged?.call(year, month);
  }

  /// 오늘이 속한 달보다 뒤로는 갈 수 없다 (미래의 기록은 만들 수 없다).
  bool get canGoNextMonth => year * 12 + month < today.year * 12 + today.month;

  bool nextMonth() {
    if (!canGoNextMonth) return false;
    final first = DateTime(year, month + 1, 1);
    year = first.year;
    month = first.month;
    day = day.clamp(1, DateTime(year, month + 1, 0).day);
    if (DateTime(year, month, day).isAfter(today)) day = today.day;
    notifyListeners();
    onViewedMonthChanged?.call(year, month);
    return true;
  }

  /// 보고 있는 달의 [d]일이 오늘보다 뒤인가
  bool isFutureDay(int d) => DateTime(year, month, d).isAfter(today);

  void selectDay(int d) {
    if (isFutureDay(d)) return;
    day = d;
    notifyListeners();
  }

  /// 상세 화면에서 보여줄 식단 — id로 참조한다.
  String? detailMealId;

  MealLog? get detailMeal => snapshot().mealById(detailMealId);

  /// 식단 하나를 상세 화면에서 볼 수 있게 골라 둔다 (화면 이동은 AppState가 한다).
  void selectDetailMeal(MealLog m) {
    detailMealId = m.id;
    notifyListeners();
  }

  /// 기록 탭에서 지금 보고 있는 날짜(month/day)의 식단.
  List<MealLog> get meals => snapshot().mealsOn(selectedKey);

  /// 지금 보고 있는 날짜의 총 섭취 칼로리.
  int get selectedDayKcal => meals.fold(0, (a, m) => a + m.kcal);

  /// 보고 있는 날짜에 식단 · 운동 · 체중 · 물을 기록했는지.
  /// 체중과 물은 날짜별 기록이 아니라 오늘 것만 있어서 오늘을 보고 있을 때만 켜진다.
  Map<String, bool> get logged {
    final data = snapshot();
    return {
      '식단': meals.isNotEmpty,
      '운동': data.exercisesOn(selectedKey).isNotEmpty,
      '체중': viewingToday && data.weights.isNotEmpty,
      '물': viewingToday && data.waterEntries.isNotEmpty,
    };
  }

  /// [date]에 남긴 기록(식단 · 운동 · 체중, 그리고 오늘의 물)이 하나라도 있는가.
  bool hasRecordOn(DateTime date) {
    final key = dateKeyOf(date);
    final data = snapshot();
    return data.meals.any((m) => m.dateKey == key) ||
        data.exercises.any((e) => e.dateKey == key) ||
        data.weights.any((w) => w.dateKey == key) ||
        data.waterEntries.any((w) => w.dateKey == key);
  }

  /// 연속 기록 일수 — 오늘부터 거꾸로 기록이 이어진 날 수.
  /// 오늘 아직 기록하지 않았어도 어제까지 이어진 연속은 끊기지 않은 것으로 센다.
  int get streakDays {
    final t = today;
    var d = hasRecordOn(t) ? t : DateTime(t.year, t.month, t.day - 1);
    var n = 0;
    while (n < 3650 && hasRecordOn(d)) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  /// 체중 화면 "최근 7일" — 오래된 날부터 오늘까지, 그날 마지막으로 기록한
  /// 체중(기록이 없는 날은 kg가 null).
  List<({int day, double? kg, bool isToday})> get recentWeightDays {
    final entries = snapshot().weights;
    final t = today;
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final d = DateTime(t.year, t.month, t.day - i);
          final key = dateKeyOf(d);
          double? kg;
          for (final w in entries) {
            if (w.dateKey == key) kg = w.kg;
          }
          return (day: d.day, kg: kg, isToday: i == 0);
        }(),
    ];
  }
}
