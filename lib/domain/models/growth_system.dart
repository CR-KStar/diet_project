import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'enums.dart';

/// 내 식물의 현재 상태
class Plant {
  Plant({
    required this.userId,
    this.speciesId = 'sp_sprout',
    this.exp = 0,
    required this.axisScore,
    required this.cares,
    this.missedDays = 0,
    this.revived = false,
    this.wateredFriendIds = const [],
    this.inventory = const {},
    this.giftTickets = 0,
  });

  final String userId;

  /// 지금 키우는 종 — PlantSpecies.id. 관리 패턴에 따라 품종이 분화되면 바뀝니다.
  String speciesId;
  int exp;
  Map<PlantAxis, int> axisScore;
  Map<String, int> cares;     // 물 주기, 햇빛 받기, 영양 주기
  int missedDays;
  bool revived;
  List<String> wateredFriendIds;
  Map<String, int> inventory;
  int giftTickets;

  int get level => (exp / 100).floor() + 1;
  bool get wilting => missedDays >= DietRules.wiltAfterDays && !revived;
  int get graceLeft => (DietRules.graceDays - missedDays).clamp(0, DietRules.graceDays);

  int get axisSpread {
    final values = axisScore.values.toList();
    return values.reduce((a, b) => a > b ? a : b) - values.reduce((a, b) => a < b ? a : b);
  }

  bool get balanced => axisSpread <= DietRules.balanceSpreadThreshold;

  PlantAxis get weakestAxis => axisScore.entries
      .reduce((a, b) => a.value < b.value ? a : b).key;

  /// 지금 키우는 종의 카탈로그 정보
  PlantSpecies get speciesInfo =>
      PlantSpecies.catalog.firstWhere((sp) => sp.id == speciesId);

  ({String emoji, String name, int lv, double size}) get stage {
    if (level >= 20) return (emoji: '🌸', name: '꽃', lv: 20, size: 52.0);
    if (level >= 15) return (emoji: '🌿', name: '무성한 잎', lv: 15, size: 48.0);
    if (level >= 10) return (emoji: '🪴', name: '어린 잎', lv: 10, size: 42.0);
    if (level >= 5) return (emoji: '🌱', name: '새싹', lv: 5, size: 34.0);
    return (emoji: '🌰', name: '씨앗', lv: 1, size: 28.0);
  }

  String get expLeft => '${100 - (exp % 100)} EXP 남음';
  String get mood => wilting ? '목말라요' : (balanced ? '행복함' : '균형 필요');
  String get message => wilting ? '기록을 잊으셨나요? 다시 물을 주세요!' : '정성껏 돌봐주셔서 잘 자라고 있어요.';
  String get balanceHint => balanced ? '모든 기록을 골고루 남기고 계시네요!' : '부족한 ${weakestAxis.label} 기록을 채워볼까요?';

  void care(String name) {
    if ((cares[name] ?? 0) > 0) {
      cares[name] = cares[name]! - 1;
      exp += DietRules.careExp[name] ?? 10;
    }
  }

  void revive() {
    revived = true;
    missedDays = 0;
  }

  bool waterFriend(String id) {
    if (wateredFriendIds.length < DietRules.dailyFriendWatering && !wateredFriendIds.contains(id)) {
      wateredFriendIds = [...wateredFriendIds, id];
      exp += DietRules.friendWateringExp;
      return true;
    }
    return false;
  }

  void useInventoryItem(String key) {
    if ((inventory[key] ?? 0) > 0) {
      inventory[key] = inventory[key]! - 1;
      // 아이템 효과 로직 추가 가능
    }
  }

  bool sendGiftFlower() {
    if (giftTickets > 0) {
      giftTickets--;
      return true;
    }
    return false;
  }
}

/// 식물 종 정보 (도감 베이스)
class PlantSpecies {
  const PlantSpecies({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    this.condition = '성실하게 기록하면 피어나요.',
    this.emoji = '🌱',
  });

  final String id;
  final String name;
  final String tier;
  final String description;
  final String condition;
  final String emoji;

