import 'dart:async';
import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/utils/date_format.dart';

class MealViewModel extends ChangeNotifier {
  MealViewModel({required this._mealRepo, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RecordRepository<MealLog> _mealRepo;
  final DateTime Function() _now;

  String get _todayKey => formatDateKey(_now());

  String _keyDaysAgo(int days) {
    final n = _now();
    return formatDateKey(DateTime(n.year, n.month, n.day - days));
  }

  String? uid;
  String get _uid => uid ?? User.meId;

  /// 서버 저장이 실패했을 때 불린다. AppState가 사용자에게 알림을 띄우는 데 쓴다.
  void Function()? onSaveFailed;

  /// 전체 식단 기록 저장소. bowlId로 Bowl을, dateKey로 날짜를 참조한다.
  late final List<MealLog> mealLogs = [
    MealLog(
      id: 'meal_seed_breakfast',
      userId: User.meId,
      mealType: MealType.breakfast,
      name: '오트밀 · 바나나',
      meta: '집 밥그릇 · 가득 · 집밥',
      kcal: 320,
      dateKey: _todayKey,
      bowlId: 'bowl_home',
      proteinG: 9,
      carbG: 55,
      fatG: 6,
      fiberG: 8,
      sodiumMg: 120,
      sugarG: 14,
      calciumMg: 90,
      ironMg: 2,
    ),
    MealLog(
      id: 'meal_seed_lunch',
      userId: User.meId,
      mealType: MealType.lunch,
      name: '현미밥 · 닭가슴살 도시락',
      meta: '회사 도시락 · 가득 · 도시락',
      kcal: 450,
      dateKey: _todayKey,
      bowlId: 'bowl_lunchbox',
      proteinG: 28,
      carbG: 62,
      fatG: 12,
      fiberG: 5,
      sodiumMg: 800,
      sugarG: 6,
      calciumMg: 60,
      ironMg: 3,
    ),
    MealLog(
      id: 'meal_seed_dinner',
      userId: User.meId,
      mealType: MealType.dinner,
      name: '닭가슴살 샐러드',
      meta: '샐러드 볼 · 반 · 집밥',
      kcal: 480,
      dateKey: _todayKey,
      bowlId: 'bowl_salad',
      proteinG: 38,
      carbG: 20,
      fatG: 22,
      fiberG: 7,
      sodiumMg: 640,
      sugarG: 5,
      calciumMg: 110,
      ironMg: 4,
    ),
    MealLog(
      id: 'meal_seed_snack',
      userId: User.meId,
      mealType: MealType.snack,
      name: '그릭요거트',
      meta: '컵 · 가득 · 외식',
      kcal: 200,
      dateKey: _todayKey,
      proteinG: 17,
      carbG: 14,
      fatG: 6,
      sodiumMg: 70,
      sugarG: 9,
      calciumMg: 180,
    ),
    ..._demoPastMeals(),
  ];

  List<MealLog> mealsOn(String dateKey) =>
      mealLogs.where((m) => m.userId == _uid && m.dateKey == dateKey).toList();

  /// 오늘의 식단
  List<MealLog> get todayMeals => mealsOn(_todayKey);

  void addMeal(MealLog log) {
    mealLogs.add(log);
    notifyListeners();
    _saveMeal(log);
  }

  /// 예시 모드에서 달력 · 리포트가 비어 보이지 않도록 지난 6일치 식단을 채운다.
  /// (실제 계정은 로그인 시 예시 기록이 비워진다.)
  List<MealLog> _demoPastMeals() {
    const kcals = [
      (320, 520, 560),
      (350, 480, 610),
      (300, 560, 520),
      (340, 450, 640),
      (330, 600, 580),
      (360, 500, 540),
    ];
    const names = [
      ('그릭요거트 · 베리', '현미 비빔밥', '연어 포케 볼'),
      ('통밀 토스트 · 달걀', '닭가슴살 샐러드', '두부 스테이크'),
      ('오트밀 · 바나나', '샌드위치', '야채 볶음밥'),
      ('고구마 · 우유', '잡곡밥 · 제육볶음', '닭가슴살 샐러드'),
      ('바나나 스무디', '곤약 쫄면', '연어 구이 · 채소'),
      ('오트밀 · 블루베리', '월남쌈', '두부 샐러드'),
    ];
    const types = [MealType.breakfast, MealType.lunch, MealType.dinner];
    final out = <MealLog>[];
    for (var i = 0; i < kcals.length; i++) {
      final key = _keyDaysAgo(i + 1);
      final k = [kcals[i].$1, kcals[i].$2, kcals[i].$3];
      final n = [names[i].$1, names[i].$2, names[i].$3];
      for (var m = 0; m < 3; m++) {
        out.add(
          MealLog(
            id: 'meal_seed_${i}_$m',
            userId: User.meId,
            mealType: types[m],
            name: n[m],
            meta: '집밥',
            kcal: k[m],
            dateKey: key,
            proteinG: k[m] * 0.06,
            carbG: k[m] * 0.11,
            fatG: k[m] * 0.03,
            fiberG: k[m] * 0.012,
            sodiumMg: k[m] * 1.3,
            sugarG: k[m] * 0.02,
            calciumMg: k[m] * 0.2,
            ironMg: k[m] * 0.006,
          ),
        );
      }
    }
    return out;
  }

  void _saveMeal(MealLog log) {
    if (uid == null) return;
    unawaited(
      _mealRepo.save(uid!, log).catchError((Object e, StackTrace stack) {
        debugPrint('식단 기록 저장 실패: $e\n$stack');
        onSaveFailed?.call();
      }),
    );
  }

  void clear() {
    mealLogs.clear();
    notifyListeners();
  }

  void mergeLoaded(List<MealLog> loaded) {
    final have = {for (final m in mealLogs) m.id};
    mealLogs.addAll(loaded.where((m) => !have.contains(m.id)));
    notifyListeners();
  }

  /// id로 식단 한 건을 찾고 없으면 null
  MealLog? mealById(String? id) {
    for (final m in mealLogs) {
      if (m.id == id) return m;
    }
    return null;
  }
}
