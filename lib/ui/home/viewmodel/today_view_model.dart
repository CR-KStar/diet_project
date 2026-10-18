import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/home/viewmodel/today_summary.dart';
import 'package:diet_project/ui/record/viewmodel/records_view_model.dart';
import 'package:flutter/foundation.dart';

/// 홈과 영양소 상세 화면이 보여주는 "오늘" 수치를 담당한다 — 먹은 칼로리 · 남은 칼로리 ·
/// 영양소 합계 · 오늘 운동 시간 · 가장 최근 체중 · 날짜 문구.
///
/// 기록은 직접 들고 있지 않고 [snapshot]으로 매번 받아서 계산만 한다
/// (영양소 합계 계산은 [TodaySummary]가 한다).
class TodayViewModel extends ChangeNotifier {
  TodayViewModel({required this.snapshot, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RecordsSnapshot Function() snapshot;
  final DateTime Function() _now;

  /// 계산에 쓰는 기록이 바뀌었을 때 화면이 다시 계산하도록 알린다 (AppState가 연결한다).
  void refresh() => notifyListeners();

  /// 오늘 (시간은 버리고 날짜만)
  DateTime get today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  String get todayKey => RecordsViewModel.dateKeyOf(today);

  static const _weekdayNames = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  /// 예: "9월 21일"
  String get todayDateLabel => '${today.month}월 ${today.day}일';

  /// 예: "9월 21일 월요일"
  String get todayLabel =>
      '$todayDateLabel ${_weekdayNames[today.weekday - 1]}';

  // ── 오늘의 기록 ─────────────────────────────────────────────────────

  /// 고정된 오늘 날짜의 식단 (기록 탭에서 넘겨보는 날짜와는 무관하다).
  List<MealLog> get todayMeals => snapshot().mealsOn(todayKey);

  /// 오늘 운동 시간 합계(분).
  int get todayExerciseMinutes =>
      snapshot().exercisesOn(todayKey).fold(0, (a, e) => a + e.minutes);

  TodaySummary get summary =>
      TodaySummary(meals: todayMeals, dailyTarget: snapshot().dailyTarget);

  int get intakeKcal => summary.intakeKcal;
  int get remainKcal => summary.remainKcal;
  double get intakeRatio => summary.intakeRatio;

  List<NutrientStat> get todayNutrientStats => summary.nutrientStats;
  double get todayProteinG => summary.proteinG;
  double get todayCarbG => summary.carbG;
  double get todayFatG => summary.fatG;
  ({int proteinPct, int carbPct, int fatPct}) get macroRatio =>
      summary.macroRatio;

  // ── 체중 ────────────────────────────────────────────────────────────

  /// 지금까지 저장한 체중 기록 횟수.
  int get weightRecordCount => snapshot().weights.length;

  /// 가장 최근에 저장한 체중 (기록이 없으면 프로필의 현재 체중).
  double get latestWeightKg {
    final data = snapshot();
    return data.latestLoggedWeightKg ?? data.profileWeightKg;
  }
}