  static const catalog = [
    PlantSpecies(id: 'sp_tulip', name: '튤립', tier: '일반', description: '가장 대중적인 구근 식물입니다.', condition: '튜토리얼 완료 시 획득', emoji: '🌷'),
    PlantSpecies(id: 'sp_sunflower', name: '해바라기', tier: '일반', description: '세 축을 골고루 돌봐주면 피어나요.', condition: '균형 7일 유지', emoji: '🌻'),
    PlantSpecies(id: 'sp_rose', name: '장미', tier: '일반', description: '화려한 꽃의 대명사입니다.', condition: '식단 30회 기록', emoji: '🌹'),
    PlantSpecies(id: 'sp_daisy', name: '데이지', tier: '일반', description: '순수한 마음을 상징합니다.', condition: '물 10L 마시기', emoji: '🌼'),
    PlantSpecies(id: 'sp_monstera', name: '몬스테라', tier: '희귀', description: '정성이 많이 필요한 품종입니다.', condition: '연속 14일 기록', emoji: '🌿'),
    PlantSpecies(id: 'sp_cactus', name: '선인장', tier: '일반', description: '물이 조금 적어도 잘 자라요.', condition: '운동 10회 기록', emoji: '🌵'),
    PlantSpecies(id: 'sp_sprout', name: '새싹', tier: '일반', description: '모든 식물의 시작입니다.', condition: '첫 기록 시 획득', emoji: '🌱'),
    PlantSpecies(id: 'sp_cherry_blossom', name: '벚꽃', tier: '희귀', description: '봄의 전령사입니다.', condition: '축 100% 달성', emoji: '🌸'),
    PlantSpecies(id: 'sp_rubber_tree', name: '고무나무', tier: '일반', description: '공기 정화 능력이 탁월합니다.', condition: '누적 20회 기록', emoji: '🌳'),
    PlantSpecies(id: 'sp_clover', name: '클로버', tier: '일반', description: '행운을 가져다줍니다.', condition: '미션 50회 달성', emoji: '☘️'),
    PlantSpecies(id: 'sp_rice', name: '벼', tier: '일반', description: '한국인의 주식입니다.', condition: '아침 식사 10회', emoji: '🌾'),
    PlantSpecies(id: 'sp_lotus', name: '연꽃', tier: '희귀', description: '진흙 속에서 피어나는 꽃입니다.', condition: '물 기록 50회', emoji: '🪷'),
    PlantSpecies(id: 'sp_moss_fern', name: '이끼 고사리', tier: '희귀', description: '습한 곳을 좋아합니다.', condition: '밤 기록 10회', emoji: '🍄'),
    PlantSpecies(id: 'sp_conifer', name: '침엽수', tier: '일반', description: '늘 푸른 나무입니다.', condition: '운동 300분', emoji: '🌲'),
    PlantSpecies(id: 'sp_bamboo', name: '대나무', tier: '일반', description: '곧게 자라는 성질이 있습니다.', condition: '체중 5회 기록', emoji: '🎍'),
    PlantSpecies(id: 'sp_mutant_tulip', name: '변이 튤립', tier: '전설', description: '기적적으로 태어난 튤립입니다.', condition: '전설 씨앗 부화', emoji: '🌷'),
    PlantSpecies(id: 'sp_golden_rose', name: '황금 장미', tier: '전설', description: '영원한 사랑을 뜻합니다.', condition: '챌린지 1위 3회', emoji: '🌹'),
    PlantSpecies(id: 'sp_rare_hibiscus', name: '희귀 무궁화', tier: '전설', description: '나라를 상징하는 귀한 꽃입니다.', condition: '도감 80% 달성', emoji: '🌺'),
  ];
}

/// 사용자별 식물 획득 상태
class DexEntry {
  DexEntry({
    required this.userId,
    required this.speciesId,
    this.owned = false,
    this.progress = 0,
  });

  final String userId;
  final String speciesId;
  final bool owned;
  final int progress;
}

/// 도감 화면용 결합 모델
class DexCard {
  DexCard(this.species, this.entry);

  final PlantSpecies species;
  final DexEntry entry;

  String get speciesId => species.id;
  String get name => species.name;
  String get tier => species.tier;
  String get emoji => species.emoji;
  String get condition => species.condition;
  bool get owned => entry.owned;
  int get progress => entry.progress;

  /// AppState와 도감 화면에서 요구하는 필드들
  int get ownedVariants => owned ? 1 : 0;
  List<String> get variants => ['기본']; // 일단 기본형만 있다고 가정
}

/// 오늘의 미션
class Mission {
  const Mission({
    required this.id,
    required this.category,
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
    required this.exp,
    required this.axis,
    required this.route,
    this.special,
  });

  final String id;
  final String category;
  final String title;
  final double current;
  final double target;
  final String unit;
  final int exp;

  /// 이 미션이 올려주는 식물 성장 축 (Plant.axisScore의 키)
  final PlantAxis axis;
  final String route;
  final String? special;

  bool get done => current >= target;
  double get ratio => (current / target).clamp(0.0, 1.0);
}
