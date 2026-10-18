import 'package:diet_project/domain/models/user_profile.dart';

/// 계정 하나에 저장해 두는 프로필 묶음.
class SavedProfile {
  const SavedProfile({
    required this.nickname,
    required this.onboardingDone,
    required this.profile,
    required this.notifications,
    required this.privacy,
    this.onboardingStep = 1,
    this.terms = const {},
  });

  final String nickname;
  final bool onboardingDone;

  /// 온보딩 도중에 나갔을 때 이어서 시작할 단계 (1~4).
  final int onboardingStep;
  final UserProfile profile;
  final NotificationSettings notifications;
  final PrivacySettings privacy;

  /// 약관 동의 상태 — 키는 화면에 보이는 약관 이름 그대로.
  final Map<String, bool> terms;
}
