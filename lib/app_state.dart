// 앱 전역 상태 — 프로토타입의 Component.state를 그대로 옮긴 ChangeNotifier.
//
// 화면 전환도 여기서 관리합니다 (Navigator 대신 screen 문자열).
// 통합된 화면은 부모 screen + 서브 모드 플래그로 표현합니다.

import 'dart:convert';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';
import 'package:diet_project/data/services/meal_recommendation_service.dart';
import 'package:diet_project/data/services/notification_service.dart';
import 'package:diet_project/data/repositories/friend_repository.dart';
import 'package:diet_project/common.dart' show AppStateFormat;
import 'package:diet_project/data/auth/mock_auth_service.dart';
import 'package:diet_project/data/repositories/profile_repository.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/data/repositories/water_repository.dart';
import 'package:diet_project/ui/record/viewmodel/water_view_model.dart';
import 'package:diet_project/data/repositories/challenge_repository.dart';
import 'package:diet_project/data/repositories/activity_feed_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart' show Offset, Color;
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data/auth/auth_service.dart';

export 'package:diet_project/domain/models/models.dart';

/// 오늘의 미션 풀 하나의 정의. `current`는 AppState의 실시간 값을 읽어오는
/// 함수라서, 미션이 뽑힌 뒤에도 항상 최신 진행도를 보여준다.
class _MissionTemplate {
  const _MissionTemplate({
    required this.id,
    required this.title,
    required this.target,
    required this.unit,
    required this.exp,
    required this.axis,
    required this.route,
    required this.current,
    this.special,
  });

  final String id;
  final String title;
  final double target;
  final String unit;
  final int exp;
  final PlantAxis axis;
  final String route;
  final String? special;
  final double Function(AppState) current;
}

