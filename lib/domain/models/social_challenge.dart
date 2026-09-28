import 'enums.dart';

/// 챌린지 모델
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.period,
    required this.creatorId,
    required this.participantIds,
    required this.metricType,
    required this.targetValue,
    this.isPublic = true,
    this.rewardDescription = '',
    this.bonusDescription = '',
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final String period;
  final String creatorId;
  final List<String> participantIds;

  /// 이 챌린지가 실제로 뭘 재는지(물 · 운동 · 식단 기록 · 단백질) —
  /// 리더보드 진행률을 계산할 때 이 값으로 어떤 기록을 볼지 정한다.
  final ChallengeType metricType;

  /// metricType 기준으로 "완료"로 치는 하루 목표치(예: 물 2000ml).
  final num targetValue;

  final bool isPublic;
  final String rewardDescription;
  final String bonusDescription;

  bool isParticipant(String userId) => participantIds.contains(userId);
  bool isCreatedBy(String userId) => creatorId == userId;
  String get peopleLabel => '${participantIds.length}명 참여';
}
