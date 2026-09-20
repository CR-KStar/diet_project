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
  final bool isPublic;
  final String rewardDescription;
  final String bonusDescription;

  bool isParticipant(String userId) => participantIds.contains(userId);
  bool isCreatedBy(String userId) => creatorId == userId;
  String get peopleLabel => '${participantIds.length}명 참여';
}
