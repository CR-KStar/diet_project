// 앱 전역 상태 — 프로토타입의 Component.state를 그대로 옮긴 ChangeNotifier.
//
// 화면 전환도 여기서 관리합니다 (Navigator 대신 screen 문자열).
// 통합된 화면은 부모 screen + 서브 모드 플래그로 표현합니다.

import 'package:diet_project/ui/growth/viewmodel/plant_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/mission_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/recommendation_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/bowl_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/exercise_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/meal_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/photo_analysis_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/routine_view_model.dart';
import 'package:diet_project/ui/report_settings/viewmodel/report_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/weight_view_model.dart';
import 'package:diet_project/ui/social/viewmodel/challenge_view_model.dart';
import 'package:diet_project/ui/social/viewmodel/friend_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diet_project/data/services/app_icon_service.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';
import 'package:diet_project/data/services/ai_consent_store.dart';
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
    WeightViewModel? weightViewModel,
    MealViewModel? mealViewModel,
    ExerciseViewModel? exerciseViewModel,
    BowlViewModel? bowlViewModel,
    RoutineViewModel? routineViewModel,
    PlantViewModel? plantViewModel,
    PhotoAnalysisViewModel? photoAnalysisViewModel,
    RecommendationViewModel? recommendationViewModel,
    FriendViewModel? friendViewModel,
    ChallengeViewModel? challengeViewModel,
    RecordRepository<ExerciseLog>? exerciseRepo,
    RecordRepository<MealLog>? mealRepo,
    RecordRepository<Bowl>? bowlRepo,
    RecordRepository<Routine>? routineRepo,
    RecordRepository<Plant>? plantRepo,
    RecordRepository<DexEntry>? dexRepo,
    FriendRepository? friendRepo,
    ChallengeRepository? challengeRepo,
    ActivityFeedRepository? activityFeedRepo,
    AiConsentStore? aiConsentStore,
    MealAnalysisService? mealAnalysisService,
    MealRecommendationService? mealRecommendationService,
    DateTime Function()? now,
  }) : _aiConsentStore = aiConsentStore ?? MemoryAiConsentStore(),
       _auth = auth ?? MockAuthService(),
       _profiles = profiles ?? MemoryProfileRepository(),
       _waterViewModel =
           waterViewModel ??
           WaterViewModel(waterRepo: MemoryWaterRepository(), now: now),
       _weightViewModel =
           weightViewModel ??
           WeightViewModel(
             weightRepo: MemoryRecordRepository(weightCodec),
             now: now,
           ),
       _mealViewModel =
           mealViewModel ??
           MealViewModel(
             mealRepo: mealRepo ?? MemoryRecordRepository(mealCodec),
             now: now,
           ),
       _exerciseViewModel =
           exerciseViewModel ??
           ExerciseViewModel(
             exerciseRepo:
                 exerciseRepo ?? MemoryRecordRepository(exerciseCodec),
             now: now,
           ),
       _exerciseRepo = exerciseRepo ?? MemoryRecordRepository(exerciseCodec),
       _mealRepo = mealRepo ?? MemoryRecordRepository(mealCodec),
       _bowlViewModel =
           bowlViewModel ??
           BowlViewModel(
             bowlRepo: bowlRepo ?? MemoryRecordRepository(bowlCodec),
           ),
       _routineViewModel =
           routineViewModel ??
           RoutineViewModel(
             routineRepo: routineRepo ?? MemoryRecordRepository(routineCodec),
           ),
       _plantViewModel =
           plantViewModel ??
           PlantViewModel(
             plantRepo: plantRepo ?? MemoryRecordRepository(plantCodec),
             dexRepo: dexRepo ?? MemoryRecordRepository(dexEntryCodec),
           ),
       _photoAnalysisViewModel =
           photoAnalysisViewModel ??
           PhotoAnalysisViewModel(service: mealAnalysisService),
       _recommendationViewModel =
           recommendationViewModel ??
           RecommendationViewModel(service: mealRecommendationService),
       _friendViewModel =
           friendViewModel ??
           FriendViewModel(
             friendRepo: friendRepo ?? MemoryFriendRepository(),
             activityFeedRepo:
                 activityFeedRepo ?? MemoryActivityFeedRepository(),
             now: now,
           ),
       _challengeViewModel =
           challengeViewModel ??
           ChallengeViewModel(
             challengeRepo: challengeRepo ?? MemoryChallengeRepository(),
             now: now,
           ),
       _now = now ?? DateTime.now {
    // 식단 저장이 실패하면 예전처럼 화면에 알림을 띄운다.
    _exerciseViewModel.onSaveFailed = () {
      _notice = '운동 기록 저장에 실패했어요. 네트워크를 확인해 주세요.';
      notifyListeners();
    };
    _mealViewModel.onSaveFailed = () {
      _notice = '식단 기록 저장에 실패했어요. 네트워크를 확인해 주세요.';
      notifyListeners();
    };
    // 그릇 · 루틴은 화면이 AppState를 통해 구독하므로, ViewModel의 변경을 그대로 전달한다.
    void showNotice(String message) {
      _notice = message;
      notifyListeners();
    }

    _bowlViewModel
      ..onSyncFailed = showNotice
      ..addListener(notifyListeners);
    _routineViewModel
      ..onSyncFailed = showNotice
      ..addListener(notifyListeners);
    _plantViewModel
      ..onSyncFailed = showNotice
      ..addListener(notifyListeners);
    _photoAnalysisViewModel.addListener(notifyListeners);
    _recommendationViewModel.addListener(notifyListeners);
    // 친구와 챌린지는 서로의 사람 정보를 쓰고, 내 닉네임은 AppState가 갖고 있다.
    _friendViewModel
      ..nickname = (() => nickname)
      ..onSyncFailed = showNotice
      ..addListener(notifyListeners);
    _challengeViewModel
      ..userFor = _friendViewModel.userFor
      ..onSyncFailed = showNotice
      ..addListener(notifyListeners);
  }

  final AuthService _auth;
  final ProfileRepository _profiles;

  /// 물 기록은 이제 이 화면 전용 ViewModel이 갖고 있다 — AppState는 연속
  /// 기록 계산 · 오늘의 기록 요약 · 미션 진행도 계산에 필요할 때만 이걸
  /// 통해서 읽는다(물 데이터를 따로 복사해서 들고 있지 않는다).
  final WaterViewModel _waterViewModel;
  final WeightViewModel _weightViewModel;
  final ExerciseViewModel _exerciseViewModel;
  final MealViewModel _mealViewModel;
  final RecordRepository<ExerciseLog> _exerciseRepo;
  final RecordRepository<MealLog> _mealRepo;
  final BowlViewModel _bowlViewModel;
  final RoutineViewModel _routineViewModel;
  final PlantViewModel _plantViewModel;
  final PhotoAnalysisViewModel _photoAnalysisViewModel;

  /// 미션도 오늘의 기록을 읽어 계산하고, 수동 완료하면 식물 경험치를 올린다.
  late final MissionViewModel _missionViewModel = MissionViewModel(
    inputs: _missionInputs,
    gainExp: (exp) => _plantViewModel.gainExp(exp),
  )..addListener(notifyListeners);

  /// 리포트는 다른 ViewModel의 기록을 읽어 계산만 해서, AppState가 만들어진 뒤에 연결한다.
  late final ReportViewModel _reportViewModel = ReportViewModel(
    inputs: _reportInputs,
  )..addListener(notifyListeners);
  final RecommendationViewModel _recommendationViewModel;
  final FriendViewModel _friendViewModel;
  final ChallengeViewModel _challengeViewModel;

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
      // AI 추천은 동의한 뒤에만 자동으로 불러온다 (동의 전에는 화면의 버튼으로 요청).
      if (id == 'recommend' &&
          _recommendationViewModel.aiRecommendations == null &&
          aiConsent) {
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
  String nickname = '새싹';

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
    await loadAiConsent();
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
        // 웹 체험판(로그인 없는 데모)은 온보딩 없이 바로 홈의 예시 데이터를 보여준다.
        onboardingDone = kIsWeb && _isDemo;
        _resumeStep = 1;
        final name = a.displayName?.trim();
        if (name != null && name.isNotEmpty) nickname = name;
      }
      if (!_isDemo) await _loadAccountData(a.uid);
      unawaited(_applyNotificationSchedule());
      unawaited(_appIconService.setFilled(todayMeals.isNotEmpty));
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
    _mealViewModel.clear();
    _exerciseViewModel.clear();
    _bowlViewModel.clear();
    _routineViewModel.clear();
    _plantViewModel.clear(_uid);
    _friendViewModel.clear();
    _loadedMonths.clear();
  }

  void _resetPersonal() {
    if (!_isDemo) _clearSampleRecords();
    account = null;
    // 로그아웃한 뒤에는 어떤 ViewModel도 서버에 쓰지 않도록 계정 연결을 끊는다.
    _mealViewModel.uid = null;
    _exerciseViewModel.uid = null;
    _bowlViewModel.uid = null;
    _routineViewModel.uid = null;
    _plantViewModel.uid = null;
    _friendViewModel.uid = null;
    _challengeViewModel.uid = null;
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
    exerciseLogs: _exerciseViewModel.exercisesOn(_todayKey),
    weightEntry: _todayWeightEntry,
  );

  /// 오늘 저장한 가장 최근 체중 기록 (없으면 null)
  WeightEntry? get _todayWeightEntry {
    for (final w in _weightViewModel.weightEntries.reversed) {
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
  static const _nutrientColors = <String, Color>{
    '단백질': AppColor.primary,
    '탄수화물': AppColor.warn,
    '지방': AppColor.warnDeep,
    '식이섬유': AppColor.teal,
    '나트륨': AppColor.alert,
    '당류': Color(0xFFF48FB1),
    '칼슘': Color(0xFF90A4EE),
    '철분': Color(0xFFB08BE0),
  };

  double _sumMeals(double Function(MealLog) pick, [MealType? type]) =>
      todayMeals
          .where((m) => type == null || m.mealType == type)
          .fold(0.0, (a, m) => a + pick(m));

  /// 8종 영양소 오늘 합계 — 홈 카드(위 5개)와 영양소 상세 화면(전체)에서 같이 쓴다.
  List<NutrientStat> get todayNutrientStats => [
    for (final (:name, :unit, :target) in Nutrients.all)
      NutrientStat(
        name: name,
        unit: unit,
        target: target,
        color: _nutrientColors[name]!,
        value: _sumMeals(Nutrients.pick(name)),
        breakfast: _sumMeals(Nutrients.pick(name), MealType.breakfast),
        lunch: _sumMeals(Nutrients.pick(name), MealType.lunch),
        dinner: _sumMeals(Nutrients.pick(name), MealType.dinner),
        snack: _sumMeals(Nutrients.pick(name), MealType.snack),
      ),
  ];

  double get todayProteinG => _sumMeals(Nutrients.pick('단백질'));
  double get todayCarbG => _sumMeals(Nutrients.pick('탄수화물'));
  double get todayFatG => _sumMeals(Nutrients.pick('지방'));

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
  // 오늘의 미션 뽑기 · 진행도 · 수동 완료는 MissionViewModel이 맡는다. 화면이 예전처럼
  // s.missions 같은 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  List<Mission> get missions => _missionViewModel.missions;

  /// 미션 카테고리 필터 — 전체/식단/운동/생활/꾸준함
  String get missionFilterTab => _missionViewModel.missionFilterTab;
  void setMissionFilterTab(String t) =>
      _missionViewModel.setMissionFilterTab(t);

  bool missionEffectivelyDone(Mission m) =>
      _missionViewModel.missionEffectivelyDone(m);
  void completeMissionManually(Mission m) =>
      _missionViewModel.completeMissionManually(m);
  int get missionDone => _missionViewModel.missionDone;
  int get missionExp => _missionViewModel.missionExp;

  /// 미션 진행도 계산에 쓸 오늘의 기록 — 부를 때마다 최신 값으로 만든다.
  MissionInputs _missionInputs() => MissionInputs(
    uid: _uid,
    todayKey: _todayKey,
    mealsToday: todayMeals.length,
    exerciseMinutesToday: todayExerciseMinutes,
    waterMl: waterTotal,
    streakDays: streakDays,
  );

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
  int get baseKcal => _photoAnalysisViewModel.baseKcal;

  final AppIconService _appIconService = AppIconService();
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

  // 사진 분석 — 사진 고르기 · AI 분석 · 분석 결과는 PhotoAnalysisViewModel이 맡는다.
  // 화면이 예전처럼 s.aiMealName 같은 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  bool get analyzingPhoto => _photoAnalysisViewModel.analyzingPhoto;
  String? get photoAnalysisError => _photoAnalysisViewModel.photoAnalysisError;

  /// 방금 찍거나 고른 사진 원본 — 화면에 실제로 보여주는 용도.
  Uint8List? get pickedPhotoBytes => _photoAnalysisViewModel.pickedPhotoBytes;
  String? get aiMealName => _photoAnalysisViewModel.aiMealName;
  double? get aiProteinG => _photoAnalysisViewModel.aiProteinG;
  double? get aiCarbG => _photoAnalysisViewModel.aiCarbG;
  double? get aiFatG => _photoAnalysisViewModel.aiFatG;
  double? get aiFiberG => _photoAnalysisViewModel.aiFiberG;
  double? get aiSodiumMg => _photoAnalysisViewModel.aiSodiumMg;
  double? get aiSugarG => _photoAnalysisViewModel.aiSugarG;
  double? get aiCalciumMg => _photoAnalysisViewModel.aiCalciumMg;
  double? get aiIronMg => _photoAnalysisViewModel.aiIronMg;
  bool get needsPhotoReview => _photoAnalysisViewModel.needsPhotoReview;

  // 외부 AI로 데이터를 보내는 기능(사진 분석 · 식단 추천)을 쓰기 전에 받는 동의.
  final AiConsentStore _aiConsentStore;
  bool aiConsent = false;

  Future<void> loadAiConsent() async {
    aiConsent = await _aiConsentStore.read();
    notifyListeners();
  }

  Future<void> setAiConsent(bool value) async {
    aiConsent = value;
    notifyListeners();
    await _aiConsentStore.write(value);
  }

  /// 사진을 고르고 즉시 AI 분석을 요청한다 (지금 고른 그릇을 함께 알려 준다).
  Future<void> pickAndAnalyzeMealPhoto(ImageSource source) =>
      _photoAnalysisViewModel.pickAndAnalyze(source, bowl: currentBowl);

  /// 지금 선택된 그릇 — 등록한 그릇이 하나도 없으면 null (그릇 없이도 기록할 수 있다).
  Bowl? get currentBowl => _bowlViewModel.currentBowl;

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
    '운동': _exerciseViewModel.exercisesOn(_selectedKey).isNotEmpty,
    '체중': _viewingToday && _weightViewModel.weightEntries.isNotEmpty,
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
    return _mealViewModel.mealLogs.any((m) => m.dateKey == key) ||
        _exerciseViewModel.exerciseLogs.any((e) => e.dateKey == key) ||
        _weightViewModel.weightEntries.any((w) => w.dateKey == key) ||
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

  /// 기록 탭에서 지금 보고 있는 날짜(month/day)의 식단.
  List<MealLog> get meals => _mealViewModel.mealsOn(_selectedKey);

  /// 지금 보고 있는 날짜의 총 섭취 칼로리.
  int get selectedDayKcal => meals.fold(0, (a, m) => a + m.kcal);

  /// 홈 화면 "오늘 섭취" 계산에 쓰는, 고정된 오늘 날짜의 식단.
  List<MealLog> get todayMeals => _mealViewModel.mealsOn(_todayKey);

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
    _mealViewModel.addMeal(log); // 목록 추가 + 서버 저장은 ViewModel이 한다
    // 이번 분석 결과는 이 기록에 다 썼다 — 다음 끼니를 새 사진 없이 저장하면
    // 방금 분석값을 재사용하지 않고 0(분석 안 함)으로 시작하게 비워준다.
    _photoAnalysisViewModel.reset();
    notifyListeners();
    _friendViewModel.postActivity('${log.mealType.label} 식단을 기록했어요');
    _challengeViewModel.reportProgress(
      ChallengeType.mealRecord,
      todayMeals.length,
    );
    _challengeViewModel.reportProgress(ChallengeType.protein, todayProteinG);
    unawaited(_appIconService.setFilled(true));
  }

  /// 상세 화면에서 보여줄 식단 — id로 참조한다.
  String? detailMealId;

  MealLog? get detailMeal => _mealViewModel.mealById(detailMealId);

  void openMeal(MealLog m) {
    detailMealId = m.id;
    go('mealDetail');
  }

  // 운동
  //
  // 입력값(Draft) · 저장된 운동 기록 · 칼로리 계산은 ExerciseViewModel이 맡는다.
  // 화면이 예전처럼 s.exType 같은 이름으로 쓸 수 있게, 같은 이름의 getter/setter로 전달만 한다.
  ExerciseDraft get exerciseDraft => _exerciseViewModel.exerciseDraft;

  String get exType => _exerciseViewModel.exType;
  set exType(String value) => _exerciseViewModel.exType = value;

  int get exMinutes => _exerciseViewModel.exMinutes;
  set exMinutes(int value) => _exerciseViewModel.exMinutes = value;

  String get exIntensity => _exerciseViewModel.exIntensity;
  set exIntensity(String value) => _exerciseViewModel.exIntensity = value;

  bool get exTypeKnown => _exerciseViewModel.exTypeKnown;
  int get exKcal => _exerciseViewModel.exKcal;

  /// 홈 · 미션에서 쓰는, 고정된 오늘 날짜의 운동 시간 합계.
  int get todayExerciseMinutes => _exerciseViewModel.minutesOn(_todayKey);

  /// 지금 입력값으로 실제 운동 기록을 저장한다.
  void logExercise() {
    final log = _exerciseViewModel.logFromDraft(dateKey: _selectedKey);
    _exerciseViewModel.addExercise(log); // 목록 추가 + 서버 저장은 ViewModel이 한다
    notifyListeners();
    _friendViewModel.postActivity('$exType $exMinutes분 운동했어요');
    _challengeViewModel.reportProgress(
      ChallengeType.exercise,
      todayExerciseMinutes,
    );
  }

  // 내 루틴 — 목록 · 저장은 RoutineViewModel이 맡는다.
  List<Routine> get routines => _routineViewModel.routines;
  bool get routineEditMode => _routineViewModel.routineEditMode;
  void toggleRoutineEditMode() => _routineViewModel.toggleRoutineEditMode();

  /// 루틴을 운동 입력값에 채운다 (운동 입력값은 ExerciseViewModel 소유).
  void loadRoutine(Routine r) {
    exType = r.type;
    exMinutes = r.minutes;
    exerciseDraft.intensity = r.intensity;
    notifyListeners();
  }

  /// 지금 운동 입력값을 새 루틴으로 저장한다.
  void saveCurrentAsRoutine() => _routineViewModel.addRoutine(
    type: exType,
    minutes: exMinutes,
    intensity: exerciseDraft.intensity,
  );

  void removeRoutine(Routine r) => _routineViewModel.removeRoutine(r);

  // 체중

  /// 체중 화면 "최근 7일" — 오래된 날부터 오늘까지, 그날 마지막으로 기록한
  /// 체중(기록이 없는 날은 kg가 null).
  List<({int day, double? kg, bool isToday})> get recentWeightDays {
    final entries = _weightViewModel.weightEntries;
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final d = DateTime(today.year, today.month, today.day - i);
          final key = dateKeyOf(d);
          double? kg;
          for (final w in entries) {
            if (w.dateKey == key) kg = w.kg;
          }
          return (day: d.day, kg: kg, isToday: i == 0);
        }(),
    ];
  }

  /// 지금까지 저장한 체중 기록 횟수.
  int get weightRecordCount => _weightViewModel.weightEntries.length;

  /// 기록 탭 요약 카드에 쓰는, 가장 최근에 저장한 체중.
  double get latestWeightKg =>
      _weightViewModel.latestWeightKg ?? profile.weightKg;

  void onWeightLogged(double kg) {
    profile.weightKg = kg;
    unawaited(_persistInBackground());
  }

  // 물
  bool waterSheet = false;

  String get _uid => account?.uid ?? User.meId;

  int get waterTotal => _waterViewModel.waterTotal;
  int get waterLeft => _waterViewModel.waterLeft;
  int get waterPct => _waterViewModel.waterPct;

  /// WaterViewModel.addWater()는 화면 전용이라 다른 기능(활동 피드 ·
  /// 챌린지 진행도)을 모른다 — 물을 기록한 뒤 이 메서드도 함께 불러서
  /// 그 연결을 이어준다.
  void onWaterAdded(int ml) {
    _friendViewModel.postActivity('물 ${AppStateFormat.comma(ml)}ml을 기록했어요');
    _challengeViewModel.reportProgress(
      ChallengeType.water,
      _waterViewModel.waterTotal,
    );
  }

  // 계정에 저장되는 기록들 (체중 · 운동 · 식단 · 그릇 · 루틴 · 식물)

  final Set<String> _loadedMonths = {};

  Future<void> _loadAccountData(String uid) async {
    _mealViewModel.uid = uid;
    _exerciseViewModel.uid = uid;
    final prev = DateTime(today.year, today.month - 1, 1);
    await Future.wait([
      _waterViewModel.loadForUid(uid),
      _weightViewModel.loadForUid(uid, fallbackKg: profile.weightKg),
      _loadTemplates(uid),
      _plantViewModel.loadForUid(uid),
      _friendViewModel.loadForUid(uid),
      _challengeViewModel.loadForUid(uid),
      _loadMonth(today.year, today.month),
      _loadMonth(prev.year, prev.month), // 연속 기록을 세려면 지난달 끝도 필요하다
    ]);
  }

  /// 저장된 수집 상태를 불러온다. 처음 가입한 계정(저장된 게 없음)은
  /// 전부 미획득 상태로 시작하고, 그 상태를 그대로 저장해 다음부터는
  /// 다시 만들지 않는다.
  Future<void> _loadTemplates(String uid) async {
    final results = await Future.wait([
      _bowlViewModel.loadForUid(uid),
      _routineViewModel.loadForUid(uid),
    ]);
    if (results.contains(false)) {
      _notice = '그릇과 운동 루틴을 불러오지 못했어요.';
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
      _mealViewModel.mergeLoaded(meals);
      _exerciseViewModel.mergeLoaded(workouts);
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
      _weightViewModel.deleteAll(uid),
      _exerciseRepo.deleteAll(uid),
      _mealRepo.deleteAll(uid),
      _bowlViewModel.deleteAll(uid),
      _routineViewModel.deleteAll(uid),
      _plantViewModel.deleteAll(uid),
      // 친구 · 챌린지 · 활동 피드는 다른 사용자와 함께 쓰는 공간이라 따로 지운다.
      _friendViewModel.deleteAll(uid),
      _challengeViewModel.deleteAll(uid),
    ]).timeout(limit);
    await _profiles.delete(uid).timeout(limit);
  }

  // 그릇
  //
  // 그릇 목록 · 입력 상태 · 저장은 BowlViewModel이 맡는다. 화면이 예전처럼
  // s.bowls 같은 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  bool get bowlSheet => _bowlViewModel.bowlSheet;
  set bowlSheet(bool value) => _bowlViewModel.bowlSheet = value;

  int? get bowlEditing => _bowlViewModel.bowlEditing;
  set bowlEditing(int? value) => _bowlViewModel.bowlEditing = value;

  int get bowlIndex => _bowlViewModel.bowlIndex;
  set bowlIndex(int value) => _bowlViewModel.bowlIndex = value;

  List<Bowl> get bowls => _bowlViewModel.bowls;
  Bowl get draftBowl => _bowlViewModel.draftBowl;

  void startAddBowl() => _bowlViewModel.startAddBowl();
  void startEditBowl(int i) => _bowlViewModel.startEditBowl(i);
  void cancelBowlEdit() => _bowlViewModel.cancelBowlEdit();
  bool saveBowl() => _bowlViewModel.saveBowl();
  void removeBowl(int i) => _bowlViewModel.removeBowl(i);

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
  // 성장 상태 · 저장 · 도감 수집 현황은 PlantViewModel이 맡는다. 화면이 예전처럼
  // s.plantLevel 같은 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  Plant get plant => _plantViewModel.plant;

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

  void care(String name) => _plantViewModel.care(name);
  void revive() => _plantViewModel.revive();
  void waterFriend(String friendUserId) =>
      _plantViewModel.waterFriend(friendUserId);
  void useInventoryItem(String key) => _plantViewModel.useInventoryItem(key);
  void sendGiftFlower() => _plantViewModel.sendGiftFlower();

  // 도감
  String get dexTab => _plantViewModel.dexTab;
  int get dexPick => _plantViewModel.dexPick;
  List<DexEntry> get dexEntries => _plantViewModel.dexEntries;

  /// 모두가 공유하는 도감 베이스 카탈로그.
  static List<PlantSpecies> get dexBase => PlantSpecies.catalog;

  int get dexTotal => _plantViewModel.dexTotal;
  int get dexOwned => _plantViewModel.dexOwned;
  int get dexPct => _plantViewModel.dexPct;
  ({int own, int all}) dexTierCount(String tier) =>
      _plantViewModel.dexTierCount(tier);
  List<DexCard> get dexFiltered => _plantViewModel.dexFiltered;
  DexCard get dexSelected => _plantViewModel.dexSelected;
  void setDexTab(String t) => _plantViewModel.setDexTab(t);
  void setDexPick(DexCard c) => _plantViewModel.setDexPick(c);

  // 식단 추천
  //
  // 추천 조건 · 결과는 RecommendationViewModel이 맡는다. 화면이 예전처럼
  // s.recMeal 같은 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  List<String> get needs => _recommendationViewModel.needs;
  String get recMeal => _recommendationViewModel.recMeal;
  List<String> get recPrefs => _recommendationViewModel.recPrefs;
  int get recMaxKcal => _recommendationViewModel.recMaxKcal;
  String get recSort => _recommendationViewModel.recSort;
  static const needOptions = RecommendationViewModel.needOptions;

  List<AiMealSuggestion>? get aiRecommendations =>
      _recommendationViewModel.aiRecommendations;
  bool get loadingRecommendations =>
      _recommendationViewModel.loadingRecommendations;
  String? get recommendationError =>
      _recommendationViewModel.recommendationError;
  Future<void> fetchAiRecommendations() =>
      _recommendationViewModel.fetchAiRecommendations();
  List<({MealSuggestion meal, int score, bool offMeal})> get recommendations =>
      _recommendationViewModel.recommendations;

  void toggleNeed(String n) => _recommendationViewModel.toggleNeed(n);
  void togglePref(String p) => _recommendationViewModel.togglePref(p);
  void setRecMeal(String m) => _recommendationViewModel.setRecMeal(m);
  void setRecMaxKcal(int v) => _recommendationViewModel.setRecMaxKcal(v);
  void setRecSort(String s) => _recommendationViewModel.setRecSort(s);

  // 리포트
  //
  // 주간 · 월간 집계는 ReportViewModel이 맡는다. 화면이 예전처럼 s.kcalBars 같은
  // 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  String get period => _reportViewModel.period;
  set period(String value) => _reportViewModel.period = value;
  void setPeriod(String p) => _reportViewModel.setPeriod(p);

  List<({String label, int value, int pct})> get kcalBars =>
      _reportViewModel.kcalBars;
  List<({String label, double kg})> get weightSeries =>
      _reportViewModel.weightSeries;
  String get avgKcal => _reportViewModel.avgKcal;
  String get periodDelta => _reportViewModel.periodDelta;
  int get avgExerciseMin => _reportViewModel.avgExerciseMin;
  int get exerciseMinDelta => _reportViewModel.exerciseMinDelta;
  int get achieveRate => _reportViewModel.achieveRate;
  int get recordDays => _reportViewModel.recordDays;
  int get recordGoalDays => _reportViewModel.recordGoalDays;
  String get mostEatenFood => _reportViewModel.mostEatenFood;
  String get mostUsedBowl => _reportViewModel.mostUsedBowl;
  String get mostUsedSauce => _reportViewModel.mostUsedSauce;
  String get lackingNutrient => _reportViewModel.lackingNutrient;
  String get recommendedMeal => _reportViewModel.recommendedMeal;

  /// 리포트가 집계에 쓸 기록 — 부를 때마다 최신 값으로 만든다.
  ReportInputs _reportInputs() => ReportInputs(
    today: today,
    meals: _mealViewModel.mealLogs,
    exercises: _exerciseViewModel.exerciseLogs,
    weights: _weightViewModel.weightEntries,
    fallbackWeightKg: profile.weightKg,
    dailyTarget: dailyTarget,
    bowls: bowls,
    hasRecordOn: hasRecordOn,
  );

  // 친구 · 챌린지
  //
  // 친구(목록 · 요청 · 검색 · 활동 피드)는 FriendViewModel이, 챌린지(목록 · 순위 ·
  // 만들기 폼)는 ChallengeViewModel이 맡는다. 화면이 예전처럼 s.realFriends,
  // s.challenges 같은 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  // 공개 범위 설정은 계정과 함께 저장되는 값이라 AppState가 갖고 있다.

  static const List<User> people = FriendViewModel.people;
  static User personById(String id) => FriendViewModel.personById(id);

  User get currentUser => _friendViewModel.currentUser;
  List<String> get addedFriends => _friendViewModel.addedFriends;
  void addFriend(String userId) => _friendViewModel.addFriend(userId);

  String get inviteCode => _friendViewModel.inviteCode;
  List<PublicProfile> get realFriends => _friendViewModel.realFriends;
  List<ActivityFeedEntry> get realActivityFeed =>
      _friendViewModel.realActivityFeed;
  List<FriendRequest> get incomingFriendRequests =>
      _friendViewModel.incomingFriendRequests;
  Map<String, PublicProfile> get requesterProfiles =>
      _friendViewModel.requesterProfiles;
  PublicProfile? get friendSearchResult => _friendViewModel.friendSearchResult;
  bool get friendSearchNotFound => _friendViewModel.friendSearchNotFound;
  String get friendSearchQuery => _friendViewModel.friendSearchQuery;

  void setFriendSearchQuery(String v) =>
      _friendViewModel.setFriendSearchQuery(v);
  Future<void> searchFriendByCode() => _friendViewModel.searchFriendByCode();
  Future<void> sendFriendRequestToSearchResult() =>
      _friendViewModel.sendFriendRequestToSearchResult();
  Future<void> acceptFriendRequest(FriendRequest request) =>
      _friendViewModel.acceptFriendRequest(request);
  Future<void> declineFriendRequest(FriendRequest request) =>
      _friendViewModel.declineFriendRequest(request);
  List<({User user, String desc})> get suggestedFriends =>
      _friendViewModel.suggestedFriends;

  List<({User user, String activity, String time})> get friendActivity =>
      _friendViewModel.friendActivity;
  Set<String> get cheeredFriends => _friendViewModel.cheeredFriends;
  void cheerFriend(String userId) => _friendViewModel.cheerFriend(userId);

  // 챌린지
  List<Challenge> get challenges => _challengeViewModel.challenges;
  List<Challenge> get joinableChallenges =>
      _challengeViewModel.joinableChallenges;
  List<Challenge> get myChallenges => _challengeViewModel.myChallenges;
  Future<void> joinChallenge(String challengeId) =>
      _challengeViewModel.joinChallenge(challengeId);

  String get activeChallengeName => _challengeViewModel.activeChallengeName;
  String get activeChallengePeriod => _challengeViewModel.activeChallengePeriod;
  List<({User user, double ratio})> get activeChallengeProgress =>
      _challengeViewModel.activeChallengeProgress;
  int get myChallengeRank => _challengeViewModel.myChallengeRank;
  List<({int rank, User user, int pct})> get challengeLeaderboard =>
      _challengeViewModel.challengeLeaderboard;
  static const challengeRewardTiers = ChallengeViewModel.challengeRewardTiers;

  // 챌린지 만들기 폼
  ChallengeDraft get challengeDraft => _challengeViewModel.challengeDraft;

  String get chKind => _challengeViewModel.chKind;
  set chKind(String value) => _challengeViewModel.chKind = value;
  int get chTarget => _challengeViewModel.chTarget;
  set chTarget(int value) => _challengeViewModel.chTarget = value;
  int get chDays => _challengeViewModel.chDays;
  set chDays(int value) => _challengeViewModel.chDays = value;
  List<String> get chInvites => _challengeViewModel.chInvites;
  bool get chPublic => _challengeViewModel.chPublic;
  set chPublic(bool value) => _challengeViewModel.chPublic = value;
  String get chReward => _challengeViewModel.chReward;
  set chReward(String value) => _challengeViewModel.chReward = value;

  static const chKindMeta = ChallengeViewModel.chKindMeta;
  String get chUnit => _challengeViewModel.chUnit;
  String get chDurLabel => _challengeViewModel.chDurLabel;
  String get chName => _challengeViewModel.chName;
  String get chRange => _challengeViewModel.chRange;
  String get chRewardDesc => _challengeViewModel.chRewardDesc;
  String get chPreview => _challengeViewModel.chPreview;

  void setChKind(String k) => _challengeViewModel.setChKind(k);
  void setChTarget(int v) => _challengeViewModel.setChTarget(v);
  void setChDays(int v) => _challengeViewModel.setChDays(v);
  void toggleChInvite(String n) => _challengeViewModel.toggleChInvite(n);
  void setChPublic(bool v) => _challengeViewModel.setChPublic(v);
  void setChReward(String r) => _challengeViewModel.setChReward(r);

  /// 챌린지를 만들고 챌린지 탭으로 이동한다. 화면 이동은 저장을 기다리지 않는다.
  Future<void> createChallenge() {
    final saving = _challengeViewModel.createChallenge();
    friendTab = '챌린지';
    screen = 'friends';
    notifyListeners();
    return saving;
  }

  final PrivacySettings privacySettings = PrivacySettings(userId: User.meId);

  String get shareScope => privacySettings.scope.label;
  set shareScope(String value) => privacySettings.scope = value == '비공개'
      ? ShareScope.private
      : ShareScope.friends;

  void setFriendTab(String t) {
    friendTab = t;
    notifyListeners();
  }

  void setShareScope(String s) {
    shareScope = s;
    notifyListeners();
    unawaited(_persistInBackground());
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
