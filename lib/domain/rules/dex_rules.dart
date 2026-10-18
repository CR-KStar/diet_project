import 'package:diet_project/domain/models/plant_axis.dart';
import 'package:diet_project/domain/models/record_tally.dart';

/// 도감 조건을 판단하는 데 쓰는 지금 상태.
class DexContext {
  const DexContext({
    required this.tally,
    required this.axisScore,
    required this.onboardingDone,
    required this.ownedCount,
    required this.totalCount,
  });

  final RecordTally tally;
  final Map<PlantAxis, int> axisScore;

  /// 시작 안내(온보딩)를 마쳤는지 — "튜토리얼 완료 시 획득" 조건.
  final bool onboardingDone;

  /// 지금까지 모은 식물 수 / 전체 식물 수 — "도감 80% 달성" 조건.
  final int ownedCount;
  final int totalCount;
}

/// 한 식물의 수집 진행 상태.
typedef DexProgress = ({int progress, bool done, bool comingSoon});

/// 식물 도감을 여는 조건 — 식물마다 PlantSpecies.condition에 적힌 문장을 그대로 계산으로 옮긴 것이다.
///
/// 기록 횟수 · 누적량 · 연속 일수로 정해진 조건은 계산하고, 아직 필요한 기록(챌린지 순위 · 미션
/// 달성 횟수 · 시간대별 기록 · 균형 유지 일수 · 씨앗 부화)이 없는 조건은 "준비 중"으로 둔다.
abstract final class DexRules {
  /// 아직 계산할 수 없는 조건의 식물.
  static const comingSoonIds = {
    'sp_sunflower', // 균형 7일 유지
    'sp_clover', // 미션 50회 달성
    'sp_moss_fern', // 밤 기록 10회
    'sp_mutant_tulip', // 전설 씨앗 부화
    'sp_golden_rose', // 챌린지 1위 3회
  };

  static bool isComingSoon(String speciesId) =>
      comingSoonIds.contains(speciesId);

  static DexProgress evaluate(String speciesId, DexContext c) {
    final t = c.tally;
    return switch (speciesId) {
      'sp_tulip' => _flag(c.onboardingDone),
      'sp_sprout' => _count(t.totalRecords, 1),
      'sp_rose' => _count(t.meals, 30),
      'sp_daisy' => _count(t.waterMl, 10000),
      'sp_monstera' => _count(t.bestStreakDays, 14),
      'sp_cactus' => _count(t.exercises, 10),
      'sp_cherry_blossom' => _count(
        c.axisScore.values.fold(0, (a, b) => a > b ? a : b),
        100,
      ),
      'sp_rubber_tree' => _count(t.totalRecords, 20),
      'sp_rice' => _count(t.breakfasts, 10),
      'sp_lotus' => _count(t.waterEntries, 50),
      'sp_conifer' => _count(t.exerciseMinutes, 300),
      'sp_bamboo' => _count(t.weights, 5),
      'sp_rare_hibiscus' => _count(
        c.totalCount == 0 ? 0 : (c.ownedCount * 100 / c.totalCount).floor(),
        80,
      ),
      _ => (progress: 0, done: false, comingSoon: true),
    };
  }

  static DexProgress _flag(bool done) =>
      (progress: done ? 100 : 0, done: done, comingSoon: false);

  /// [current]가 [target]에 닿으면 완료, 그 전에는 비율(%)로 진행도를 보여준다.
  static DexProgress _count(int current, int target) {
    final pct = (current * 100 / target).floor().clamp(0, 100);
    return (progress: pct, done: current >= target, comingSoon: false);
  }
}
