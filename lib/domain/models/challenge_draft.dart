import 'package:diet_project/domain/models/challenge_reward.dart';
import 'package:diet_project/domain/models/challenge_type.dart';
import 'package:diet_project/domain/models/challenge_visibility.dart';

/// 챌린지를 만들기 전 입력하는 값입니다.
class ChallengeDraft {
  ChallengeDraft({
    this.type = ChallengeType.water,
    this.dailyTarget = 2000,
    this.durationDays = 14,
    this.visibility = ChallengeVisibility.private,
    this.reward = ChallengeReward.plantExperience,
    List<String>? invitedUserIds,
  }) : invitedUserIds = invitedUserIds ?? [];

  ChallengeType type;
  int dailyTarget;
  int durationDays;
  ChallengeVisibility visibility;
  ChallengeReward reward;
  List<String> invitedUserIds;
}