/// 영양소 하나의 오늘 합계 — 목표 대비 비율과 끼니별 분해까지 담는다.
class NutrientStat {
  const NutrientStat({
    required this.name,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  final String name;
  final String unit;
  final double value;
  final double target;
  final Color color;
  final double breakfast;
  final double lunch;
  final double dinner;
  final double snack;

  int get pct => target <= 0 ? 0 : (value / target * 100).round();

  /// 80% 이상이면 "적정", 그 아래면 "부족"으로 본다 — 간단한 기준이라
  /// 100%를 초과해도 "적정"으로 표시된다(초과 자체를 경고로 다루진 않는다).
  bool get isLow => pct < 80;
}

class AppState extends ChangeNotifier {
  AppState({
    AuthService? auth,
    ProfileRepository? profiles,
    WaterViewModel? waterViewModel,
    RecordRepository<WeightEntry>? weightRepo,
    RecordRepository<ExerciseLog>? exerciseRepo,
    RecordRepository<MealLog>? mealRepo,
    RecordRepository<Bowl>? bowlRepo,
    RecordRepository<Routine>? routineRepo,
    RecordRepository<Plant>? plantRepo,
    RecordRepository<DexEntry>? dexRepo,
    FriendRepository? friendRepo,
    ChallengeRepository? challengeRepo,
    ActivityFeedRepository? activityFeedRepo,
    DateTime Function()? now,
  }) : _auth = auth ?? MockAuthService(),
       _profiles = profiles ?? MemoryProfileRepository(),
       _waterViewModel =
           waterViewModel ?? WaterViewModel(waterRepo: MemoryWaterRepository()),
       _weightRepo = weightRepo ?? MemoryRecordRepository(weightCodec),
       _exerciseRepo = exerciseRepo ?? MemoryRecordRepository(exerciseCodec),
       _mealRepo = mealRepo ?? MemoryRecordRepository(mealCodec),
       _bowlRepo = bowlRepo ?? MemoryRecordRepository(bowlCodec),
       _routineRepo = routineRepo ?? MemoryRecordRepository(routineCodec),
       _plantRepo = plantRepo ?? MemoryRecordRepository(plantCodec),
       _dexRepo = dexRepo ?? MemoryRecordRepository(dexEntryCodec),
       _friendRepo = friendRepo ?? MemoryFriendRepository(),
       _challengeRepo = challengeRepo ?? MemoryChallengeRepository(),
       _activityFeedRepo = activityFeedRepo ?? MemoryActivityFeedRepository(),
       _now = now ?? DateTime.now;

  final AuthService _auth;
  final ProfileRepository _profiles;

  /// 물 기록은 이제 이 화면 전용 ViewModel이 갖고 있다 — AppState는 연속
  /// 기록 계산 · 오늘의 기록 요약 · 미션 진행도 계산에 필요할 때만 이걸
  /// 통해서 읽는다(물 데이터를 따로 복사해서 들고 있지 않는다).
  final WaterViewModel _waterViewModel;
  final RecordRepository<WeightEntry> _weightRepo;
  final RecordRepository<ExerciseLog> _exerciseRepo;
  final RecordRepository<MealLog> _mealRepo;
  final RecordRepository<Bowl> _bowlRepo;
  final RecordRepository<Routine> _routineRepo;
  final RecordRepository<Plant> _plantRepo;
  final RecordRepository<DexEntry> _dexRepo;
  final FriendRepository _friendRepo;
  final ChallengeRepository _challengeRepo;
  final ActivityFeedRepository _activityFeedRepo;

  /// 테스트에서 날짜를 고정할 수 있도록 시계를 주입받는다.
  final DateTime Function() _now;

  // 화면 전환
  String screen = 'login';

  // 서브 모드 (통합된 화면)
  bool missionOpen = false; // home
  bool extraOpen = false; // capture
  bool editing = false; // mealDetail
  bool profileEdit = false; // my
  String plantTab = '식물'; // 식물 / 도감
  String friendTab = '활동'; // 활동 / 챌린지 / 친구 추가
  String setTab = '알림'; // 알림 / 데이터 · 개인정보

  /// 옛 화면 id → 부모 화면 + 서브 모드
  static const _alias = <String, Map<String, Object>>{
    'signup': {'screen': 'onboard', 'step': 1},
    'mission': {'screen': 'home', 'missionOpen': true},
    'dex': {'screen': 'plant', 'plantTab': '도감'},
    'extra': {'screen': 'capture', 'extraOpen': true},
    'mealEdit': {'screen': 'mealDetail', 'editing': true},
    'challenge': {'screen': 'friends', 'friendTab': '챌린지'},
    'alerts': {'screen': 'settings', 'setTab': '알림'},
    'privacy': {'screen': 'settings', 'setTab': '데이터 · 개인정보'},
  };

  /// 화면 이동 기록 — 안드로이드 시스템 뒤로가기 버튼으로 이전 화면에
  /// 돌아가는 데 쓴다. (handleSystemBack 참고)
  final List<String> _history = [];

  void go(String id) {
    final resolvedScreen = (_alias[id]?['screen'] as String?) ?? id;
    if (showShell && screen != resolvedScreen) {
      _history.add(screen);
    }

    // 서브 모드 초기화
    missionOpen = false;
    extraOpen = false;
    editing = false;
    profileEdit = false;
    plantTab = '식물';
    friendTab = '활동';
    setTab = '알림';

    final a = _alias[id];
    if (a != null) {
      screen = a['screen'] as String;
      if (a.containsKey('step')) step = a['step'] as int;
      missionOpen = a['missionOpen'] as bool? ?? false;
      extraOpen = a['extraOpen'] as bool? ?? false;
      editing = a['editing'] as bool? ?? false;
      plantTab = a['plantTab'] as String? ?? '식물';
      friendTab = a['friendTab'] as String? ?? '활동';
      setTab = a['setTab'] as String? ?? '알림';
    } else {
      screen = id;
      if (id == 'report') period = '주간';
      if (id == 'onboard') step = 2;
      if (id == 'recommend' && aiRecommendations == null) {
        unawaited(fetchAiRecommendations());
      }
    }
    fabOpen = false;
    bowlSheet = false;
    waterSheet = false;
    notifyListeners();
  }

  void setSub(void Function() mutate) {
    mutate();
    notifyListeners();
  }

  /// 더 뒤로 갈 곳이 없을 때, 뒤로가기를 한 번 더 눌러야 진짜 종료되게
  /// 하는 유예 시각. 이 안에 다시 누르면 종료, 아니면 다시 "한 번 더"
  /// 안내로 되돌아간다.
  DateTime? _backExitArmedAt;

  /// 안드로이드 시스템 뒤로가기(제스처/버튼)를 눌렀을 때 호출한다.
  /// 열려 있는 시트 → 서브 화면(부가 정보 입력 등) → 이전 화면 순서로 하나씩
  /// 닫고, true를 반환한다. 더 닫을 게 없으면(최상위 화면) 안내를 한 번
  /// 보여주고 true를 반환하며, 2초 안에 한 번 더 누르면 그때 false를
  /// 반환해서 시스템이 앱을 종료하게 둔다.
  ///
  /// false를 절대 안 주는 버전이 없으면 앱 안 어디서 뒤로가기를 눌러도
  /// 화면 이동 없이 앱이 통째로 꺼져버린다 — Flutter가 자체 화면 전환
  /// 기록(Navigator)을 안 쓰고 `screen` 문자열 하나로 화면을 바꾸는
  /// 구조라서, 시스템 입장에선 "뒤로 갈 곳이 없는 화면 1개"로만 보인다.
  bool handleSystemBack() {
    if (fabOpen || waterSheet || bowlSheet) {
      fabOpen = false;
      waterSheet = false;
      bowlSheet = false;
      notifyListeners();
      return true;
    }
    if (missionOpen || extraOpen || editing || profileEdit) {
      missionOpen = false;
      extraOpen = false;
      editing = false;
      profileEdit = false;
      notifyListeners();
      return true;
    }
    if (_history.isNotEmpty) {
      screen = _history.removeLast();
      notifyListeners();
      return true;
    }

    final now = _now();
    final armed =
        _backExitArmedAt != null &&
        now.difference(_backExitArmedAt!) < const Duration(seconds: 2);
    if (armed) {
      _backExitArmedAt = null;
      return false;
    }
    _backExitArmedAt = now;
    _notice = '뒤로가기를 한 번 더 누르면 앱이 종료돼요.';
    notifyListeners();
    return true;
  }

  /// 하단 탭 활성 판정용 그룹
  static const tabGroups = <String, List<String>>{
    'home': ['home', 'notif', 'nutrition', 'recommend', 'plant'],
    'records': ['records', 'capture', 'exercise', 'weight', 'mealDetail'],
    'report': ['report'],
    'friends': ['friends', 'chNew'],
    'my': ['my', 'bowls', 'profile', 'settings'],
  };

  bool get showShell => screen != 'login' && screen != 'onboard';

  // 오늘 날짜
  static String dateKeyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 오늘 (시간은 버리고 날짜만)
  DateTime get today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  int get todayYear => today.year;
  int get todayMonth => today.month;
  int get todayDay => today.day;

  String get _todayKey => dateKeyOf(today);
  String get _selectedKey => dateKeyOf(DateTime(year, month, day));
  bool get _viewingToday => _selectedKey == _todayKey;

  static const _weekdayNames = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  /// 예: "9월 21일"
  String get todayDateLabel => '$todayMonth월 $todayDay일';

  /// 예: "9월 21일 월요일"
  String get todayLabel =>
      '$todayDateLabel ${_weekdayNames[today.weekday - 1]}';

  // 인증 · 온보딩
  String provider = 'Google';
  String nickname = '채린';

  /// 로그인한 계정 (로그인 전에는 null)
  AuthAccount? account;

  /// 로그인 버튼 중복 탭 방지.
  bool signingIn = false;

  /// 마지막 로그인 · 계정 삭제 실패 문구 (화면이 토스트로 보여주고 비운다)
  String? authError;

  /// 성공 true, 취소 false, 실패 false + authError.
  Future<bool> signIn(LoginProvider p) async {
    if (signingIn) return false;
    signingIn = true;
    authError = null;
    notifyListeners();
    try {
      final result = await _auth.signIn(p);
      if (result == null) return false;
      return await _enter(result);
    } on AuthFailure catch (e) {
      authError = e.message;
      return false;
    } catch (e, stack) {
      debugPrint('로그인 중 예상치 못한 오류: $e\n$stack');
      authError = '로그인 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요.';
      return false;
    } finally {
      signingIn = false;
      notifyListeners();
    }
  }

  /// 앱을 켤 때 호출 — 로그인 · 온보딩 완료 여부에 따라 알맞은 화면으로 보낸다.
  Future<bool> restoreSession() async {
    final current = await _auth.restoreAccount();
    if (current == null) return false;
    if (!await _enter(current)) return false;
    goAfterLogin();
    return true;
  }

  /// 온보딩 완료 계정은 홈으로, 아니면 저장된 단계의 온보딩으로 보낸다.
  void goAfterLogin() {
    if (onboardingDone) {
      go('home');
      return;
    }
    go('signup'); // 온보딩 1단계 (이때 step이 1로 초기화된다)
    step = _resumeStep;
    notifyListeners();
  }

  int _resumeStep = 1;

  /// 화면 밖 안내 문구(저장 실패, 로그아웃 등) — main.dart가 스낵바로 보여주고 비운다.
  String? _notice;

  String? takeNotice() {
    final message = _notice;
    _notice = null;
    return message;
  }

  /// 온보딩 단계를 넘기고 진행 상황을 저장한다. 실패해도 화면은 막지 않는다.
  Future<void> goToStep(int next) async {
    step = next;
    notifyListeners();
    await _persistInBackground();
  }

  Future<void> _persistInBackground() async {
    if (!await _persist()) {
      _notice = authError;
      authError = null;
      notifyListeners();
    }
  }

  bool onboardingDone = false;

  /// 로그인한 계정의 저장된 프로필을 불러와 반영한다. 없으면 계정 이름을 닉네임으로 쓴다.
  Future<bool> _enter(AuthAccount a) async {
    try {
      final saved = await _profiles.load(a.uid);
      account = a;
      provider = a.provider.label;
      if (!_isDemo) _clearSampleRecords();
      if (saved != null) {
        onboardingDone = saved.onboardingDone;
        _resumeStep = saved.onboardingStep;
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
        onboardingDone = false;
        _resumeStep = 1;
        final name = a.displayName?.trim();
        if (name != null && name.isNotEmpty) nickname = name;
      }
      if (!_isDemo) await _loadAccountData(a.uid);
      unawaited(_applyNotificationSchedule());
      return true;
    } catch (e, stack) {
      debugPrint('프로필을 불러오지 못했어요: $e\n$stack');
      authError = '내 정보를 불러오지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.';
      return false;
    }
  }

  /// 온보딩 완료를 저장하고 홈으로 간다. 저장 실패 시 false.
  Future<bool> completeOnboarding() async {
    final before = onboardingDone;
    onboardingDone = true;
    if (!await _persist()) {
      onboardingDone = before;
      notifyListeners();
      return false;
    }
    go('home');
    return true;
  }

  Future<bool> saveProfile() => _persist();

  Future<bool> _persist() async {
    final a = account;
    if (a == null) return true;
    try {
      await _profiles
          .save(
            a.uid,
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
      authError = '내 정보를 저장하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.';
      return false;
    }
  }

  /// 가짜 로그인(Mock)일 때만 true — 이때는 예시 기록을 그대로 보여준다.
  bool get _isDemo => _auth is MockAuthService;

  /// 예시 기록을 비운다. 실제 계정은 자기 기록만 보여야 한다.
  void _clearSampleRecords() {
    _mealLogs.clear();
    _exerciseLogs.clear();
    _plantSaveTimer?.cancel();
    _plantSaveTimer = null;
    weightEntries = [];
    bowls = [];
    routines = [];
    bowlIndex = 0;
    plant = Plant.starter(_uid);
    _plantSyncOk = true;
    dexEntries = [
      for (final sp in PlantSpecies.catalog)
        DexEntry(userId: _uid, speciesId: sp.id),
    ];
    inviteCode = '';
    realFriends = [];
    incomingFriendRequests = [];
    requesterProfiles = {};
    friendSearchResult = null;
    friendSearchNotFound = false;
    _loadedMonths.clear();
  }

  void _resetPersonal() {
    if (!_isDemo) _clearSampleRecords();
    account = null;
    onboardingDone = false;
    _resumeStep = 1;
    nickname = '';
    step = 1;
    profile = UserProfile(userId: User.meId);
    notificationSettings
      ..mealReminder = true
      ..waterReminder = true
      ..exerciseReminder = false
      ..friendActivity = true;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _resetPersonal();
    _notice = '로그아웃했어요.';
    go('login');
  }

  /// 계정 삭제에 성공하면 true, 실패하면 false(authError에 사용자용 문구).
  Future<bool> deleteAccount() async {
    if (deleting) return false;
    deleting = true;
    authError = null;
    notifyListeners();
    final uid = account?.uid;
    try {
      await _auth.deleteAccount(
        beforeDelete: uid == null ? null : () => _deleteAllUserData(uid),
      );
      _resetPersonal();
      _notice = '계정과 저장된 정보를 모두 삭제했어요.';
      go('login');
      return true;
    } on AuthFailure catch (e) {
      authError = e.message;
      return false;
    } catch (e, stack) {
      debugPrint('계정 삭제 중 예상치 못한 오류: $e\n$stack');
      authError = '계정을 삭제하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.';
      return false;
    } finally {
      deleting = false;
      notifyListeners();
    }
  }

  /// 계정 삭제가 진행 중인 동안 true — 버튼 중복 탭을 막는다.
  bool deleting = false;
  int step = 1; // 1 계정연결 / 2 목표 / 3 신체 / 4 알림

  final Map<String, bool> terms = {
    '(필수) 서비스 이용약관': true,
    '(필수) 개인정보 처리방침': true,
    '(필수) 민감 건강정보 수집·이용 동의': false,
    '(선택) 마케팅 정보 수신': false,
  };

  bool get requiredTermsOk =>
      terms.entries.where((e) => e.key.contains('필수')).every((e) => e.value);

  void toggleTerm(String k) {
    terms[k] = !(terms[k] ?? false);
    notifyListeners();
    unawaited(_persistInBackground());
  }

  void toggleAllTerms() {
    final all = terms.values.every((v) => v);
    for (final k in terms.keys) {
      terms[k] = !all;
    }
    notifyListeners();
    unawaited(_persistInBackground());
  }

  UserProfile profile = UserProfile(userId: User.meId);

  String get goal => profile.goal;
  set goal(String v) => profile.goal = v;

  String get activity => profile.activity;
  set activity(String v) => profile.activity = v;

  String get gender => profile.gender;
  set gender(String v) => profile.gender = v;

  double get heightCm => profile.heightCm;
  set heightCm(double v) => profile.heightCm = v;

  double get weightKg => profile.weightKg;
  set weightKg(double v) => profile.weightKg = v;

  int get age => profile.age;
  set age(int v) => profile.age = v;

  double get goalWeight => profile.goalWeight;
  set goalWeight(double v) => profile.goalWeight = v;

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

  void toggleOnboardAlert(String label) {
    switch (label) {
      case '식단 미기록 알림':
        notificationSettings.mealReminder = !notificationSettings.mealReminder;
        break;
      case '물 마시기 알림':
        notificationSettings.waterReminder =
            !notificationSettings.waterReminder;
        break;
      case '운동 리마인드':
        notificationSettings.exerciseReminder =
            !notificationSettings.exerciseReminder;
        break;
      case '친구 응원 알림':
        notificationSettings.friendActivity =
            !notificationSettings.friendActivity;
        break;
    }
    notifyListeners();
  }

  double get bmi => profile.bmi;
  double get bmr => profile.bmr;
  int get dailyTarget => profile.dailyTarget;
  String get goalDelta => profile.goalDelta;

  // 홈 · 오늘 수치
  /// 고정된 오늘 날짜(_todayKey)의 기록 요약. 기록 탭에서 넘겨보는 날짜(month/day)와
  /// 무관해야 하므로 식단 · 운동 · 체중 모두 _todayKey로 걸러낸다.
  /// 물은 아직 날짜별 히스토리가 없어서 항상 "오늘" 목록 하나를 그대로 쓴다.
  DailyRegistry get todayRegistry => DailyRegistry(
    userId: _uid,
    dateKey: _todayKey,
    meals: todayMeals,
    waterEntries: _waterViewModel.waterEntries,
    exerciseLogs: _exerciseLogs
        .where((e) => e.userId == _uid && e.dateKey == _todayKey)
        .toList(),
    weightEntry: _todayWeightEntry,
  );

  /// 오늘 저장한 가장 최근 체중 기록 (없으면 null)
  WeightEntry? get _todayWeightEntry {
    for (final w in weightEntries.reversed) {
      if (w.userId == _uid && w.dateKey == _todayKey) return w;
    }
    return null;
  }

  int get intakeKcal => todayRegistry.totalIntakeKcal;
  int get remainKcal => dailyTarget - intakeKcal;
  double get intakeRatio =>
      dailyTarget > 0 ? (intakeKcal / dailyTarget).clamp(0.0, 1.0) : 0.0;

  // 영양소 — 오늘 기록한 식단의 AI 분석값을 그대로 더한 실제 합계.
  //
  // target(하루 권장치)은 성별 · 체중 등에 맞춘 개인화 목표가 아니라 일반
  // 성인 기준 고정값이다 — 개인 맞춤 목표는 별도 기능으로 남겨둔다.
  // 사진 분석 없이 저장한 식단(예: 분석 실패 후 대체값 450kcal로 저장)은
  // 영양소가 전부 0으로 잡혀서, 그만큼 실제보다 적게 보일 수 있다.
  static const _nutrientMeta =
      <(String name, String unit, double target, Color color)>[
        ('단백질', 'g', 100, AppColor.primary),
        ('탄수화물', 'g', 220, AppColor.warn),
        ('지방', 'g', 60, AppColor.warnDeep),
        ('식이섬유', 'g', 25, AppColor.teal),
        ('나트륨', 'mg', 2000, AppColor.alert),
        ('당류', 'g', 50, Color(0xFFF48FB1)),
        ('칼슘', 'mg', 700, Color(0xFF90A4EE)),
        ('철분', 'mg', 14, Color(0xFFB08BE0)),
      ];

  static double Function(MealLog) _nutrientPick(String name) => switch (name) {
    '단백질' => (m) => m.proteinG,
    '탄수화물' => (m) => m.carbG,
    '지방' => (m) => m.fatG,
    '식이섬유' => (m) => m.fiberG,
    '나트륨' => (m) => m.sodiumMg,
    '당류' => (m) => m.sugarG,
    '칼슘' => (m) => m.calciumMg,
    _ => (m) => m.ironMg,
  };

  double _sumMeals(double Function(MealLog) pick, [MealType? type]) =>
      todayMeals
          .where((m) => type == null || m.mealType == type)
          .fold(0.0, (a, m) => a + pick(m));

  /// 8종 영양소 오늘 합계 — 홈 카드(위 5개)와 영양소 상세 화면(전체)에서 같이 쓴다.
  List<NutrientStat> get todayNutrientStats => [
    for (final (name, unit, target, color) in _nutrientMeta)
      NutrientStat(
        name: name,
        unit: unit,
        target: target,
        color: color,
        value: _sumMeals(_nutrientPick(name)),
        breakfast: _sumMeals(_nutrientPick(name), MealType.breakfast),
        lunch: _sumMeals(_nutrientPick(name), MealType.lunch),
        dinner: _sumMeals(_nutrientPick(name), MealType.dinner),
        snack: _sumMeals(_nutrientPick(name), MealType.snack),
      ),
  ];

  double get todayProteinG => _sumMeals(_nutrientPick('단백질'));
  double get todayCarbG => _sumMeals(_nutrientPick('탄수화물'));
  double get todayFatG => _sumMeals(_nutrientPick('지방'));

  /// 3대 영양소가 각각 오늘 칼로리에서 차지하는 비율(%). 기록이 없으면 0.
  ({int proteinPct, int carbPct, int fatPct}) get macroRatio {
    final proteinKcal = todayProteinG * 4;
    final carbKcal = todayCarbG * 4;
    final fatKcal = todayFatG * 9;
    final total = proteinKcal + carbKcal + fatKcal;
    if (total <= 0) return (proteinPct: 0, carbPct: 0, fatPct: 0);
    return (
      proteinPct: (proteinKcal / total * 100).round(),
      carbPct: (carbKcal / total * 100).round(),
      fatPct: (fatKcal / total * 100).round(),
    );
  }

  // 미션 (자동 생성)
  //
  // 카테고리별 미션 풀에서 오늘 날짜 + 내 uid로 시드를 고정한 난수로
  // 3~5개를 뽑는다. 같은 uid·같은 날이면 항상 같은 조합이 나오고(새로고침
  // 해도 안 바뀜), 날짜가 바뀌면 다른 조합이 나온다. 한 카테고리에서는
  // 최대 2개까지만 뽑는다.
  //
  // "전날 실패 카테고리 우선"이나 "난이도는 최근 7일 평균의 90~110%" 같은
  // 더 정교한 규칙은 과거 날짜별 카테고리 성공/실패 기록이 따로 쌓여야
  // 가능한데, 지금은 그 데이터가 없어서 구현하지 않았다 — 목표치가 다른
  // 여러 난이도의 미션을 같은 카테고리 풀에 넣어 두는 정도로 대신한다.
  static final Map<String, List<_MissionTemplate>> _missionPool = {
    '식단': [
      _MissionTemplate(
        id: 'm_meal1',
        title: '한 끼 기록하기',
        target: 1,
        unit: '끼',
        exp: 10,
        axis: PlantAxis.nutri,
        route: 'capture',
        current: (s) => s.todayMeals.length.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_meal2',
        title: '두 끼 기록하기',
        target: 2,
        unit: '끼',
        exp: 15,
        axis: PlantAxis.nutri,
        route: 'capture',
        current: (s) => s.todayMeals.length.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_meal3',
        title: '세 끼 모두 기록하기',
        target: 3,
        unit: '끼',
        exp: 20,
        axis: PlantAxis.nutri,
        route: 'capture',
        current: (s) => s.todayMeals.length.toDouble(),
      ),
    ],
    '운동': [
      _MissionTemplate(
        id: 'm_exercise20',
        title: '20분 운동하기',
        target: 20,
        unit: '분',
        exp: 10,
        axis: PlantAxis.sun,
        route: 'exercise',
        current: (s) => s.todayExerciseMinutes.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_exercise30',
        title: '30분 운동하기',
        target: 30,
        unit: '분',
        exp: 15,
        axis: PlantAxis.sun,
        route: 'exercise',
        special: '변이 기회',
        current: (s) => s.todayExerciseMinutes.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_exercise45',
        title: '45분 운동하기',
        target: 45,
        unit: '분',
        exp: 20,
        axis: PlantAxis.sun,
        route: 'exercise',
        special: '변이 기회',
        current: (s) => s.todayExerciseMinutes.toDouble(),
      ),
    ],
    '생활': [
      _MissionTemplate(
        id: 'm_water1000',
        title: '물 1L 마시기',
        target: 1000,
        unit: 'ml',
        exp: 10,
        axis: PlantAxis.water,
        route: 'water',
        current: (s) => s.waterTotal.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_water1500',
        title: '물 1.5L 마시기',
        target: 1500,
        unit: 'ml',
        exp: 10,
        axis: PlantAxis.water,
        route: 'water',
        current: (s) => s.waterTotal.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_water2000',
        title: '물 2L 마시기',
        target: 2000,
        unit: 'ml',
        exp: 15,
        axis: PlantAxis.water,
        route: 'water',
        current: (s) => s.waterTotal.toDouble(),
      ),
    ],
    '꾸준함': [
      _MissionTemplate(
        id: 'm_streak3',
        title: '3일 연속 기록하기',
        target: 3,
        unit: '일',
        exp: 15,
        axis: PlantAxis.nutri,
        route: 'records',
        current: (s) => s.streakDays.toDouble(),
      ),
      _MissionTemplate(
        id: 'm_streak7',
        title: '7일 연속 기록하기',
        target: 7,
        unit: '일',
        exp: 25,
        axis: PlantAxis.nutri,
        route: 'records',
        current: (s) => s.streakDays.toDouble(),
      ),
    ],
  };

  List<Mission> get missions {
    final rng = Random(Object.hash(_uid, _todayKey));
    final categories = _missionPool.keys.toList()..shuffle(rng);
    final missionCount = 3 + rng.nextInt(3); // 3~5개

    final picked = <(String category, _MissionTemplate template)>[];
    for (final category in categories) {
      if (picked.length >= missionCount) break;
      final pool = List.of(_missionPool[category]!)..shuffle(rng);
      picked.add((category, pool.first));
    }
    // 미션이 5개면 카테고리(4개)를 다 쓰고도 하나가 남는다 — 그 하나는
    // 무작위 카테고리에서 이미 뽑은 것과 다른 난이도로 하나 더 뽑는다.
    while (picked.length < missionCount) {
      final category = categories[rng.nextInt(categories.length)];
      final usedIds = picked
          .where((p) => p.$1 == category)
          .map((p) => p.$2.id)
          .toSet();
      final remaining = _missionPool[category]!
          .where((t) => !usedIds.contains(t.id))
          .toList();
      if (remaining.isEmpty) break;
      picked.add((category, remaining[rng.nextInt(remaining.length)]));
    }

    return [
      for (final (category, template) in picked)
        Mission(
          id: template.id,
          category: category,
          title: template.title,
          current: template.current(this),
          target: template.target,
          unit: template.unit,
          exp: template.exp,
          axis: template.axis,
          route: template.route,
          special: template.special,
        ),
    ];
  }

  /// 미션 카테고리 필터 — 전체/식단/운동/생활/꾸준함
  String missionFilterTab = '전체';
  void setMissionFilterTab(String t) {
    missionFilterTab = t;
    notifyListeners();
  }

  /// "달성 처리" 버튼으로 수동 완료한 미션(제목 기준)
  final Set<String> _manualMissionDone = {};

  bool missionEffectivelyDone(Mission m) =>
      m.done || _manualMissionDone.contains(m.id);

  void completeMissionManually(Mission m) {
    if (missionEffectivelyDone(m)) return;
    _manualMissionDone.add(m.id);
    plant.exp += m.exp;
    notifyListeners();
    _schedulePlantSave();
  }

  int get missionDone => missions.where(missionEffectivelyDone).length;
  int get missionExp =>
      missions.where(missionEffectivelyDone).fold(0, (a, m) => a + m.exp);

  // 알림
  String notifTab = '전체';

  static const _unreadNotifIds = [
    '저녁 식단을 기록하지 않았어요',
    '식물이 물을 기다려요',
    '지현님이 응원을 보냈어요',
  ];
  final Set<String> readNotifIds = {};

  int get unread =>
      _unreadNotifIds.where((id) => !readNotifIds.contains(id)).length;

  void setNotifTab(String t) {
    notifTab = t;
    notifyListeners();
  }

  void markNotifRead(String id) {
    if (readNotifIds.add(id)) notifyListeners();
  }

  void readAll() {
    readNotifIds.addAll(_unreadNotifIds);
    notifyListeners();
  }

  // 식단 기록 · 부가 정보
  /// 식단 화면의 입력값은 이 Draft 하나가 소유합니다.
  final MealDraft mealDraft = MealDraft(
    proteinType: '돼지고기',
    sauce: '저당 소스',
    cookingMethod: '볶음',
    carbohydrateType: '백미',
  );

  Map<String, String> get extras => {
    'meat': mealDraft.proteinType ?? '',
    'sauce': mealDraft.sauce ?? '',
    'cook': mealDraft.cookingMethod ?? '',
    'carb': mealDraft.carbohydrateType ?? '',
    'meal': mealDraft.customMealTypeLabel ?? mealDraft.mealType.label,
    'context': mealDraft.customContextLabel ?? mealDraft.context.label,
  };

  final Map<String, String> customInputs = {
    'meat': '',
    'sauce': '',
    'cook': '',
    'carb': '',
    'meal': '',
    'context': '',
  };

  String get portion => mealDraft.portion.label;
  int get portionPct => mealDraft.portionPercent;
  int bowlIndex = 0;
  String get fill => mealDraft.fillLevel.label;
  List<String> get tags => mealDraft.tags;
  List<String> customTags = [];
  String tagInput = '';
  String get memo => mealDraft.memo;
  set memo(String value) => mealDraft.memo = value;

  /// 부가 정보 화면에서 "자주 쓰는 설정으로 저장" 했을 때의 스냅샷
  Map<String, String>? savedPreset;
  int? savedPresetBowlIndex;
  String? savedPresetPortion;
  String? savedPresetFill;

  void saveExtrasAsPreset() {
    savedPreset = Map.of(extras);
    savedPresetBowlIndex = bowlIndex;
    savedPresetPortion = portion;
    savedPresetFill = fill;
    notifyListeners();
  }

  double get portionRatio => mealDraft.portion == PortionSize.custom
      ? mealDraft.portionPercent / 100
      : (DietRules.portionRatio[portion] ?? 1.0);

  /// AI가 사진만 보고 추정한 기본 칼로리 (부가 정보 반영 전)
  int get baseKcal => _aiKcal ?? 450;

  final MealAnalysisService _mealAnalysisService = MealAnalysisService();
  final MealRecommendationService _mealRecommendationService =
      MealRecommendationService();
  final NotificationService _notificationService = NotificationService();

  /// 지금 알림 설정(notificationSettings)에 맞춰 기기 알림을 다시 예약한다.
  /// 토글을 끄면 해당 알림은 취소된다.
  Future<void> _applyNotificationSchedule() async {
    try {
      await _notificationService.init();
      await _notificationService.requestPermission();

      if (notificationSettings.mealReminder) {
        await _notificationService.scheduleMorning(
          notificationSettings.morningAlertTime,
        );
      } else {
        await _notificationService.cancelMorning();
      }

      if (notificationSettings.mealReminder ||
          notificationSettings.waterReminder) {
        await _notificationService.scheduleEvening(
          notificationSettings.eveningAlertTime,
        );
      } else {
        await _notificationService.cancelEvening();
      }

      await _notificationService.scheduleWeekly(
        notificationSettings.weeklyReportTime,
      );
    } catch (e, stack) {
      debugPrint('알림을 예약하지 못했어요: $e\n$stack');
    }
  }

  bool analyzingPhoto = false;
  String? photoAnalysisError;

  /// 방금 찍거나 고른 사진 원본 — 화면에 실제로 보여주는 용도.
  Uint8List? pickedPhotoBytes;
  String? aiMealName;
  int? _aiKcal;
  double? aiProteinG;
  double? aiCarbG;
  double? aiFatG;
  double? aiFiberG;
  double? aiSodiumMg;
  double? aiSugarG;
  double? aiCalciumMg;
  double? aiIronMg;
  bool needsPhotoReview = false;

  /// 사진을 고르고 즉시 AI 분석을 요청한다.
  Future<void> pickAndAnalyzeMealPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, imageQuality: 70);
    if (photo == null) return;

    analyzingPhoto = true;
    photoAnalysisError = null;
    notifyListeners();

    try {
      final bytes = await photo.readAsBytes();
      pickedPhotoBytes = bytes;
      final result = await _mealAnalysisService.analyze(
        imageBase64: base64Encode(bytes),
        mediaType: photo.mimeType ?? 'image/jpeg',
        bowl: currentBowl == null
            ? null
            : (name: currentBowl!.name, capacityMl: currentBowl!.capacityMl),
      );

      aiMealName = result.name;
      _aiKcal = result.kcal;
      aiProteinG = result.proteinG;
      aiCarbG = result.carbG;
      aiFatG = result.fatG;
      aiFiberG = result.fiberG;
      aiSodiumMg = result.sodiumMg;
      aiSugarG = result.sugarG;
      aiCalciumMg = result.calciumMg;
      aiIronMg = result.ironMg;
      needsPhotoReview = result.needsReview;
    } catch (e) {
      photoAnalysisError = '사진 분석에 실패했어요. 다시 시도해주세요.';
      debugPrint('사진 분석 실패: $e');
    } finally {
      analyzingPhoto = false;
      notifyListeners();
    }
  }

  /// 지금 선택된 그릇 — 등록한 그릇이 하나도 없으면 null (그릇 없이도 기록할 수 있다).
  Bowl? get currentBowl =>
      bowls.isEmpty ? null : bowls[bowlIndex.clamp(0, bowls.length - 1)];

  /// 부가 정보 반영 보정 칼로리
  int get adjustedKcal {
    var v =
        baseKcal *
        portionRatio *
        (DietRules.fillRatio[fill] ?? 1.0) *
        (currentBowl?.capacityFactor ?? 1.0);
    v *= DietRules.cookFactor[extras['cook']] ?? 1.0;
    v *= DietRules.sauceFactor[extras['sauce']] ?? 1.0;
    v *= DietRules.proteinFactor[extras['meat']] ?? 1.0;
    return v.round();
  }

  void setExtra(String key, String value) {
    switch (key) {
      case 'meat':
        mealDraft.proteinType = value;
        break;
      case 'sauce':
        mealDraft.sauce = value;
        break;
      case 'cook':
        mealDraft.cookingMethod = value;
        break;
      case 'carb':
        mealDraft.carbohydrateType = value;
        break;
      case 'meal':
        final type = _mealTypeFromLabel(value);
        mealDraft.mealType = type;
        mealDraft.customMealTypeLabel = type.label == value ? null : value;
        break;
      case 'context':
        final context = _mealContextFromLabel(value);
        mealDraft.context = context;
        mealDraft.customContextLabel = context.label == value ? null : value;
        break;
    }
    notifyListeners();
  }

  void setCustomInput(String key, String value) {
    customInputs[key] = value;
    notifyListeners();
  }

  /// 직접 입력값 적용 — 칩으로 추가되고 즉시 선택됩니다.
  bool applyCustom(String key) {
    final v = (customInputs[key] ?? '').trim();
    if (v.isEmpty) return false;
    customInputs[key] = '';
    setExtra(key, v);
    return true;
  }

  void setPortion(String p) {
    mealDraft.portion = _portionFromLabel(p);
    mealDraft.portionPercent =
        {'전체': 100, '반절': 50, '1/3': 33}[p] ?? mealDraft.portionPercent;
    notifyListeners();
  }

  void setPortionPct(int pct) {
    mealDraft.portionPercent = pct.clamp(1, 300);
    mealDraft.portion = pct == 100
        ? PortionSize.full
        : pct == 50
        ? PortionSize.half
        : pct == 33
        ? PortionSize.third
        : PortionSize.custom;
    notifyListeners();
  }

  void toggleTag(String t) {
    tags.contains(t) ? tags.remove(t) : tags.add(t);
    notifyListeners();
  }

  bool addCustomTag() {
    final raw = tagInput.trim();
    if (raw.isEmpty) return false;
    final t = raw.startsWith('#') ? raw : '#$raw';
    if (tags.contains(t)) return false;
    if (!customTags.contains(t)) customTags.add(t);
    tags.add(t);
    tagInput = '';
    notifyListeners();
    return true;
  }

  // 기록 탭
  late int year = today.year;
  late int month = today.month;
  late int day = today.day;

  Map<String, bool> get logged => {
    '식단': meals.isNotEmpty,
    '운동': _exerciseLogs.any(
      (e) => e.userId == _uid && e.dateKey == _selectedKey,
    ),
    '체중': _viewingToday && weightEntries.isNotEmpty,
    '물': _viewingToday && _waterViewModel.waterEntries.isNotEmpty,
  };

  /// 이전 달로 — 과거는 제한 없이 넘겨볼 수 있다.
  void prevMonth() {
    final first = DateTime(year, month - 1, 1);
    year = first.year;
    month = first.month;
    day = day.clamp(1, DateTime(year, month + 1, 0).day);
    notifyListeners();
    _loadViewedMonth();
  }

  /// 오늘이 속한 달보다 뒤로는 갈 수 없다 (미래의 기록은 만들 수 없다).
  bool get canGoNextMonth => year * 12 + month < todayYear * 12 + todayMonth;

  bool nextMonth() {
    if (!canGoNextMonth) return false;
    final first = DateTime(year, month + 1, 1);
    year = first.year;
    month = first.month;
    day = day.clamp(1, DateTime(year, month + 1, 0).day);
    if (DateTime(year, month, day).isAfter(today)) day = todayDay;
    notifyListeners();
    _loadViewedMonth();
    return true;
  }

  /// 보고 있는 달의 [d]일이 오늘보다 뒤인가
  bool isFutureDay(int d) => DateTime(year, month, d).isAfter(today);

  void selectDay(int d) {
    if (isFutureDay(d)) return;
    day = d;
    notifyListeners();
  }

  /// [date]에 남긴 기록(식단 · 운동 · 체중, 그리고 오늘의 물)이 하나라도 있는가.
  bool hasRecordOn(DateTime date) {
    final key = dateKeyOf(date);
    return _mealLogs.any((m) => m.dateKey == key) ||
        _exerciseLogs.any((e) => e.dateKey == key) ||
        weightEntries.any((w) => w.dateKey == key) ||
        _waterViewModel.waterEntries.any((w) => w.dateKey == key);
  }

  /// 연속 기록 일수 — 오늘부터 거꾸로 기록이 이어진 날 수.
  /// 오늘 아직 기록하지 않았어도 어제까지 이어진 연속은 끊기지 않은 것으로 센다.
  int get streakDays {
    var d = hasRecordOn(today)
        ? today
        : DateTime(today.year, today.month, today.day - 1);
    var n = 0;
    while (n < 3650 && hasRecordOn(d)) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  /// 전체 식단 기록 저장소. bowlId로 Bowl을, dateKey로 날짜를 참조한다.
  late final List<MealLog> _mealLogs = [
    MealLog(
      id: 'meal_seed_breakfast',
      userId: User.meId,
      mealType: MealType.breakfast,
      name: '오트밀 · 바나나',
      meta: '집 밥그릇 · 가득 · 집밥',
      kcal: 320,
      dateKey: _todayKey,
      bowlId: 'bowl_home',
    ),
    MealLog(
      id: 'meal_seed_lunch',
      userId: User.meId,
      mealType: MealType.lunch,
      name: aiMealName ?? '음식 (추정)',
      meta: '회사 도시락 · 가득 · 도시락',
      kcal: 450,
      dateKey: _todayKey,
      bowlId: 'bowl_lunchbox',
      needsReview: needsPhotoReview,
    ),
    MealLog(
      id: 'meal_seed_dinner',
      userId: User.meId,
      mealType: MealType.dinner,
      name: '닭가슴살 샐러드',
      meta: '샐러드 볼 · 반 · 집밥',
      kcal: 480,
      dateKey: _todayKey,
      bowlId: 'bowl_salad',
    ),
    MealLog(
      id: 'meal_seed_snack',
      userId: User.meId,
      mealType: MealType.snack,
      name: '그릭요거트',
      meta: '컵 · 가득 · 외식',
      kcal: 200,
      dateKey: _todayKey,
    ),
  ];

  /// 기록 탭에서 지금 보고 있는 날짜(month/day)의 식단.
  List<MealLog> get meals => _mealLogs
      .where((m) => m.userId == _uid && m.dateKey == _selectedKey)
      .toList();

  /// 지금 보고 있는 날짜의 총 섭취 칼로리.
  int get selectedDayKcal => meals.fold(0, (a, m) => a + m.kcal);

  /// 홈 화면 "오늘 섭취" 계산에 쓰는, 고정된 오늘 날짜의 식단.
  List<MealLog> get todayMeals => _mealLogs
      .where((m) => m.userId == _uid && m.dateKey == _todayKey)
      .toList();

  /// 촬영/기록 화면에서 저장한 값으로 실제 MealLog를 만들어 저장한다.
  void logMeal() {
    final bowl = currentBowl;
    final log = MealLog(
      id: 'meal_${DateTime.now().microsecondsSinceEpoch}',
      userId: _uid,
      mealType: _mealTypeFromLabel(extras['meal'] ?? '점심'),
      name: aiMealName ?? '식사 (직접 기록)',
      meta: bowl == null
          ? '기록 · $fill · ${extras['context']}'
          : '${bowl.name} · $fill · ${extras['context']}',
      kcal: adjustedKcal,
      dateKey: _todayKey,
      bowlId: bowl?.id,
      sauce: extras['sauce'] ?? '',
      needsReview: true,
      proteinG: aiProteinG ?? 0,
      carbG: aiCarbG ?? 0,
      fatG: aiFatG ?? 0,
      fiberG: aiFiberG ?? 0,
      sodiumMg: aiSodiumMg ?? 0,
      sugarG: aiSugarG ?? 0,
      calciumMg: aiCalciumMg ?? 0,
      ironMg: aiIronMg ?? 0,
    );
    _mealLogs.add(log);
    // 이번 분석 결과는 이 기록에 다 썼다 — 다음 끼니를 새 사진 없이 저장하면
    // 방금 분석값을 재사용하지 않고 0(분석 안 함)으로 시작하게 비워준다.
    pickedPhotoBytes = null;
    aiMealName = null;
    _aiKcal = null;
    aiProteinG = null;
    aiCarbG = null;
    aiFatG = null;
    aiFiberG = null;
    aiSodiumMg = null;
    aiSugarG = null;
    aiCalciumMg = null;
    aiIronMg = null;
    needsPhotoReview = false;
    notifyListeners();
    _saveRecord(_mealRepo, log, '식단 기록');
    _postActivity('${log.mealType.label} 식단을 기록했어요');
    _reportChallengeProgress(ChallengeType.mealRecord, todayMeals.length);
    _reportChallengeProgress(ChallengeType.protein, todayProteinG);
  }

  /// 상세 화면에서 보여줄 식단 — id로 참조한다.
  String? detailMealId;

  MealLog? get detailMeal {
    for (final m in _mealLogs) {
      if (m.id == detailMealId) return m;
    }
    return null;
  }

  void openMeal(MealLog m) {
    detailMealId = m.id;
    go('mealDetail');
  }

  // 운동
  /// 운동 화면의 입력 상태입니다. 저장 전까지만 유지되는 Draft 모델입니다.
  final ExerciseDraft exerciseDraft = ExerciseDraft();

  String get exType => exerciseDraft.type;
  set exType(String value) => exerciseDraft.type = value;

  int get exMinutes => exerciseDraft.minutes;
  set exMinutes(int value) => exerciseDraft.minutes = value;

  String get exIntensity => exerciseDraft.intensity.label;
  set exIntensity(String value) => exerciseDraft.intensity = switch (value) {
    '낮음' => ExerciseIntensity.low,
    '높음' => ExerciseIntensity.high,
    _ => ExerciseIntensity.moderate,
  };

  bool get exTypeKnown =>
      DietRules.exerciseTypeFactor.containsKey(exType.trim());

  int get exKcal {
    final f = DietRules.exerciseTypeFactor[exType.trim()] ?? 1.0;
    final i = DietRules.exerciseIntensityFactor[exIntensity] ?? 8;
    return (exMinutes * i * f).round();
  }

  /// 실제로 저장한 운동 기록 저장소.
  final List<ExerciseLog> _exerciseLogs = [];

  /// 홈 · 미션에서 쓰는, 고정된 오늘 날짜의 운동 시간 합계.
  int get todayExerciseMinutes => _exerciseLogs
      .where((e) => e.userId == _uid && e.dateKey == _todayKey)
      .fold(0, (a, e) => a + e.minutes);

  /// 지금 입력값으로 실제 운동 기록을 저장한다.
  void logExercise() {
    final log = ExerciseLog(
      id: 'ex_${DateTime.now().microsecondsSinceEpoch}',
      userId: _uid,
      type: exType,
      minutes: exMinutes,
      intensity: exerciseDraft.intensity,
      kcal: exKcal,
      dateKey: _selectedKey,
      time: _clockTime,
    );
    _exerciseLogs.add(log);
    notifyListeners();
    _saveRecord(_exerciseRepo, log, '운동 기록');
    _postActivity('$exType $exMinutes분 운동했어요');
    _reportChallengeProgress(ChallengeType.exercise, todayExerciseMinutes);
  }

  List<Routine> routines = [
    Routine(
      id: 'routine_morning_run',
      userId: User.meId,
      name: '아침 러닝',
      type: '달리기',
      minutes: 30,
      intensity: ExerciseIntensity.moderate,
      icon: '🏃',
      used: 12,
      weeklyUsed: 3,
    ),
    Routine(
      id: 'routine_home_workout',
      userId: User.meId,
      name: '홈트 세트',
      type: '근력',
      minutes: 40,
      intensity: ExerciseIntensity.high,
      icon: '🏋️',
      used: 8,
      weeklyUsed: 2,
    ),
    Routine(
      id: 'routine_evening_walk',
      userId: User.meId,
      name: '저녁 산책',
      type: '걷기',
      minutes: 25,
      intensity: ExerciseIntensity.low,
      icon: '🚶',
      used: 5,
      weeklyUsed: 1,
    ),
  ];

  static const _routineIcons = {
    '달리기': '🏃',
    '걷기': '🚶',
    '자전거': '🚴',
    '근력': '🏋️',
    '요가': '🧘',
    '수영': '🏊',
    '등산': '🥾',
  };

  /// "내 루틴" 카드에서 추가/삭제 컨트롤(✕)을 보여줄지 여부
  bool routineEditMode = false;

  void toggleRoutineEditMode() {
    routineEditMode = !routineEditMode;
    notifyListeners();
  }

  void loadRoutine(Routine r) {
    exType = r.type;
    exMinutes = r.minutes;
    exerciseDraft.intensity = r.intensity;
    notifyListeners();
  }

  void saveCurrentAsRoutine() {
    final routine = Routine(
      id: 'routine_${DateTime.now().microsecondsSinceEpoch}',
      userId: _uid,
      name: '$exType $exMinutes분',
      type: exType,
      minutes: exMinutes,
      intensity: exerciseDraft.intensity,
      icon: _routineIcons[exType.trim()] ?? '💪',
    );
    routines.add(routine);
    notifyListeners();
    _saveRecord(_routineRepo, routine, '운동 루틴');
  }

  void removeRoutine(Routine r) {
    routines.remove(r);
    notifyListeners();
    _deleteRecord(_routineRepo, r.id, '운동 루틴');
  }

  // 체중
  double weightInput = 56.7;
  final Map<String, bool> bodyShots = {'FRONT': true, 'SIDE': false};

  bool get bodyShotsOk =>
      bodyShots['FRONT'] == true && bodyShots['SIDE'] == true;

  void toggleBodyShot(String k) {
    bodyShots[k] = !(bodyShots[k] ?? false);
    notifyListeners();
  }

  /// 실제로 저장한 체중 기록 저장소 — 최근 값이 "어제보다" 비교 기준이 된다.
  late List<WeightEntry> weightEntries = [
    WeightEntry(
      id: 'weight_seed',
      userId: User.meId,
      kg: 56.9,
      dateKey: dateKeyOf(DateTime(today.year, today.month, today.day - 1)),
      time: '어제',
    ),
  ];

  /// 기록 탭 요약 카드에 쓰는, 가장 최근에 저장한 체중.
  double get latestWeightKg =>
      weightEntries.isEmpty ? profile.weightKg : weightEntries.last.kg;

  String get weightDiff {
    final last = weightEntries.isEmpty
        ? profile.weightKg
        : weightEntries.last.kg;
    return '${(weightInput - last).toStringAsFixed(1)}kg';
  }

  /// 눈바디 2장을 확인한 뒤 지금 입력값으로 실제 체중 기록을 저장한다.
  void logWeight() {
    final entry = WeightEntry(
      id: 'weight_${DateTime.now().microsecondsSinceEpoch}',
      userId: _uid,
      kg: weightInput,
      dateKey: _todayKey,
      time: _clockTime,
    );
    weightEntries.add(entry);
    profile.weightKg = weightInput;
    notifyListeners();
    _saveRecord(_weightRepo, entry, '체중 기록');
    unawaited(_persistInBackground());
  }

  // 물
  bool waterSheet = false;

  String get _uid => account?.uid ?? User.meId;

  String get _clockTime {
    final n = _now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  int get waterTotal => _waterViewModel.waterTotal;
  int get waterLeft => _waterViewModel.waterLeft;
  int get waterPct => _waterViewModel.waterPct;

  /// WaterViewModel.addWater()는 화면 전용이라 다른 기능(활동 피드 ·
  /// 챌린지 진행도)을 모른다 — 물을 기록한 뒤 이 메서드도 함께 불러서
  /// 그 연결을 이어준다.
  void onWaterAdded(int ml) {
    _postActivity('물 ${AppStateFormat.comma(ml)}ml을 기록했어요');
    _reportChallengeProgress(ChallengeType.water, _waterViewModel.waterTotal);
  }

  // 계정에 저장되는 기록들 (체중 · 운동 · 식단 · 그릇 · 루틴 · 식물)

  void _saveRecord<T>(RecordRepository<T> repo, T entry, String what) {
    final a = account;
    if (a == null) return;
    unawaited(
      repo.save(a.uid, entry).catchError((Object e, StackTrace stack) {
        debugPrint('$what 저장 실패: $e\n$stack');
        _notice = '$what 저장에 실패했어요. 네트워크를 확인해 주세요.';
        notifyListeners();
      }),
    );
  }

  void _deleteRecord<T>(RecordRepository<T> repo, String id, String what) {
    final a = account;
    if (a == null) return;
    unawaited(
      repo.delete(a.uid, id).catchError((Object e, StackTrace stack) {
        debugPrint('$what 삭제 실패: $e\n$stack');
        _notice = '$what 삭제에 실패했어요. 네트워크를 확인해 주세요.';
        notifyListeners();
      }),
    );
  }

  Timer? _plantSaveTimer;
  static const _plantSaveDelay = Duration(milliseconds: 500);

  /// 식물을 불러오지 못했을 때는 저장도 멈춘다 (덮어쓰기 방지).
  bool _plantSyncOk = true;

  void _schedulePlantSave() {
    if (account == null || !_plantSyncOk) return;
    _plantSaveTimer?.cancel();
    _plantSaveTimer = Timer(_plantSaveDelay, () {
      _plantSaveTimer = null;
      _saveRecord(_plantRepo, plant, '식물 상태');
    });
  }

  final Set<String> _loadedMonths = {};

  Future<void> _loadAccountData(String uid) async {
    final prev = DateTime(today.year, today.month - 1, 1);
    await Future.wait([
      _waterViewModel.loadForUid(uid),
      _loadWeight(uid),
      _loadTemplates(uid),
      _loadPlant(uid),
      _loadDex(uid),
      _loadFriendData(uid),
      _loadChallenges(uid),
      _loadMonth(today.year, today.month),
      _loadMonth(prev.year, prev.month), // 연속 기록을 세려면 지난달 끝도 필요하다
    ]);
  }

  /// 저장된 수집 상태를 불러온다. 처음 가입한 계정(저장된 게 없음)은
  /// 전부 미획득 상태로 시작하고, 그 상태를 그대로 저장해 다음부터는
  /// 다시 만들지 않는다.
  Future<void> _loadDex(String uid) async {
    try {
      final saved = await _dexRepo.loadAll(uid);
      if (saved.isNotEmpty) {
        dexEntries = saved;
        return;
      }
      dexEntries = [
        for (final sp in PlantSpecies.catalog)
          DexEntry(userId: uid, speciesId: sp.id),
      ];
      for (final e in dexEntries) {
        unawaited(_dexRepo.save(uid, e));
      }
    } catch (e, stack) {
      debugPrint('도감 정보를 불러오지 못했어요: $e\n$stack');
      dexEntries = [
        for (final sp in PlantSpecies.catalog)
          DexEntry(userId: uid, speciesId: sp.id),
      ];
      _notice = '도감 정보를 불러오지 못했어요.';
    }
  }

  Future<void> _loadWeight(String uid) async {
    try {
      weightEntries = await _weightRepo.loadAll(uid);
    } catch (e, stack) {
      debugPrint('체중 기록을 불러오지 못했어요: $e\n$stack');
      weightEntries = [];
      _notice = '체중 기록을 불러오지 못했어요.';
    }
    weightInput = weightEntries.isNotEmpty
        ? weightEntries.last.kg
        : profile.weightKg;
  }

  Future<void> _loadTemplates(String uid) async {
    try {
      bowls = await _bowlRepo.loadAll(uid);
      routines = await _routineRepo.loadAll(uid);
    } catch (e, stack) {
      debugPrint('그릇 · 루틴을 불러오지 못했어요: $e\n$stack');
      bowls = [];
      routines = [];
      _notice = '그릇과 운동 루틴을 불러오지 못했어요.';
    }
    bowlIndex = 0;
  }

  Future<void> _loadPlant(String uid) async {
    _plantSyncOk = true;
    try {
      final saved = await _plantRepo.loadAll(uid);
      plant = saved.isEmpty ? Plant.starter(uid) : saved.first;
    } catch (e, stack) {
      debugPrint('식물 정보를 불러오지 못했어요: $e\n$stack');
      plant = Plant.starter(uid);
      _plantSyncOk = false;
      _notice = '식물 정보를 불러오지 못했어요. 다시 로그인하기 전까지 식물 변화는 저장되지 않아요.';
    }
  }

  Future<void> _loadMonth(int year, int month) async {
    final a = account;
    if (a == null || _isDemo) return;
    final key = '$year-${month.toString().padLeft(2, '0')}';
    if (_loadedMonths.contains(key)) return;
    try {
      final meals = await _mealRepo.loadRange(a.uid, '$key-01', '$key-31');
      final workouts = await _exerciseRepo.loadRange(
        a.uid,
        '$key-01',
        '$key-31',
      );
      final haveMeals = {for (final m in _mealLogs) m.id};
      final haveWorkouts = {for (final e in _exerciseLogs) e.id};
      _mealLogs.addAll(meals.where((m) => !haveMeals.contains(m.id)));
      _exerciseLogs.addAll(workouts.where((e) => !haveWorkouts.contains(e.id)));
      _loadedMonths.add(key);
    } catch (e, stack) {
      debugPrint('$key 기록을 불러오지 못했어요: $e\n$stack');
      _notice = '$year년 $month월 기록을 불러오지 못했어요.';
    }
  }

  void _loadViewedMonth() =>
      unawaited(_loadMonth(year, month).then((_) => notifyListeners()));

  Future<void> _deleteAllUserData(String uid) async {
    const limit = Duration(seconds: 30);
    await Future.wait<void>([
      _waterViewModel.deleteAll(uid),
      _weightRepo.deleteAll(uid),
      _exerciseRepo.deleteAll(uid),
      _mealRepo.deleteAll(uid),
      _bowlRepo.deleteAll(uid),
      _routineRepo.deleteAll(uid),
      _plantRepo.deleteAll(uid),
      _dexRepo.deleteAll(uid),
    ]).timeout(limit);
    await _profiles.delete(uid).timeout(limit);
  }

  // 그릇
  bool bowlSheet = false;
  int? bowlEditing; // null = 편집 중 아님, -1 = 신규 추가

  List<Bowl> bowls = [
    Bowl(
      id: 'bowl_lunchbox',
      userId: User.meId,
      name: '회사 도시락',
      capacityMl: 500,
      portion: '1인분',
      material: '플라스틱',
      shape: '도시락',
      memo: '항상 가득 채워 먹음',
      isDefault: true,
      icon: '🍱',
    ),
    Bowl(
      id: 'bowl_home',
      userId: User.meId,
      name: '집 밥그릇',
      capacityMl: 300,
      portion: '소',
      material: '도자기',
      shape: '원형',
      memo: '반만 채움',
      icon: '🍚',
    ),
    Bowl(
      id: 'bowl_salad',
      userId: User.meId,
      name: '샐러드 볼',
      capacityMl: 900,
      portion: '대',
      material: '유리',
      shape: '원형',
      memo: '드레싱 따로',
      icon: '🥗',
    ),
    Bowl(
      id: 'bowl_tumbler',
      userId: User.meId,
      name: '텀블러',
      capacityMl: 450,
      portion: '중',
      material: '스테인리스',
      shape: '컵',
      memo: '물 기록용',
      icon: '☕',
    ),
  ];

  Bowl draftBowl = Bowl(
    id: '',
    userId: User.meId,
    name: '',
    capacityMl: 400,
    portion: '1인분',
    material: '플라스틱',
    shape: '원형',
  );

  void startAddBowl() {
    draftBowl = Bowl(
      id: '',
      userId: User.meId,
      name: '',
      capacityMl: 400,
      portion: '1인분',
      material: '플라스틱',
      shape: '원형',
    );
    bowlEditing = -1;
    notifyListeners();
  }

  void startEditBowl(int i) {
    final b = bowls[i];
    draftBowl = Bowl(
      id: b.id,
      userId: b.userId,
      name: b.name,
      capacityMl: b.capacityMl,
      portion: b.portion,
      material: b.material,
      shape: b.shape,
      memo: b.memo,
      isDefault: b.isDefault,
      icon: b.icon,
    );
    bowlEditing = i;
    notifyListeners();
  }

  void cancelBowlEdit() {
    bowlEditing = null;
    notifyListeners();
  }

  bool saveBowl() {
    if (draftBowl.name.trim().isEmpty) return false;
    final changed = <Bowl>[];
    if (draftBowl.isDefault) {
      for (final b in bowls) {
        if (b.isDefault) {
          b.isDefault = false;
          changed.add(b);
        }
      }
    }
    if (bowlEditing == -1) {
      if (bowls.length >= DietRules.maxBowls) return false;
      final created = Bowl(
        id: 'bowl_${DateTime.now().microsecondsSinceEpoch}',
        userId: _uid,
        name: draftBowl.name,
        capacityMl: draftBowl.capacityMl,
        portion: draftBowl.portion,
        material: draftBowl.material,
        shape: draftBowl.shape,
        memo: draftBowl.memo,
        isDefault: draftBowl.isDefault,
        icon: draftBowl.icon,
      );
      bowls.add(created);
      changed.add(created);
    } else if (bowlEditing != null) {
      bowls[bowlEditing!] = draftBowl;
      changed.add(draftBowl);
    }
    bowlEditing = null;
    notifyListeners();
    for (final b in {for (final b in changed) b.id: b}.values) {
      _saveRecord(_bowlRepo, b, '그릇');
    }
    return true;
  }

  void removeBowl(int i) {
    final removed = bowls.removeAt(i);
    if (bowlIndex >= bowls.length) bowlIndex = 0;
    bowlEditing = null;
    notifyListeners();
    _deleteRecord(_bowlRepo, removed.id, '그릇');
  }

  void selectBowl(int i) {
    bowlIndex = i;
    mealDraft.bowlId = bowls[i].id;
    notifyListeners();
  }

  void setFill(String f) {
    mealDraft.fillLevel = switch (f) {
      '반' => BowlFillLevel.half,
      '1/3' => BowlFillLevel.third,
      _ => BowlFillLevel.full,
    };
    notifyListeners();
  }

  static MealType _mealTypeFromLabel(String value) => switch (value) {
    '아침' => MealType.breakfast,
    '저녁' => MealType.dinner,
    '간식' => MealType.snack,
    _ => MealType.lunch,
  };

  static MealContext _mealContextFromLabel(String value) => switch (value) {
    '집밥' => MealContext.home,
    '외식' => MealContext.diningOut,
    '배달' => MealContext.delivery,
    '도시락' => MealContext.lunchbox,
    _ => MealContext.other,
  };

  static PortionSize _portionFromLabel(String value) => switch (value) {
    '반절' => PortionSize.half,
    '1/3' => PortionSize.third,
    '직접' => PortionSize.custom,
    _ => PortionSize.full,
  };

  // 식물
  //
  // "내 식물"의 성장 상태(경험치 · 3축 점수 · 돌보기 횟수 등)와 그 상태로부터
  // 계산되는 값(레벨 · 품종 · 시듦 여부 …)은 전부 Plant 모델이 담당한다.
  // AppState는 Plant 인스턴스 하나를 들고 있다가, 화면에서 그대로 쓸 수
  // 있도록 이름을 맞춘 getter로 흘려보낸다(forward)만 한다.
  Plant plant = Plant(
    userId: User.meId,
    exp: 240,
    axisScore: {PlantAxis.water: 82, PlantAxis.sun: 45, PlantAxis.nutri: 68},
    cares: {'물 주기': 3, '햇빛 받기': 2, '영양 주기': 2},
    missedDays: 2,
    inventory: {'물방울': 6, '희귀 씨앗': 2, '전설 씨앗': 0, '정원 장식': 1},
    giftTickets: 1,
  );

  int get plantExp => plant.exp;
  Map<PlantAxis, int> get axisScore => plant.axisScore;
  Map<String, int> get cares => plant.cares;
  int get missedDays => plant.missedDays;
  bool get revived => plant.revived;
  List<String> get wateredFriends => plant.wateredFriendIds;
  Map<String, int> get inventory => plant.inventory;
  int get giftTickets => plant.giftTickets;

  int get plantLevel => plant.level;
  bool get wilting => plant.wilting;
  int get graceLeft => plant.graceLeft;
  int get axisSpread => plant.axisSpread;
  bool get balanced => plant.balanced;
  PlantAxis get weakestAxis => plant.weakestAxis;
  ({String emoji, String name, int lv, double size}) get plantStage =>
      plant.stage;
  String get plantExpLeft => plant.expLeft;
  String get plantMood => plant.mood;
  String get plantMessage => plant.message;
  String get balanceHint => plant.balanceHint;

  void care(String name) {
    plant.care(name);
    notifyListeners();
    _schedulePlantSave();
  }

  void revive() {
    plant.revive();
    notifyListeners();
    _schedulePlantSave();
  }

  /// friendUserId(친구의 User.id)의 정원에 물을 준다.
  void waterFriend(String friendUserId) {
    if (!plant.waterFriend(friendUserId)) return;
    notifyListeners();
    _schedulePlantSave();
  }

  /// 보관함 아이템 사용 — 즉시 1개 소모하고 효과를 바로 반영해요.
  void useInventoryItem(String key) {
    plant.useInventoryItem(key);
    notifyListeners();
    _schedulePlantSave();
  }

  void sendGiftFlower() {
    if (!plant.sendGiftFlower()) return;
    notifyListeners();
    _schedulePlantSave();
  }

  // 도감
  //
  // 카탈로그(어떤 종이 있는지)는 PlantSpecies.catalog가 담당하고, "내가 그
  // 종을 얼마나 모았는지"는 계정별로 저장되는 dexEntries가 담당한다.
  // 여기서는 둘을 합친 DexCard 목록만 다룬다.
  String dexTab = '전체';
  int dexPick = 0;

  static const _dexDemoOwned = {
    'sp_tulip',
    'sp_sunflower',
    'sp_rose',
    'sp_daisy',
    'sp_monstera',
    'sp_cactus',
    'sp_sprout',
    'sp_cherry_blossom',
  };
  static const _dexDemoProgress = <String, int>{
    'sp_rubber_tree': 62,
    'sp_clover': 75,
    'sp_rice': 40,
    'sp_lotus': 55,
    'sp_moss_fern': 30,
    'sp_conifer': 45,
    'sp_bamboo': 20,
    'sp_mutant_tulip': 12,
    'sp_golden_rose': 33,
    'sp_rare_hibiscus': 8,
  };

  /// 데모(Mock) 계정에서 보여줄 예시 수집 상태. 실제 계정은 로그인 후
  /// _loadDex에서 저장된 값(없으면 전부 미획득)으로 덮어쓴다.
  List<DexEntry> dexEntries = [
    for (final sp in PlantSpecies.catalog)
      DexEntry(
        userId: User.meId,
        speciesId: sp.id,
        owned: _dexDemoOwned.contains(sp.id),
        progress: _dexDemoOwned.contains(sp.id)
            ? 100
            : (_dexDemoProgress[sp.id] ?? 0),
      ),
  ];

  /// 모두가 공유하는 도감 베이스 카탈로그.
  static List<PlantSpecies> get dexBase => PlantSpecies.catalog;

  DexEntry _dexEntryFor(String speciesId) => dexEntries.firstWhere(
    (e) => e.speciesId == speciesId,
    orElse: () => DexEntry(userId: _uid, speciesId: speciesId),
  );

  List<DexCard> get _dexCards => [
    for (final sp in PlantSpecies.catalog) DexCard(sp, _dexEntryFor(sp.id)),
  ];

  int get dexTotal => _dexCards.fold(0, (a, b) => a + b.variants.length);
  int get dexOwned => _dexCards.fold(0, (a, b) => a + b.ownedVariants);
  int get dexPct => ((dexOwned / dexTotal) * 100).round();

  ({int own, int all}) dexTierCount(String tier) {
    final g = _dexCards.where((c) => c.tier == tier);
    return (
      own: g.fold(0, (a, b) => a + b.ownedVariants),
      all: g.fold(0, (a, b) => a + b.variants.length),
    );
  }

  List<DexCard> get dexFiltered {
    final cards = _dexCards;
    return dexTab == '전체'
        ? cards
        : cards.where((c) => c.tier == dexTab).toList();
  }

  DexCard get dexSelected {
    final cards = _dexCards;
    return cards[dexPick.clamp(0, cards.length - 1)];
  }

  void setDexTab(String t) {
    dexTab = t;
    notifyListeners();
  }

  void setDexPick(DexCard c) {
    dexPick = _dexCards.indexOf(c);
    notifyListeners();
  }

  // 식단 추천
  List<String> needs = ['식이섬유', '칼슘'];
  String recMeal = '저녁';
  List<String> recPrefs = ['채식 위주'];
  int recMaxKcal = 600;
  String recSort = '추천순';
  int recSeed = 0;

  static const needOptions = [
    '탄수화물',
    '단백질',
    '지방',
    '식이섬유',
    '칼슘',
    '철분',
    '비타민D',
    '오메가3',
  ];

  static const _pool = <MealSuggestion>[
    MealSuggestion(
      name: '현미밥 · 두부구이 · 브로콜리',
      emoji: '🍚',
      kcal: 520,
      meta: '탄수화물 68g · 식이섬유 9g · 칼슘 240mg · 단백질 26g',
      covers: ['탄수화물', '식이섬유', '칼슘', '단백질'],
      prefs: ['채식 위주', '저나트륨'],
      meals: ['점심', '저녁'],
      tag: '집밥',
      why: '식이섬유와 칼슘을 한 끼로 함께 채울 수 있어요.',
    ),
    MealSuggestion(
      name: '연어 샐러드 · 통밀빵',
      emoji: '🥗',
      kcal: 480,
      meta: '오메가3 1.8g · 지방 22g · 식이섬유 7g · 단백질 30g',
      covers: ['오메가3', '지방', '식이섬유', '단백질'],
      prefs: ['고단백', '간편식'],
      meals: ['점심', '저녁'],
      tag: '15분',
      why: '조리 없이 준비할 수 있고 좋은 지방과 단백질이 넉넉해요.',
    ),
    MealSuggestion(
      name: '병아리콩 커리 · 현미',
      emoji: '🍛',
      kcal: 560,
      meta: '탄수화물 74g · 식이섬유 12g · 철분 5mg',
      covers: ['탄수화물', '식이섬유', '철분'],
      prefs: ['채식 위주'],
      meals: ['점심', '저녁'],
      tag: '든든',
      why: '탄수화물과 식이섬유를 한 번에 채워요.',
    ),
    MealSuggestion(
      name: '그릭요거트 · 아몬드 · 블루베리',
      emoji: '🫐',
      kcal: 280,
      meta: '칼슘 300mg · 단백질 18g',
      covers: ['칼슘', '단백질'],
      prefs: ['간편식'],
      meals: ['아침', '간식'],
      tag: '5분',
      why: '간식으로 칼슘과 단백질을 함께 챙길 수 있어요.',
    ),
    MealSuggestion(
      name: '닭가슴살 스테이크 · 시금치',
      emoji: '🍗',
      kcal: 430,
      meta: '단백질 38g · 철분 4mg',
      covers: ['단백질', '철분'],
      prefs: ['고단백', '저나트륨'],
      meals: ['점심', '저녁'],
      tag: '고단백',
      why: '단백질 목표가 남았을 때 가장 효율적이에요.',
    ),
    MealSuggestion(
      name: '오트밀 · 바나나 · 우유',
      emoji: '🥛',
      kcal: 320,
      meta: '탄수화물 52g · 식이섬유 8g · 칼슘 320mg',
      covers: ['탄수화물', '식이섬유', '칼슘'],
      prefs: ['간편식', '채식 위주'],
      meals: ['아침', '간식'],
      tag: '5분',
      why: '아침 탄수화물과 칼슘을 동시에 챙기는 조합이에요.',
    ),
    MealSuggestion(
      name: '고구마 · 삶은 달걀 · 그린샐러드',
      emoji: '🍠',
      kcal: 380,
      meta: '탄수화물 54g · 식이섬유 7g · 단백질 16g',
      covers: ['탄수화물', '식이섬유', '단백질'],
      prefs: ['간편식', '채식 위주'],
      meals: ['아침', '점심', '간식'],
      tag: '10분',
      why: '탄수화물이 부족한 날 혈당 부담이 적은 선택이에요.',
    ),
    MealSuggestion(
      name: '아보카도 통밀 토스트 · 달걀',
      emoji: '🥑',
      kcal: 420,
      meta: '지방 26g · 탄수화물 34g · 식이섬유 9g',
      covers: ['지방', '탄수화물', '식이섬유'],
      prefs: ['간편식', '채식 위주'],
      meals: ['아침', '점심'],
      tag: '10분',
      why: '지방이 부족할 때 불포화지방으로 채우기 좋아요.',
    ),
    MealSuggestion(
      name: '견과 한 줌 · 무가당 요거트',
      emoji: '🥜',
      kcal: 260,
      meta: '지방 19g · 칼슘 210mg · 단백질 12g',
      covers: ['지방', '칼슘', '단백질'],
      prefs: ['간편식'],
      meals: ['간식'],
      tag: '즉시',
      why: '간식으로 좋은 지방과 칼슘을 함께 보충해요.',
    ),
    MealSuggestion(
      name: '고등어 구이 · 현미밥',
      emoji: '🐟',
      kcal: 540,
      meta: '오메가3 2.2g · 비타민D 12µg · 단백질 32g',
      covers: ['오메가3', '비타민D', '단백질'],
      prefs: ['저나트륨'],
      meals: ['점심', '저녁'],
      tag: '집밥',
      why: '비타민D와 오메가3를 한 번에 채우는 메뉴예요.',
    ),
    MealSuggestion(
      name: '두부 김치 볶음 · 현미',
      emoji: '🍲',
      kcal: 470,
      meta: '단백질 24g · 식이섬유 8g',
      covers: ['단백질', '식이섬유'],
      prefs: ['채식 위주'],
      meals: ['점심', '저녁'],
      tag: '집밥',
      why: '익숙한 조합으로 단백질을 채울 수 있어요.',
    ),
    MealSuggestion(
      name: '새우 두부면 파스타',
      emoji: '🍝',
      kcal: 410,
      meta: '단백질 34g · 식이섬유 7g',
      covers: ['단백질', '식이섬유'],
      prefs: ['고단백', '간편식'],
      meals: ['점심', '저녁'],
      tag: '20분',
      why: '면이 먹고 싶을 때 칼로리 부담을 줄인 선택이에요.',
    ),
  ];

  /// 조건 기반 추천 결과 (점수 내림차순 또는 칼로리 오름차순)
  List<AiMealSuggestion>? aiRecommendations;
  bool loadingRecommendations = false;
  String? recommendationError;

  /// AI에게 지금 조건(needs · recMeal · recPrefs · recMaxKcal)으로 추천을 요청한다.
  Future<void> fetchAiRecommendations() async {
    loadingRecommendations = true;
    recommendationError = null;
    notifyListeners();
    try {
      aiRecommendations = await _mealRecommendationService.recommend(
        needs: needs,
        meal: recMeal,
        prefs: recPrefs,
        maxKcal: recMaxKcal,
      );
    } catch (e, stack) {
      debugPrint('식단 추천을 받지 못했어요: $e\n$stack');
      recommendationError = '추천을 불러오지 못했어요. 다시 시도해주세요.';
    } finally {
      loadingRecommendations = false;
      notifyListeners();
    }
  }

  List<({MealSuggestion meal, int score, bool offMeal})> get recommendations {
    final ai = aiRecommendations;
    if (ai != null) {
      final scored = [
        for (final s in ai)
          (
            meal: MealSuggestion(
              name: s.name,
              emoji: s.emoji,
              kcal: s.kcal,
              meta: s.meta,
              covers: s.covers,
              prefs: s.prefs,
              meals: s.meals,
              tag: s.tag,
              why: s.why,
            ),
            score: s.score,
            offMeal: !s.meals.contains(recMeal),
          ),
      ];
      scored.sort(
        (a, b) => recSort == '칼로리 낮은 순'
            ? a.meal.kcal.compareTo(b.meal.kcal)
            : b.score.compareTo(a.score),
      );
      return scored;
    }

    // AI 추천을 아직 못 받아왔을 때(로딩 중 · 실패)는 예전 규칙 기반 추천으로 대체한다.
    int raw(MealSuggestion m) =>
        m.covers.where(needs.contains).length * 30 +
        m.prefs.where(recPrefs.contains).length * 14 +
        20;

    final matched = _pool
        .where((m) => m.kcal <= recMaxKcal && m.meals.contains(recMeal))
        .toList();
    final base = matched.length >= 3
        ? matched
        : _pool.where((m) => m.kcal <= recMaxKcal).toList();
    if (base.isEmpty) return [];

    final top = base.map(raw).reduce((a, b) => a > b ? a : b).clamp(1, 9999);

    final scored = base.map((m) {
      final off = !m.meals.contains(recMeal);
      final s = ((raw(m) / top) * 96).round() - (off ? 18 : 0);
      return (meal: m, score: s < 52 ? 52 : s, offMeal: off);
    }).toList();

    scored.sort(
      (a, b) => recSort == '칼로리 낮은 순'
          ? a.meal.kcal.compareTo(b.meal.kcal)
          : b.score.compareTo(a.score),
    );
    return scored;
  }

  void toggleNeed(String n) {
    needs.contains(n) ? needs.remove(n) : needs.add(n);
    notifyListeners();
  }

  void togglePref(String p) {
    recPrefs.contains(p) ? recPrefs.remove(p) : recPrefs.add(p);
    notifyListeners();
  }

  void setRecMeal(String m) {
    recMeal = m;
    notifyListeners();
  }

  void setRecMaxKcal(int v) {
    recMaxKcal = v;
    notifyListeners();
  }

  void setRecSort(String s) {
    recSort = s;
    notifyListeners();
  }

  // 리포트
  String period = '주간';

  void setPeriod(String p) {
    period = p;
    notifyListeners();
  }

  // 리포트 탭(주간 · 월간) — 실제 기록을 집계한다.
  //
  // "주간"은 오늘을 포함한 최근 7일, "월간"은 이번 달 1일부터 오늘까지다.
  // _loadAccountData가 이번 달 + 지난달 기록만 불러오므로, 그 범위를 벗어난
  // 조회는 하지 않는다(지지난달과 비교하는 식의 통계는 만들지 않았다).
  static const _weekdayShort = ['월', '화', '수', '목', '금', '토', '일'];

  List<DateTime> get _periodDays => period == '주간'
      ? [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))]
      : [
          for (var d = 1; d <= today.day; d++)
            DateTime(today.year, today.month, d),
        ];

  /// 이전 동일 기간(지난주 · 지난달) — 증감 비교에만 쓴다.
  List<DateTime> get _prevPeriodDays => period == '주간'
      ? [for (var i = 13; i >= 7; i--) today.subtract(Duration(days: i))]
      : [
          for (var d = 1; d <= DateTime(today.year, today.month, 0).day; d++)
            DateTime(today.year, today.month - 1, d),
        ];

  /// 월간일 때 달력 주 단위(최대 7일)로 묶는다. 주간은 하루씩 그대로 묶는다.
  List<List<DateTime>> get _periodBuckets {
    final days = _periodDays;
    if (period == '주간') {
      return [
        for (final d in days) [d],
      ];
    }
    return [
      for (var i = 0; i < days.length; i += 7)
        days.sublist(i, i + 7 > days.length ? days.length : i + 7),
    ];
  }

  int _kcalOn(DateTime d) {
    final key = dateKeyOf(d);
    return _mealLogs
        .where((m) => m.dateKey == key)
        .fold(0, (a, m) => a + m.kcal);
  }

  int _exerciseMinOn(DateTime d) {
    final key = dateKeyOf(d);
    return _exerciseLogs
        .where((e) => e.dateKey == key)
        .fold(0, (a, e) => a + e.minutes);
  }

  /// [key] 날짜까지 기록된 것 중 가장 최근 체중(없으면 그 이후 가장 이른
  /// 기록, 그마저 없으면 프로필의 현재 체중) — 매일 재지 않아도 그래프가
  /// 끊기지 않게 이전 값을 이어서 보여준다.
  double _weightAsOf(String key) {
    WeightEntry? best;
    for (final w in weightEntries) {
      if (w.dateKey.compareTo(key) > 0) continue;
      if (best == null || w.dateKey.compareTo(best.dateKey) > 0) best = w;
    }
    if (best != null) return best.kg;
    WeightEntry? earliest;
    for (final w in weightEntries) {
      if (earliest == null || w.dateKey.compareTo(earliest.dateKey) < 0) {
        earliest = w;
      }
    }
    return earliest?.kg ?? profile.weightKg;
  }

  List<({String label, int value, int pct})> get kcalBars {
    final buckets = _periodBuckets;
    return [
      for (var i = 0; i < buckets.length; i++) _kcalBarFor(buckets[i], i),
    ];
  }

  ({String label, int value, int pct}) _kcalBarFor(
    List<DateTime> days,
    int weekIndex,
  ) {
    final avg = days.isEmpty
        ? 0
        : (days.fold(0, (a, d) => a + _kcalOn(d)) / days.length).round();
    final label = period == '주간'
        ? _weekdayShort[days.first.weekday - 1]
        : '${weekIndex + 1}주';
    final pct = dailyTarget > 0
        ? (avg / dailyTarget * 100).round().clamp(0, 100)
        : 0;
    return (label: label, value: avg, pct: pct);
  }

  List<({String label, double kg})> get weightSeries {
    final buckets = _periodBuckets;
    return [
      for (var i = 0; i < buckets.length; i++)
        (
          label: period == '주간'
              ? '${buckets[i].first.month}/${buckets[i].first.day}'
              : '${i + 1}주',
          kg: _weightAsOf(dateKeyOf(buckets[i].last)),
        ),
    ];
  }

  int get _avgKcalThisPeriod {
    final days = _periodDays;
    if (days.isEmpty) return 0;
    return (days.fold(0, (a, d) => a + _kcalOn(d)) / days.length).round();
  }

  int get _avgKcalPrevPeriod {
    final days = _prevPeriodDays;
    if (days.isEmpty) return 0;
    return (days.fold(0, (a, d) => a + _kcalOn(d)) / days.length).round();
  }

  String get avgKcal => AppStateFormat.comma(_avgKcalThisPeriod);

  String get periodDelta {
    final delta = _avgKcalThisPeriod - _avgKcalPrevPeriod;
    final label = period == '주간' ? '지난주' : '지난달';
    if (delta == 0) return '$label과 비슷해요';
    final sign = delta > 0 ? '+' : '-';
    return '$label 대비 $sign${AppStateFormat.comma(delta.abs())}kcal';
  }

  int get avgExerciseMin {
    final days = _periodDays;
    if (days.isEmpty) return 0;
    return (days.fold(0, (a, d) => a + _exerciseMinOn(d)) / days.length)
        .round();
  }

  int get exerciseMinDelta {
    final days = _periodDays;
    final prevDays = _prevPeriodDays;
    if (days.isEmpty || prevDays.isEmpty) return 0;
    final now = days.fold(0, (a, d) => a + _exerciseMinOn(d)) / days.length;
    final prev =
        prevDays.fold(0, (a, d) => a + _exerciseMinOn(d)) / prevDays.length;
    return (now - prev).round();
  }

  /// 이 기간의 날짜 중, 하루 권장 칼로리 안으로 먹은(0kcal 초과 ~ 목표 이하)
  /// 날의 비율. 아예 기록하지 않은 날은 "달성"으로 치지 않는다.
  int get achieveRate {
    final days = _periodDays;
    if (days.isEmpty || dailyTarget <= 0) return 0;
    final achieved = days.where((d) {
      final kcal = _kcalOn(d);
      return kcal > 0 && kcal <= dailyTarget;
    }).length;
    return (achieved / days.length * 100).round();
  }

  int get recordDays => _periodDays.where(hasRecordOn).length;
  int get recordGoalDays => period == '주간' ? 5 : 20;

  List<MealLog> get _periodMeals {
    final keys = _periodDays.map(dateKeyOf).toSet();
    return _mealLogs.where((m) => keys.contains(m.dateKey)).toList();
  }

  String get mostEatenFood {
    final meals = _periodMeals;
    if (meals.isEmpty) return '기록된 식단이 없어요';
    final counts = <String, int>{};
    for (final m in meals) {
      counts[m.name] = (counts[m.name] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return '${top.key} · ${top.value}회';
  }

  String get mostUsedBowl {
    final withBowl = _periodMeals.where((m) => m.bowlId != null);
    if (withBowl.isEmpty) return '사용한 그릇이 없어요';
    final counts = <String, int>{};
    for (final m in withBowl) {
      counts[m.bowlId!] = (counts[m.bowlId!] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    Bowl? matched;
    for (final b in bowls) {
      if (b.id == top.key) {
        matched = b;
        break;
      }
    }
    return '${matched?.name ?? '삭제된 그릇'} · ${top.value}회';
  }

  String get mostUsedSauce {
    final withSauce = _periodMeals.where((m) => m.sauce.isNotEmpty);
    if (withSauce.isEmpty) return '기록된 소스가 없어요';
    final counts = <String, int>{};
    for (final m in withSauce) {
      counts[m.sauce] = (counts[m.sauce] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return '${top.key} · ${top.value}회';
  }

  /// 이 기간 동안 가장 부족했던(목표 대비 %가 가장 낮은) 영양소.
  String get lackingNutrient {
    final meals = _periodMeals;
    if (meals.isEmpty) return '기록된 식단이 없어요';
    final days = _periodDays.length;
    ({String name, int pct})? worst;
    for (final (name, _, target, _) in _nutrientMeta) {
      final pick = _nutrientPick(name);
      final total = meals.fold(0.0, (a, m) => a + pick(m));
      final periodTarget = target * days;
      final pct = periodTarget <= 0 ? 0 : (total / periodTarget * 100).round();
      if (worst == null || pct < worst.pct) worst = (name: name, pct: pct);
    }
    if (worst == null || worst.pct >= 100) return '부족한 영양소가 없어요';
    return '${worst.name} ${worst.pct - 100}%';
  }

  static const _nutrientTip = {
    '단백질': '단백질이 부족해요. 닭가슴살이나 두부, 계란 위주 식사를 추천해요.',
    '탄수화물': '탄수화물이 부족해요. 현미밥이나 고구마를 곁들여보세요.',
    '지방': '지방이 부족해요. 견과류나 아보카도, 올리브오일을 더해보세요.',
    '식이섬유': '식이섬유가 부족해요. 채소나 통곡물 위주 식사를 추천해요.',
    '나트륨': '나트륨 섭취가 부족해요. 국물 요리를 곁들여도 좋아요.',
    '당류': '당류 섭취가 부족해요. 제철 과일을 간식으로 더해보세요.',
    '칼슘': '칼슘이 부족해요. 유제품이나 멸치, 두부를 추천해요.',
    '철분': '철분이 부족해요. 붉은 고기나 시금치를 추천해요.',
  };

  String get recommendedMeal {
    if (_periodMeals.isEmpty) {
      return '아직 기록된 식단이 없어요. 식사를 기록하면 맞춤 추천을 보여드려요.';
    }
    final lacking = lackingNutrient;
    for (final entry in _nutrientTip.entries) {
      if (lacking.startsWith(entry.key)) return entry.value;
    }
    return '이번 기간 영양소를 골고루 채웠어요. 지금처럼 유지해보세요!';
  }

  // 친구 · 챌린지
  //
  // 사람은 이름 문자열이 아니라 User 모델(id로 구분)로 다룬다.
  // "나"는 currentUser로, 그 외 사람들은 아래 people 목록에서 가져온다.

  static const List<User> people = [
    User(id: 'u_jihyun', nickname: '지현', emoji: '🏃', tint: Color(0xFFFFEDE3)),
    User(id: 'u_minsu', nickname: '민수', emoji: '🪴', tint: Color(0xFFEAF5E7)),
    User(id: 'u_seoyeon', nickname: '서연', emoji: '🌸', tint: Color(0xFFFCEAF1)),
    User(id: 'u_taeho', nickname: '태호', emoji: '💧', tint: Color(0xFFEAF1FE)),
    User(id: 'u_hyunwoo', nickname: '현우', emoji: '🙂', tint: Color(0xFFF7EFE7)),
    User(id: 'u_minji', nickname: '민지', emoji: '🏃', tint: Color(0xFFFFEDE3)),
    User(id: 'u_junho', nickname: '준호', emoji: '🥗', tint: Color(0xFFEAF5E7)),
    User(id: 'u_yujin', nickname: '유진', emoji: '🌱', tint: Color(0xFFEAF5E7)),
  ];

  /// 지금 로그인한 사용자. 닉네임은 온보딩 · 마이페이지에서 바꾸는 값(nickname)을 그대로 반영한다.
  User get currentUser => User(
    id: _uid,
    nickname: nickname,
    emoji: '🙂',
    tint: const Color(0xFFEAF1FE),
  );

  /// id로 사람을 찾는다. 목록에 없는 id면(알 수 없는 사람) 안전한 대체 값을 준다.
  static User personById(String id) => people.firstWhere(
    (u) => u.id == id,
    orElse: () => User(
      id: id,
      nickname: '알 수 없음',
      emoji: '❓',
      tint: const Color(0xFFEDEDED),
    ),
  );

  List<String> addedFriends = [];
  final PrivacySettings privacySettings = PrivacySettings(userId: User.meId);

  String get shareScope => privacySettings.scope.label;
  set shareScope(String value) => privacySettings.scope = value == '비공개'
      ? ShareScope.private
      : ShareScope.friends;

  /// 이 계정의 진짜 초대 코드. 로그인 직후 _loadFriendData에서 채워진다.
  String inviteCode = '';

  /// 실제로 친구 관계가 확정된 사람들(공개 프로필만 — 닉네임 정도).
  List<PublicProfile> realFriends = [];

  /// 나 + 친구들이 남긴 최근 활동(식단 · 운동 · 물 기록).
  List<ActivityFeedEntry> realActivityFeed = [];

  /// 내가 받은, 아직 답하지 않은 진짜 친구 요청.
  List<FriendRequest> incomingFriendRequests = [];

  /// 받은 요청을 보낸 사람들의 닉네임 — fromUid로 찾아 화면에 보여줄 때 쓴다.
  Map<String, PublicProfile> requesterProfiles = {};

  /// 초대 코드로 검색한 결과 — 화면에 "이 사람 맞아요?" 하고 보여줄 때 쓴다.
  PublicProfile? friendSearchResult;
  bool friendSearchNotFound = false;

  String friendSearchQuery = '';

  void setFriendSearchQuery(String v) {
    friendSearchQuery = v;
    friendSearchResult = null;
    friendSearchNotFound = false;
    notifyListeners();
  }

  /// 로그인 직후 초대 코드 · 친구 목록 · 받은 요청 · 활동 피드를 불러온다.
  Future<void> _loadFriendData(String uid) async {
    try {
      inviteCode = await _friendRepo.ensureInviteCode(uid, nickname);
      final friendUids = await _friendRepo.loadFriendUids(uid);
      realFriends = [
        for (final id in friendUids) ?await _friendRepo.loadPublicProfile(id),
      ];
      incomingFriendRequests = await _friendRepo.loadIncomingRequests(uid);
      requesterProfiles = {};
      for (final r in incomingFriendRequests) {
        final p = await _friendRepo.loadPublicProfile(r.fromUid);
        if (p != null) requesterProfiles[r.fromUid] = p;
      }
      realActivityFeed = await _activityFeedRepo.loadRecent([
        uid,
        ...friendUids,
      ]);
    } catch (e, stack) {
      debugPrint('친구 정보를 불러오지 못했어요: $e\n$stack');
      _notice = '친구 정보를 불러오지 못했어요.';
    }
  }

  /// friendSearchQuery를 초대 코드로 취급해 상대를 찾는다.
  Future<void> searchFriendByCode() async {
    final code = friendSearchQuery.trim();
    if (code.isEmpty) return;
    final uid = await _friendRepo.findUidByCode(code);
    if (uid == null || uid == _uid) {
      friendSearchResult = null;
      friendSearchNotFound = true;
      notifyListeners();
      return;
    }
    friendSearchResult = await _friendRepo.loadPublicProfile(uid);
    friendSearchNotFound = friendSearchResult == null;
    notifyListeners();
  }

  /// 검색 결과로 나온 사람에게 친구 요청을 보낸다.
  Future<void> sendFriendRequestToSearchResult() async {
    final target = friendSearchResult;
    if (target == null) return;
    await _friendRepo.sendFriendRequest(_uid, target.uid);
    friendSearchResult = null;
    friendSearchQuery = '';
    notifyListeners();
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    await _friendRepo.acceptFriendRequest(request);
    incomingFriendRequests.removeWhere((r) => r.id == request.id);
    final profile =
        requesterProfiles.remove(request.fromUid) ??
        await _friendRepo.loadPublicProfile(request.fromUid);
    if (profile != null) realFriends.add(profile);
    notifyListeners();
  }

  Future<void> declineFriendRequest(FriendRequest request) async {
    await _friendRepo.declineFriendRequest(request.id);
    incomingFriendRequests.removeWhere((r) => r.id == request.id);
    requesterProfiles.remove(request.fromUid);
    notifyListeners();
  }

  /// 정당한 사용자 탐색 방법(초대 코드) 없이 "추천"을 지어내지 않는다.
  /// 언젠가 실제 추천 로직(예: 연락처 연동)이 생기면 그때 채운다.
  List<({User user, String desc})> get suggestedFriends => const [];

  /// uid로 화면에 보여줄 User를 만든다 — 나 → 실제 친구 프로필 → 데모 인물 순으로 찾는다.
  User _userFor(String uid) {
    if (uid == _uid) return currentUser;
    for (final f in realFriends) {
      if (f.uid == uid) {
        return User(
          id: f.uid,
          nickname: f.nickname,
          emoji: '🙂',
          tint: const Color(0xFFEAF1FE),
        );
      }
    }
    return personById(uid);
  }

  String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 2) return '어제';
    return '${diff.inDays}일 전';
  }

  void setFriendTab(String t) {
    friendTab = t;
    notifyListeners();
  }

  void setShareScope(String s) {
    shareScope = s;
    notifyListeners();
    unawaited(_persistInBackground());
  }

  // 친구 탭 · 활동 요약
  //
  // 화면에는 "활성 챌린지" 하나만 보여주는데, 여러 개에 참여 중이면
  // 가장 먼저 참여한(목록 첫 번째) 챌린지를 대표로 보여준다.
  Challenge? get _primaryChallenge =>
      myChallenges.isEmpty ? null : myChallenges.first;

  String get activeChallengeName => _primaryChallenge?.title ?? '';

  /// 남은 일수 대신, 챌린지에 저장된 기간 문자열을 그대로 보여준다.
  String get activeChallengePeriod => _primaryChallenge?.period ?? '';

  List<({User user, double ratio})> get activeChallengeProgress {
    final c = _primaryChallenge;
    if (c == null) return [];
    final progress = _challengeProgress[c.id] ?? const {};
    return [
      for (final uid in c.participantIds)
        (
          user: _userFor(uid),
          ratio: c.targetValue <= 0
              ? 0.0
              : ((progress[uid] ?? 0) / c.targetValue).clamp(0.0, 1.0),
        ),
    ];
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
    unawaited(_persistInBackground());
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
    unawaited(_persistInBackground());
  }

  List<({User user, String activity, String time})> get friendActivity => [
    for (final e in realActivityFeed)
      (user: _userFor(e.uid), activity: e.message, time: _relativeTime(e.at)),
  ];

  final Set<String> cheeredFriends = {};

  void cheerFriend(String userId) {
    cheeredFriends.add(userId);
    notifyListeners();
  }

  // 친구 탭 · 챌린지
  List<({User user, int pct})> _rankedParticipants(Challenge? c) {
    if (c == null) return [];
    final progress = _challengeProgress[c.id] ?? const {};
    final list = [
      for (final uid in c.participantIds)
        (
          user: _userFor(uid),
          pct: c.targetValue <= 0
              ? 0
              : (((progress[uid] ?? 0) / c.targetValue) * 100).round().clamp(
                  0,
                  100,
                ),
        ),
    ];
    list.sort((a, b) => b.pct.compareTo(a.pct));
    return list;
  }

  int get myChallengeRank {
    final ranked = _rankedParticipants(_primaryChallenge);
    final i = ranked.indexWhere((r) => r.user.id == _uid);
    return i < 0 ? 0 : i + 1;
  }

  List<({int rank, User user, int pct})> get challengeLeaderboard {
    final ranked = _rankedParticipants(_primaryChallenge);
    return [
      for (var i = 0; i < ranked.length; i++)
        (rank: i + 1, user: ranked[i].user, pct: ranked[i].pct),
    ];
  }

  static const challengeRewardTiers = [
    (
      icon: '💧',
      tint: Color(0xFFEAF1FE),
      title: '데일리 챌린지 (1일)',
      confirmed: '확정 · 물방울 1개',
      bonus: '보너스 15% · 희귀 씨앗',
    ),
    (
      icon: '🌰',
      tint: Color(0xFFF7EFE7),
      title: '위클리 챌린지 (2~7일)',
      confirmed: '확정 · 희귀 씨앗 1개',
      bonus: '보너스 15% · 전설 씨앗',
    ),
    (
      icon: '🏺',
      tint: Color(0xFFF1ECFF),
      title: '장기 챌린지 (8일~)',
      confirmed: '확정 · 전설 씨앗 + 정원 장식',
      bonus: '보너스 10% · 스페셜 아이템',
    ),
  ];

  /// 데모(Mock) 계정에서 보여줄 예시 챌린지. 실제 계정은 로그인 후
  /// _loadChallenges에서 Firestore에 저장된 전체 목록으로 덮어쓴다.
  List<Challenge> challenges = [
    Challenge(
      id: 'c_water_2l',
      title: '오늘 물 2L 마시기',
      description: '자정까지 물 2,000ml 기록하기',
      icon: '💧',
      category: '데일리',
      period: '오늘 하루',
      creatorId: 'u_jihyun',
      participantIds: ['u_jihyun', 'u_minsu', 'u_seoyeon'],
      metricType: ChallengeType.water,
      targetValue: 2000,
      isPublic: true,
      rewardDescription: '확정 물방울 1개',
      bonusDescription: '보너스 15% 희귀 씨앗 · 실패 시 눈바디 전송',
    ),
    Challenge(
      id: 'c_morning_run_sep',
      title: '9월 아침 러닝 챌린지',
      description: '매일 아침 20분 이상 러닝 기록하기',
      icon: '🏃',
      category: '장기',
      period: '9/1 ~ 9/30',
      creatorId: 'u_taeho',
      participantIds: ['u_taeho', 'u_hyunwoo'],
      metricType: ChallengeType.exercise,
      targetValue: 20,
      isPublic: true,
      rewardDescription: '확정 전설 씨앗 + 정원 장식',
      bonusDescription: '보너스 10% 스페셜 아이템 · 실패 시 눈바디 전송',
    ),
  ];

  /// 챌린지별 · 참가자별 오늘 진행 상황(리더보드용). 내가 참여 중인
  /// 챌린지만 불러온다.
  Map<String, Map<String, num>> _challengeProgress = {};

  /// 저장된 전체 챌린지와, 그중 내가 참여 중인 챌린지의 진행 상황을 불러온다.
  Future<void> _loadChallenges(String uid) async {
    try {
      challenges = await _challengeRepo.loadAll();
      final progress = <String, Map<String, num>>{};
      for (final c in challenges.where((c) => c.isParticipant(uid))) {
        progress[c.id] = await _challengeRepo.loadProgress(
          c.id,
          c.participantIds,
        );
      }
      _challengeProgress = progress;
    } catch (e, stack) {
      debugPrint('챌린지를 불러오지 못했어요: $e\n$stack');
      challenges = [];
      _challengeProgress = {};
      _notice = '챌린지를 불러오지 못했어요.';
    }
  }

  /// 친구 활동 피드에 한 줄을 남긴다. 데모 계정(로그인 안 함)에서는 아무것도 하지 않는다.
  void _postActivity(String message) {
    final a = account;
    if (a == null) return;
    unawaited(
      _activityFeedRepo.post(a.uid, message).catchError((
        Object e,
        StackTrace stack,
      ) {
        debugPrint('활동 피드를 기록하지 못했어요: $e\n$stack');
      }),
    );
  }

  /// 내가 참여 중인, metricType이 일치하는 모든 챌린지에 오늘 진행 상황을 보고한다.
  void _reportChallengeProgress(ChallengeType type, num value) {
    final a = account;
    if (a == null) return;
    for (final c in myChallenges.where((c) => c.metricType == type)) {
      unawaited(
        _challengeRepo.reportProgress(c.id, a.uid, value).catchError((
          Object e,
          StackTrace stack,
        ) {
          debugPrint('챌린지 진행 상황을 저장하지 못했어요: $e\n$stack');
        }),
      );
    }
  }

  /// 아직 내가 참여하지 않은 공개 챌린지
  List<Challenge> get joinableChallenges => challenges
      .where((c) => c.isPublic && !c.isParticipant(currentUser.id))
      .toList();

  /// 내가 만들었거나 참여 중인 챌린지
  List<Challenge> get myChallenges =>
      challenges.where((c) => c.isParticipant(currentUser.id)).toList();

  void addFriend(String userId) {
    if (!addedFriends.contains(userId)) addedFriends.add(userId);
    notifyListeners();
  }

  Future<void> joinChallenge(String challengeId) async {
    final target = challenges.where((c) => c.id == challengeId);
    if (target.isEmpty) return;
    if (!target.first.participantIds.contains(currentUser.id)) {
      target.first.participantIds.add(currentUser.id); // 화면에 바로 반영
    }
    notifyListeners();
    await _challengeRepo.join(challengeId, currentUser.id);
  }

  // 챌린지 만들기 폼
  /// 챌린지 생성 화면의 임시 입력값입니다. Challenge는 저장 시에만 만듭니다.
  final ChallengeDraft challengeDraft = ChallengeDraft(
    invitedUserIds: ['u_jihyun', 'u_minsu'],
  );

  String get chKind => challengeDraft.type.label;
  set chKind(String value) => challengeDraft.type = switch (value) {
    '운동 시간' => ChallengeType.exercise,
    '식단 기록' => ChallengeType.mealRecord,
    '단백질' => ChallengeType.protein,
    _ => ChallengeType.water,
  };

  int get chTarget => challengeDraft.dailyTarget;
  set chTarget(int value) => challengeDraft.dailyTarget = value;

  int get chDays => challengeDraft.durationDays;
  set chDays(int value) => challengeDraft.durationDays = value;

  List<String> get chInvites => challengeDraft.invitedUserIds
      .map((id) => personById(id).nickname)
      .toList();

  bool get chPublic => challengeDraft.visibility == ChallengeVisibility.public;
  set chPublic(bool value) => challengeDraft.visibility = value
      ? ChallengeVisibility.public
      : ChallengeVisibility.private;

  String get chReward => challengeDraft.reward.label;
  set chReward(String value) => challengeDraft.reward = switch (value) {
    '배지' => ChallengeReward.badge,
    '없음' => ChallengeReward.none,
    _ => ChallengeReward.plantExperience,
  };

  static const chKindMeta =
      <String, ({String icon, String unit, int base, String desc})>{
        '물 마시기': (icon: '💧', unit: 'ml', base: 2000, desc: '하루 물 섭취량'),
        '운동 시간': (icon: '🏃', unit: '분', base: 40, desc: '하루 운동 시간'),
        '식단 기록': (icon: '🍽️', unit: '회', base: 3, desc: '하루 기록 횟수'),
        '단백질': (icon: '🥚', unit: 'g', base: 100, desc: '하루 단백질 섭취'),
      };

  String get chUnit => chKindMeta[chKind]!.unit;

  String get chDurLabel => chDays % 30 == 0 && chDays >= 30
      ? '${chDays ~/ 30}개월'
      : chDays % 7 == 0
      ? '${chDays ~/ 7}주'
      : '$chDays일';

  String get chName =>
      '$chKind ${AppStateFormat.comma(chTarget)}$chUnit $chDurLabel 챌린지';

  String get chRange {
    final end = DateTime(2026, 9, chDays.clamp(1, 365));
    return '9월 1일 ~ ${end.month}월 ${end.day}일 ($chDays일)';
  }

  String get chRewardDesc => {
    '식물 EXP': '완주하면 참가자 전원 +100 EXP, 1위는 +150 EXP를 받아요.',
    '배지': '완주자에게 전용 배지가 지급돼요.',
    '없음': '순위만 기록되고 별도 보상은 없어요.',
  }[chReward]!;

  String get chPreview =>
      '참가 ${chInvites.length + 1}명 · $chDays일 · 매일 ${AppStateFormat.comma(chTarget)}$chUnit 달성 · '
      '보상 $chReward${chPublic ? ' · 공개' : ' · 초대한 친구만'}';

  void setChKind(String k) {
    chKind = k;
    chTarget = chKindMeta[k]!.base;
    notifyListeners();
  }

  void setChTarget(int v) {
    chTarget = v < 0 ? 0 : v;
    notifyListeners();
  }

  void setChDays(int v) {
    chDays = v.clamp(1, 365);
    notifyListeners();
  }

  void toggleChInvite(String n) {
    final user = people.firstWhere(
      (candidate) => candidate.nickname == n,
      orElse: () => User(
        id: 'u_$n',
        nickname: n,
        emoji: '🙂',
        tint: const Color(0xFFEDEDED),
      ),
    );
    challengeDraft.invitedUserIds.contains(user.id)
        ? challengeDraft.invitedUserIds.remove(user.id)
        : challengeDraft.invitedUserIds.add(user.id);
    notifyListeners();
  }

  void setChPublic(bool v) {
    chPublic = v;
    notifyListeners();
  }

  void setChReward(String r) {
    chReward = r;
    notifyListeners();
  }

  Future<void> createChallenge() async {
    final end = DateTime(2026, 9, chDays.clamp(1, 365));
    final invitedIds = chInvites
        .map(
          (n) => people
              .firstWhere(
                (u) => u.nickname == n,
                orElse: () => User(
                  id: 'u_$n',
                  nickname: n,
                  emoji: '🙂',
                  tint: const Color(0xFFEDEDED),
                ),
              )
              .id,
        )
        .toList();
    final challenge = Challenge(
      id: 'c_${DateTime.now().microsecondsSinceEpoch}',
      title: chName,
      description:
          '매일 ${AppStateFormat.comma(chTarget)}$chUnit 달성 · 보상 $chReward',
      icon: chKindMeta[chKind]!.icon,
      category: chDurLabel,
      period: '9/1 ~ ${end.month}/${end.day}',
      creatorId: currentUser.id,
      participantIds: [currentUser.id, ...invitedIds],
      metricType: challengeDraft.type,
      targetValue: chTarget,
      isPublic: chPublic,
      rewardDescription: chRewardDesc,
    );
    challenges.add(challenge); // 화면에 바로 반영
    friendTab = '챌린지';
    screen = 'friends';
    notifyListeners();
    await _challengeRepo.create(challenge);
  }

  // 설정
  //
  // 여기 보이는 토글 · 시간은 새 상태가 아니라, 이미 계정에 저장되고 있는
  // notificationSettings를 화면이 읽기 쉬운 한글 키로 보여주는 것뿐이다.
  Map<String, bool> get notifyToggles => {
    '식단 미기록 알림': notificationSettings.mealReminder,
    '물 마시기 알림': notificationSettings.waterReminder,
    '운동 리마인드': notificationSettings.exerciseReminder,
    '친구 응원 알림': notificationSettings.friendActivity,
  };

  Map<String, String> get alertTime => {
    '아침 기록 알림': notificationSettings.morningAlertTime,
    '저녁 정리 알림': notificationSettings.eveningAlertTime,
    '주간 리포트': notificationSettings.weeklyReportTime,
  };

  void toggleNotify(String k) {
    switch (k) {
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
    notifyListeners();
    unawaited(_persistInBackground());
    unawaited(_applyNotificationSchedule());
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
    unawaited(_persistInBackground());
    unawaited(_applyNotificationSchedule());
  }

  void setSetTab(String t) {
    setTab = t;
    notifyListeners();
  }

  // FAB (드래그 가능)
  Offset? fabPos; // null = 기본 위치 (탭바 중앙 위)
  bool fabOpen = false;
  bool fabHint = true;

  void moveFab(Offset p) {
    fabPos = p;
    fabHint = false;
    notifyListeners();
  }

  void toggleFab() {
    fabOpen = !fabOpen;
    fabHint = false;
    notifyListeners();
  }

  void closeFab() {
    fabOpen = false;
    notifyListeners();
  }

  static String comma(int n) => AppStateFormat.comma(n);
}
