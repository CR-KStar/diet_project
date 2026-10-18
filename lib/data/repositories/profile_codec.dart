import 'package:diet_project/domain/models/models.dart';

/// 프로필 묶음(SavedProfile)을 저장소에 넣는 모양(Map)으로 바꾸고 되돌린다.
///
/// 목표 · 활동량 · 성별은 label 대신 enum 이름으로 저장한다. 저장 모양은 데이터 쪽 일이라
/// 도메인 모델(SavedProfile)에는 두지 않는다.
abstract final class ProfileCodec {
  /// 목표 · 활동량 · 성별은 label 대신 enum 이름으로 저장한다.
  static Map<String, Object?> toMap(SavedProfile saved) {
    final SavedProfile(
      :nickname,
      :onboardingDone,
      :onboardingStep,
      :profile,
      :notifications,
      :privacy,
      :terms,
    ) = saved;
    return {
      'nickname': nickname,
      'onboardingDone': onboardingDone,
      'onboardingStep': onboardingStep,
      'profile': {
        'goal': profile.goalType.name,
        'activity': profile.activityLevel.name,
        'gender': profile.genderType.name,
        'heightCm': profile.heightCm,
        'weightKg': profile.weightKg,
        'age': profile.age,
        'goalWeight': profile.goalWeight,
      },
      'notifications': {
        'meal': notifications.mealReminder,
        'water': notifications.waterReminder,
        'exercise': notifications.exerciseReminder,
        'friendActivity': notifications.friendActivity,
        'morningAlertTime': notifications.morningAlertTime,
        'eveningAlertTime': notifications.eveningAlertTime,
        'weeklyReportTime': notifications.weeklyReportTime,
      },
      'privacy': {
        'scope': privacy.scope.name,
        'shareGarden': privacy.shareGarden,
        'shareStreak': privacy.shareStreak,
        'shareWeightTrend': privacy.shareWeightTrend,
        'shareMealPhotos': privacy.shareMealPhotos,
        'shareChallengeRank': privacy.shareChallengeRank,
      },
      'terms': terms,
    };
  }

  static SavedProfile fromMap(
    Map<String, Object?> map, {
    required String userId,
  }) {
    final p = _asMap(map['profile']);
    final n = _asMap(map['notifications']);

    final profile = UserProfile(userId: userId);
    final goal = DietGoal.values.asNameMap()[p['goal']];
    if (goal != null) profile.goal = goal.label;
    final activity = ActivityLevel.values.asNameMap()[p['activity']];
    if (activity != null) profile.activity = activity.label;
    final gender = Gender.values.asNameMap()[p['gender']];
    if (gender != null) profile.gender = gender.label;
    profile.heightCm = _num(p['heightCm'])?.toDouble() ?? profile.heightCm;
    profile.weightKg = _num(p['weightKg'])?.toDouble() ?? profile.weightKg;
    profile.age = _num(p['age'])?.toInt() ?? profile.age;
    profile.goalWeight =
        _num(p['goalWeight'])?.toDouble() ?? profile.goalWeight;

    final notifications = NotificationSettings(userId: userId);
    notifications.mealReminder = _bool(n['meal']) ?? notifications.mealReminder;
    notifications.waterReminder =
        _bool(n['water']) ?? notifications.waterReminder;
    notifications.exerciseReminder =
        _bool(n['exercise']) ?? notifications.exerciseReminder;
    notifications.friendActivity =
        _bool(n['friendActivity']) ?? notifications.friendActivity;
    notifications.morningAlertTime =
        _str(n['morningAlertTime']) ?? notifications.morningAlertTime;
    notifications.eveningAlertTime =
        _str(n['eveningAlertTime']) ?? notifications.eveningAlertTime;
    notifications.weeklyReportTime =
        _str(n['weeklyReportTime']) ?? notifications.weeklyReportTime;

    final termsMap = _asMap(map['terms']);

    final pr = _asMap(map['privacy']);
    final privacy = PrivacySettings(userId: userId);
    final scope = ShareScope.values.asNameMap()[pr['scope']];
    if (scope != null) privacy.scope = scope;
    privacy.shareGarden = _bool(pr['shareGarden']) ?? privacy.shareGarden;
    privacy.shareStreak = _bool(pr['shareStreak']) ?? privacy.shareStreak;
    privacy.shareWeightTrend =
        _bool(pr['shareWeightTrend']) ?? privacy.shareWeightTrend;
    privacy.shareMealPhotos =
        _bool(pr['shareMealPhotos']) ?? privacy.shareMealPhotos;
    privacy.shareChallengeRank =
        _bool(pr['shareChallengeRank']) ?? privacy.shareChallengeRank;

    return SavedProfile(
      nickname: (map['nickname'] is String ? map['nickname'] as String : '')
          .trim(),
      onboardingDone: map['onboardingDone'] == true,
      onboardingStep: (_num(map['onboardingStep'])?.toInt() ?? 1).clamp(1, 4),
      profile: profile,
      notifications: notifications,
      privacy: privacy,
      terms: {
        for (final e in termsMap.entries)
          if (e.value is bool) e.key: e.value as bool,
      },
    );
  }

  static Map<String, Object?> _asMap(Object? value) =>
      value is Map ? value.cast<String, Object?>() : const {};

  static num? _num(Object? value) => value is num ? value : null;

  static bool? _bool(Object? value) => value is bool ? value : null;

  static String? _str(Object? value) => value is String ? value : null;
}
