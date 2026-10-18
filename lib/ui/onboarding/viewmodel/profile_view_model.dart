import 'dart:async';

import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_project/domain/repositories/profile_repository.dart';

/// 계정과 함께 저장되는 "내 정보" 전부를 담당한다 — 닉네임 · 신체 정보와 목표 · 약관 동의 ·
/// 알림 설정 · 친구에게 보이는 공개 범위 · 온보딩 진행 상황.
///
/// 이 값들은 한 덩어리(SavedProfile)로 저장되므로, 하나라도 바뀌면 전체를 다시 저장한다.
/// 로그인 · 로그아웃과 다른 기록들을 함께 불러오는 일(순서가 중요한 부분)은 AppState가 맡는다.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required ProfileRepository profiles})
    : _profiles = profiles;

  final ProfileRepository _profiles;

  /// 로그인한 계정의 uid. 로그인 전에는 null이고, 그동안은 저장하지 않는다.
  String? uid;

  /// 백그라운드 저장이 실패했을 때, 사용자에게 보여줄 문구와 함께 불린다.
  void Function(String message)? onSyncFailed;

  /// 마지막 저장이 실패한 이유 (저장이 성공하면 비우지 않고, 실패할 때만 갱신한다).
  String? saveError;

  // ── 온보딩 ──────────────────────────────────────────────────────────
  String nickname = '새싹';

  /// 1 계정연결 / 2 목표 / 3 신체 / 4 알림
  int step = 1;
  bool onboardingDone = false;

  /// 온보딩 도중에 나갔을 때 다시 들어와서 이어서 시작할 단계.
  int resumeStep = 1;

  static const _defaultTerms = {
    '(필수) 서비스 이용약관': true,
    '(필수) 개인정보 처리방침': true,
    '(필수) 민감 건강정보 수집·이용 동의': false,
    '(선택) 마케팅 정보 수신': false,
  };

  final Map<String, bool> terms = {..._defaultTerms};

  bool get requiredTermsOk =>
      terms.entries.where((e) => e.key.contains('필수')).every((e) => e.value);

  void toggleTerm(String k) {
    terms[k] = !(terms[k] ?? false);
    notifyListeners();
    unawaited(persistAndReport());
  }

  void toggleAllTerms() {
    final all = terms.values.every((v) => v);
    for (final k in terms.keys) {
      terms[k] = !all;
    }
    notifyListeners();
    unawaited(persistAndReport());
  }

  // ── 신체 정보 · 목표 ─────────────────────────────────────────────────
  UserProfile profile = UserProfile(userId: User.meId);

  // 입력 화면(온보딩 · 내 정보 수정)이 쓰는 값들 — 바꾸면 화면이 바로 다시 그려진다.
  String get goal => profile.goal;
  set goal(String v) {
    profile.goal = v;
    notifyListeners();
  }

  String get activity => profile.activity;
  set activity(String v) {
    profile.activity = v;
    notifyListeners();
  }

  String get gender => profile.gender;
  set gender(String v) {
    profile.gender = v;
    notifyListeners();
  }

  double get heightCm => profile.heightCm;
  set heightCm(double v) {
    profile.heightCm = v;
    notifyListeners();
  }

  double get weightKg => profile.weightKg;
  set weightKg(double v) {
    profile.weightKg = v;
    notifyListeners();
  }

  int get age => profile.age;
  set age(int v) {
    profile.age = v;
    notifyListeners();
  }

  double get goalWeight => profile.goalWeight;
  set goalWeight(double v) {
    profile.goalWeight = v;
    notifyListeners();
  }

  double get bmi => profile.bmi;
  double get bmr => profile.bmr;
  int get dailyTarget => profile.dailyTarget;
  String get goalDelta => profile.goalDelta;

  /// 체중을 기록하면 프로필의 현재 체중도 함께 바뀐다.
  void onWeightLogged(double kg) {
    profile.weightKg = kg;
    unawaited(persistAndReport());
  }

  // ── 알림 ────────────────────────────────────────────────────────────

  /// 알림 화면과 온보딩이 함께 쓰는 사용자 알림 설정입니다.
  final NotificationSettings notificationSettings = NotificationSettings(
    userId: User.meId,
  );

  Map<String, bool> get onboardAlerts => {
    '식단 미기록 알림': notificationSettings.mealReminder,
    '물 마시기 알림': notificationSettings.waterReminder,
    '운동 리마인드': notificationSettings.exerciseReminder,
    '친구 응원 알림': notificationSettings.friendActivity,
  };

  /// 온보딩에서는 켜고 끄기만 하고, 저장은 단계를 넘길 때 한꺼번에 한다.
  void toggleOnboardAlert(String label) {
    _flipNotify(label);
    notifyListeners();
  }

  // 설정 화면에 보이는 토글 · 시간은 새 상태가 아니라, 이미 계정에 저장되고 있는
  // notificationSettings를 화면이 읽기 쉬운 한글 키로 보여주는 것뿐이다.
  Map<String, bool> get notifyToggles => onboardAlerts;

  Map<String, String> get alertTime => {
    '아침 기록 알림': notificationSettings.morningAlertTime,
    '저녁 정리 알림': notificationSettings.eveningAlertTime,
    '주간 리포트': notificationSettings.weeklyReportTime,
  };

  void toggleNotify(String k) {
    _flipNotify(k);
    notifyListeners();
    unawaited(persistAndReport());
  }

  void setAlertTime(String key, String value) {
    switch (key) {
      case '아침 기록 알림':
        notificationSettings.morningAlertTime = value;
      case '저녁 정리 알림':
        notificationSettings.eveningAlertTime = value;
      case '주간 리포트':
        notificationSettings.weeklyReportTime = value;
    }
    notifyListeners();
    unawaited(persistAndReport());
  }

  void _flipNotify(String label) {
    switch (label) {
      case '식단 미기록 알림':
        notificationSettings.mealReminder = !notificationSettings.mealReminder;
      case '물 마시기 알림':
        notificationSettings.waterReminder =
            !notificationSettings.waterReminder;
      case '운동 리마인드':
        notificationSettings.exerciseReminder =
            !notificationSettings.exerciseReminder;
      case '친구 응원 알림':
        notificationSettings.friendActivity =
            !notificationSettings.friendActivity;
    }
  }

  // ── 친구에게 보이는 공개 범위 ─────────────────────────────────────────
  final PrivacySettings privacySettings = PrivacySettings(userId: User.meId);

  String get shareScope => privacySettings.scope.label;
  set shareScope(String value) => privacySettings.scope = value == '비공개'
      ? ShareScope.private
      : ShareScope.friends;

  void setShareScope(String s) {
    shareScope = s;
    notifyListeners();
    unawaited(persistAndReport());
  }

  static const friendVisibilityDesc = {
    '식물 · 정원': '단계 · 변이 · 도감 수집률',
    '연속 기록 · 스트릭': '며칠 연속 기록했는지',
    '체중 변화': '증감 추세만 (실제 수치 제외)',
    '식단 사진': '기록한 음식 사진',
    '챌린지 순위': '참여 챌린지의 내 순위',
  };

  Map<String, bool> get friendVisibility => {
    '식물 · 정원': privacySettings.shareGarden,
    '연속 기록 · 스트릭': privacySettings.shareStreak,
    '체중 변화': privacySettings.shareWeightTrend,
    '식단 사진': privacySettings.shareMealPhotos,
    '챌린지 순위': privacySettings.shareChallengeRank,
  };

  void toggleFriendVisibility(String k) {
    switch (k) {
      case '식물 · 정원':
        privacySettings.shareGarden = !privacySettings.shareGarden;
        break;
      case '연속 기록 · 스트릭':
        privacySettings.shareStreak = !privacySettings.shareStreak;
        break;
      case '체중 변화':
        privacySettings.shareWeightTrend = !privacySettings.shareWeightTrend;
        break;
      case '식단 사진':
        privacySettings.shareMealPhotos = !privacySettings.shareMealPhotos;
        break;
      case '챌린지 순위':
        privacySettings.shareChallengeRank =
            !privacySettings.shareChallengeRank;
        break;
    }
    notifyListeners();
    unawaited(persistAndReport());
  }

  String get friendVisibilitySummary {
    final on = friendVisibility.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    return on.isEmpty
        ? '$shareScope · 공개 항목 없음'
        : '$shareScope · 공개 항목 ${on.length}개 — ${on.join(', ')}';
  }

  bool get gardenPublic => privacySettings.shareGarden;

  void toggleGardenPublic() {
    privacySettings.shareGarden = !privacySettings.shareGarden;
    notifyListeners();
    unawaited(persistAndReport());
  }

  // ── 불러오기 · 저장 · 비우기 · 삭제 ───────────────────────────────────

  /// 로그인한 계정의 저장된 프로필을 불러와 반영한다. 저장된 게 없으면(처음 가입)
  /// 계정 이름을 닉네임으로 쓴다. 불러오지 못하면 예외를 그대로 던지고 아무것도 바꾸지 않는다.
  ///
  /// [skipOnboardingForNewAccount]: 웹 체험판(로그인 없는 데모)은 온보딩 없이 바로
  /// 홈의 예시 데이터를 보여준다.
  Future<void> loadFor(
    AuthAccount account, {
    required bool skipOnboardingForNewAccount,
  }) async {
    final saved = await _profiles.load(account.uid);
    uid = account.uid;
    if (saved != null) {
      onboardingDone = saved.onboardingDone;
      resumeStep = saved.onboardingStep;
      profile = saved.profile;
      notificationSettings
        ..mealReminder = saved.notifications.mealReminder
        ..waterReminder = saved.notifications.waterReminder
        ..exerciseReminder = saved.notifications.exerciseReminder
        ..friendActivity = saved.notifications.friendActivity
        ..morningAlertTime = saved.notifications.morningAlertTime
        ..eveningAlertTime = saved.notifications.eveningAlertTime
        ..weeklyReportTime = saved.notifications.weeklyReportTime;
      privacySettings
        ..scope = saved.privacy.scope
        ..shareGarden = saved.privacy.shareGarden
        ..shareStreak = saved.privacy.shareStreak
        ..shareWeightTrend = saved.privacy.shareWeightTrend
        ..shareMealPhotos = saved.privacy.shareMealPhotos
        ..shareChallengeRank = saved.privacy.shareChallengeRank;
      if (saved.terms.isNotEmpty) {
        for (final e in saved.terms.entries) {
          if (terms.containsKey(e.key)) terms[e.key] = e.value;
        }
      }
      if (saved.nickname.isNotEmpty) nickname = saved.nickname;
    } else {
      onboardingDone = skipOnboardingForNewAccount;
      resumeStep = 1;
      final name = account.displayName?.trim();
      if (name != null && name.isNotEmpty) nickname = name;
    }
    notifyListeners();
  }

  /// 지금 값을 계정에 저장한다. 로그인 전(uid 없음)에는 저장할 곳이 없어 true.
  /// 실패하면 false이고, 이유는 [saveError]에 있다.
  Future<bool> persist() async {
    final id = uid;
    if (id == null) return true;
    try {
      await _profiles
          .save(
            id,
            SavedProfile(
              nickname: nickname,
              onboardingDone: onboardingDone,
              onboardingStep: step.clamp(1, 4),
              profile: profile,
              notifications: notificationSettings,
              privacy: privacySettings,
              terms: terms,
            ),
          )
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e, stack) {
      debugPrint('프로필을 저장하지 못했어요: $e\n$stack');
      saveError = '내 정보를 저장하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.';
      return false;
    }
  }

  /// 저장하고, 실패하면 화면 밖 안내([onSyncFailed])로 알린다. 화면은 막지 않는다.
  Future<void> persistAndReport() async {
    if (!await persist()) {
      onSyncFailed?.call(saveError!);
    }
  }

  /// 로그아웃 · 계정 삭제 뒤에 개인 정보를 처음 상태로 되돌린다.
  void reset() {
    uid = null;
    onboardingDone = false;
    resumeStep = 1;
    nickname = '';
    step = 1;
    profile = UserProfile(userId: User.meId);
    notificationSettings
      ..mealReminder = true
      ..waterReminder = true
      ..exerciseReminder = false
      ..friendActivity = true;
    // 약관 동의와 공개 범위도 처음 상태로 — 같은 기기에서 다음 계정이 로그인할 때
    // 이전 계정의 동의(특히 민감 건강정보 동의)를 물려받으면 안 된다.
    terms
      ..clear()
      ..addAll(_defaultTerms);
    privacySettings
      ..scope = ShareScope.friends
      ..shareGarden = true
      ..shareStreak = true
      ..shareWeightTrend = false
      ..shareMealPhotos = true
      ..shareChallengeRank = true;
    notifyListeners();
  }

  Future<void> deleteProfile(String uid) => _profiles.delete(uid);
}
