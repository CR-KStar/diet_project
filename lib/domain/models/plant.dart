import 'package:diet_project/domain/rules/diet_rules.dart';
import 'package:diet_project/domain/models/plant_axis.dart';
import 'package:diet_project/domain/models/plant_species.dart';
import 'package:diet_project/domain/models/record_kind.dart';
import 'package:diet_project/domain/models/record_tally.dart';

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
    this.startedKey = '',
    this.revivedKey = '',
    this.friendWaterKey = '',
    RecordTally? tally,
  }) : tally = tally ?? RecordTally();

  /// 새 계정의 시작 식물 — 경험치 0, 세 축 0점.
  factory Plant.starter(String userId) => Plant(
    userId: userId,
    axisScore: {for (final a in PlantAxis.values) a: 0},
    cares: {'물 주기': 3, '햇빛 받기': 2, '영양 주기': 2},
    inventory: {'물방울': 3, '희귀 씨앗': 0, '전설 씨앗': 0, '정원 장식': 0},
  );

  final String userId;

  /// 지금 키우는 종 — PlantSpecies.id. 관리 패턴에 따라 품종이 분화되면 바뀝니다.
  String speciesId;
  int exp;
  Map<PlantAxis, int> axisScore;
  Map<String, int> cares; // 물 주기, 햇빛 받기, 영양 주기
  int missedDays;
  bool revived;
  List<String> wateredFriendIds;
  Map<String, int> inventory;
  int giftTickets;

  /// 이 식물을 처음 키우기 시작한 날(yyyy-MM-dd) — 이 날 전의 날은 "기록을 쉰 날"로 세지 않는다.
  String startedKey;

  /// "회복 돌보기"를 누른 날 — 그날 하루만 시들지 않은 것으로 본다.
  String revivedKey;

  /// 친구 정원에 물을 준 날 — 날짜가 바뀌면 하루 한도(물 주기 횟수)를 새로 시작한다.
  String friendWaterKey;

  /// 지금까지 남긴 기록의 누적 횟수 (도감 조건 계산용).
  RecordTally tally;

  int get level => (exp / 100).floor() + 1;
  bool get wilting => missedDays >= DietRules.wiltAfterDays && !revived;
  int get graceLeft =>
      (DietRules.graceDays - missedDays).clamp(0, DietRules.graceDays);

  int get axisSpread {
    final values = axisScore.values.toList();
    return values.reduce((a, b) => a > b ? a : b) -
        values.reduce((a, b) => a < b ? a : b);
  }

  /// 세 축이 비슷하게 자랐는지 — 아직 아무 축도 자라지 않았으면(모두 0점) 균형이라 부르지 않는다.
  bool get balanced =>
      axisSpread <= DietRules.balanceSpreadThreshold &&
      axisScore.values.any((v) => v > 0);

  PlantAxis get weakestAxis =>
      axisScore.entries.reduce((a, b) => a.value < b.value ? a : b).key;

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
  String get message =>
      wilting ? '기록을 잊으셨나요? 다시 물을 주세요!' : '정성껏 돌봐주셔서 잘 자라고 있어요.';
  String get balanceHint => axisScore.values.every((v) => v == 0)
      ? '돌보기를 눌러서 식물을 키워 보세요.'
      : balanced
      ? '세 가지를 골고루 돌보고 계시네요!'
      : '부족한 ${weakestAxis.label} 쪽을 돌봐볼까요?';

  /// 돌보기 한 번 — 남은 횟수가 있으면 EXP와 그 축 점수(최대 100)가 같은 만큼 오른다.
  void care(String name) {
    if ((cares[name] ?? 0) > 0) {
      cares[name] = cares[name]! - 1;
      final gain = DietRules.careExp[name] ?? 10;
      exp += gain;
      final axis = DietRules.careAxis[name];
      if (axis != null) {
        axisScore[axis] = ((axisScore[axis] ?? 0) + gain).clamp(
          0,
          DietRules.axisMax,
        );
      }
    }
  }

  /// 기록을 남기면 그 기록에 맞는 돌보기가 1회 충전된다 (쌓아 둘 수 있는 최대 횟수까지).
  void recharge(RecordKind kind) {
    final name = DietRules.careRechargedBy[kind];
    if (name == null) return;
    final cap = DietRules.careCapacity[name] ?? 0;
    cares[name] = ((cares[name] ?? 0) + 1).clamp(0, cap);
  }

  /// 오늘([todayKey])은 시들지 않은 것으로 한다.
  void revive(String todayKey) {
    revived = true;
    revivedKey = todayKey;
    missedDays = 0;
  }

  bool waterFriend(String id) {
    if (wateredFriendIds.length < DietRules.dailyFriendWatering &&
        !wateredFriendIds.contains(id)) {
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
