import 'package:diet_project/domain/models/models.dart';

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

  /// 목표 · 활동량 · 성별은 label 대신 enum 이름으로 저장한다.
  Map<String, Object?> toMap() => {
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

  factory SavedProfile.fromMap(
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

/// 계정별 프로필을 저장하고 불러오는 저장소.
abstract class ProfileRepository {
  /// 저장된 프로필이 없으면(처음 가입) null.
  Future<SavedProfile?> load(String uid);

  Future<void> save(String uid, SavedProfile profile);

  Future<void> delete(String uid);
}

/// Firebase 없이 메모리에만 저장하는 버전 — 테스트용.
class MemoryProfileRepository implements ProfileRepository {
  final Map<String, Map<String, Object?>> _store = {};

  @override
  Future<SavedProfile?> load(String uid) async {
    final map = _store[uid];
    return map == null ? null : SavedProfile.fromMap(map, userId: uid);
  }

  @override
  Future<void> save(String uid, SavedProfile profile) async {
    _store[uid] = profile.toMap();
  }

  @override
  Future<void> delete(String uid) async {
    _store.remove(uid);
  }
}
