import 'dart:math';

import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';

/// 미션 진행도를 계산하는 데 쓰는 오늘의 기록 요약 — AppState가 그때그때 최신 값으로 만들어 준다.
class MissionInputs {
  const MissionInputs({
    required this.uid,
    required this.todayKey,
    required this.mealsToday,
    required this.exerciseMinutesToday,
    required this.waterMl,
    required this.streakDays,
  });

  /// 미션을 뽑는 난수의 시드 — 같은 사용자 · 같은 날이면 늘 같은 미션이 나온다.
  final String uid;
  final String todayKey;
  final int mealsToday;
  final int exerciseMinutesToday;
  final int waterMl;
  final int streakDays;
}

/// 오늘의 미션 풀 하나의 정의. `current`는 오늘의 실시간 기록(MissionInputs)에서 값을 읽어오는
/// 함수라서, 미션이 뽑힌 뒤에도 항상 최신 진행도를 보여준다.
class _MissionTemplate {
  const _MissionTemplate({
    required this.id,
    required this.title,
    required this.target,
    required this.unit,
    required this.exp,
    required this.axis,
    required this.route,
    required this.current,
    this.special,
  });

  final String id;
  final String title;
  final double target;
  final String unit;
  final int exp;
  final PlantAxis axis;
  final String route;
  final String? special;
  final double Function(MissionInputs) current;
}

/// 같은 글자면 앱을 다시 켜도, 어느 기기에서도 같은 숫자가 나오는 시드.
///
/// Object.hash는 실행할 때마다 값이 달라져서, 이걸로 난수를 고정하면 앱을 다시 켤
/// 때마다 오늘의 미션이 새로 뽑힌다. 값이 32비트 안에서만 움직이게 해서 웹에서도 같다.
int _stableSeed(String text) {
  var h = 7;
  for (final unit in text.codeUnits) {
    h = (h * 31 + unit) & 0x7fffffff;
  }
  return h;
}

/// 오늘의 미션을 뽑고 진행도를 계산하며, 수동 완료를 기억한다.
///
/// 기록은 직접 들고 있지 않고 [inputs]로 매번 받아서 계산만 한다. 여기서 들고 있는
/// 상태는 카테고리 필터와 "달성 처리"로 수동 완료한 미션뿐이다. 수동 완료하면 식물
/// 경험치를 주려고 [gainExp]를 부른다.
class MissionViewModel extends ChangeNotifier {
  MissionViewModel({required this.inputs, required this.gainExp});

  /// 계산에 쓰는 기록이 바뀌었을 때 화면이 다시 계산하도록 알린다 (AppState가 연결한다).
  void refresh() => notifyListeners();

  final MissionInputs Function() inputs;
  final void Function(int exp) gainExp;

