import 'package:diet_project/domain/models/share_scope.dart';

/// 개인정보 및 공개 범위 설정
class PrivacySettings {
  PrivacySettings({
    required this.userId,
    this.scope = ShareScope.friends,
    this.shareGarden = true,
    this.shareStreak = true,
    this.shareWeightTrend = false,
    this.shareMealPhotos = true,
    this.shareChallengeRank = true,
  });

  /// 이 공개 범위 설정의 주인 — User.id
  final String userId;
  ShareScope scope;
  bool shareGarden;
  bool shareStreak;
  bool shareWeightTrend;
  bool shareMealPhotos;
  bool shareChallengeRank;
}