  // 미션 뽑기
  //
  // 카테고리별 미션 풀에서 오늘 날짜 + 내 uid로 시드를 고정한 난수로
  // 3~5개를 뽑는다. 같은 uid·같은 날이면 항상 같은 조합이 나오고(새로고침
  // 해도 안 바뀜), 날짜가 바뀌면 다른 조합이 나온다. 한 카테고리에서는
  // 최대 2개까지만 뽑는다.
  //
  // "전날 실패 카테고리 우선"이나 "난이도는 최근 7일 평균의 90~110%" 같은
  // 더 정교한 규칙은 과거 날짜별 카테고리 성공/실패 기록이 따로 쌓여야
  // 가능한데, 지금은 그 데이터가 없어서 구현하지 않았다 — 목표치가 다른
  // 여러 난이도의 미션을 같은 카테고리 풀에 넣어 두는 정도로 대신한다.
  static final Map<String, List<_MissionTemplate>> _missionPool = {
    '식단': [
      _MissionTemplate(
        id: 'm_meal1',
        title: '한 끼 기록하기',
        target: 1,
        unit: '끼',
        exp: 10,
        axis: PlantAxis.nutri,
        route: 'capture',
        current: (i) => i.mealsToday.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_meal2',
        title: '두 끼 기록하기',
        target: 2,
        unit: '끼',
        exp: 15,
        axis: PlantAxis.nutri,
        route: 'capture',
        current: (i) => i.mealsToday.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_meal3',
        title: '세 끼 모두 기록하기',
        target: 3,
        unit: '끼',
        exp: 20,
        axis: PlantAxis.nutri,
        route: 'capture',
        current: (i) => i.mealsToday.toDouble(),
      ),
    ],
    '운동': [
      _MissionTemplate(
        id: 'm_exercise20',
        title: '20분 운동하기',
        target: 20,
        unit: '분',
        exp: 10,
        axis: PlantAxis.sun,
        route: 'exercise',
        current: (i) => i.exerciseMinutesToday.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_exercise30',
        title: '30분 운동하기',
        target: 30,
        unit: '분',
        exp: 15,
        axis: PlantAxis.sun,
        route: 'exercise',
        special: '변이 기회',
        current: (i) => i.exerciseMinutesToday.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_exercise45',
        title: '45분 운동하기',
        target: 45,
        unit: '분',
        exp: 20,
        axis: PlantAxis.sun,
        route: 'exercise',
        special: '변이 기회',
        current: (i) => i.exerciseMinutesToday.toDouble(),
      ),
    ],
    '생활': [
      _MissionTemplate(
        id: 'm_water1000',
        title: '물 1L 마시기',
        target: 1000,
        unit: 'ml',
        exp: 10,
        axis: PlantAxis.water,
        route: 'water',
        current: (i) => i.waterMl.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_water1500',
        title: '물 1.5L 마시기',
        target: 1500,
        unit: 'ml',
        exp: 10,
        axis: PlantAxis.water,
        route: 'water',
        current: (i) => i.waterMl.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_water2000',
        title: '물 2L 마시기',
        target: 2000,
        unit: 'ml',
        exp: 15,
        axis: PlantAxis.water,
        route: 'water',
        current: (i) => i.waterMl.toDouble(),
      ),
    ],
    '꾸준함': [
      _MissionTemplate(
        id: 'm_streak3',
        title: '3일 연속 기록하기',
        target: 3,
        unit: '일',
        exp: 15,
        axis: PlantAxis.nutri,
        route: 'records',
        current: (i) => i.streakDays.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_streak7',
        title: '7일 연속 기록하기',
        target: 7,
        unit: '일',
        exp: 25,
        axis: PlantAxis.nutri,
        route: 'records',
        current: (i) => i.streakDays.toDouble(),
      ),
    ],
  };

  List<Mission> get missions {
    final input = inputs();
    final rng = Random(_stableSeed('${input.uid}|${input.todayKey}'));
    final categories = _missionPool.keys.toList()..shuffle(rng);
    final missionCount = 3 + rng.nextInt(3); // 3~5개

    final picked = <(String category, _MissionTemplate template)>[];
    for (final category in categories) {
      if (picked.length >= missionCount) break;
      final pool = List.of(_missionPool[category]!)..shuffle(rng);
      picked.add((category, pool.first));
    }
    // 미션이 5개면 카테고리(4개)를 다 쓰고도 하나가 남는다 — 그 하나는
    // 무작위 카테고리에서 이미 뽑은 것과 다른 난이도로 하나 더 뽑는다.
    while (picked.length < missionCount) {
      final category = categories[rng.nextInt(categories.length)];
      final usedIds = picked
          .where((p) => p.$1 == category)
          .map((p) => p.$2.id)
          .toSet();
      final remaining = _missionPool[category]!
          .where((t) => !usedIds.contains(t.id))
          .toList();
      if (remaining.isEmpty) break;
      picked.add((category, remaining[rng.nextInt(remaining.length)]));
    }

    return [
      for (final (category, template) in picked)
        Mission(
          id: template.id,
          category: category,
          title: template.title,
          current: template.current(input),
          target: template.target,
          unit: template.unit,
          exp: template.exp,
          axis: template.axis,
          route: template.route,
          special: template.special,
        ),
    ];
  }

  /// 미션 카테고리 필터 — 전체/식단/운동/생활/꾸준함
  String missionFilterTab = '전체';
  void setMissionFilterTab(String t) {
    missionFilterTab = t;
    notifyListeners();
  }

  /// "달성 처리" 버튼으로 수동 완료한 미션 — 날짜까지 함께 기억한다. 미션 id만 기억하면
  /// 어제 달성 처리한 미션이 오늘 같은 미션으로 다시 나왔을 때도 완료로 보인다.
  final Set<String> _manualMissionDone = {};

  String _manualKey(Mission m) => '${inputs().todayKey}:${m.id}';

  bool missionEffectivelyDone(Mission m) =>
      m.done || _manualMissionDone.contains(_manualKey(m));

  void completeMissionManually(Mission m) {
    if (missionEffectivelyDone(m)) return;
    _manualMissionDone.add(_manualKey(m));
    gainExp(m.exp);
    notifyListeners();
  }

  int get missionDone => missions.where(missionEffectivelyDone).length;
  int get missionExp =>
      missions.where(missionEffectivelyDone).fold(0, (a, m) => a + m.exp);
}
