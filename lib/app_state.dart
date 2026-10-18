// 앱 전역 상태 — 프로토타입의 Component.state를 그대로 옮긴 ChangeNotifier.
//
// 화면 전환도 여기서 관리합니다 (Navigator 대신 screen 문자열).
// 통합된 화면은 부모 screen + 서브 모드 플래그로 표현합니다.

import 'package:diet_project/ui/growth/viewmodel/plant_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/ai_consent_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/mission_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/notification_inbox_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/recommendation_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/today_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/today_summary.dart';
import 'package:diet_project/ui/onboarding/viewmodel/auth_view_model.dart';
import 'package:diet_project/ui/onboarding/viewmodel/profile_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/bowl_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/exercise_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/meal_draft_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/meal_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/photo_analysis_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/records_view_model.dart';
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
import 'package:flutter/material.dart' show Offset;
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data/auth/auth_service.dart';

export 'package:diet_project/domain/models/models.dart';
export 'package:diet_project/ui/home/viewmodel/today_summary.dart'
    show NutrientStat;

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
    AuthViewModel? authViewModel,
    ProfileViewModel? profileViewModel,
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
  }) : _aiConsentViewModel = AiConsentViewModel(
         store: aiConsentStore ?? MemoryAiConsentStore(),
       ),
       _notificationInboxViewModel = NotificationInboxViewModel(),
       _authViewModel =
           authViewModel ?? AuthViewModel(auth: auth ?? MockAuthService()),
       _profileViewModel =
           profileViewModel ??
           ProfileViewModel(profiles: profiles ?? MemoryProfileRepository()),
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
    // 저장·불러오기에 실패하면 화면 밖 안내(스낵바)로 알린다. 화면은 필요한 ViewModel을 직접 구독한다.
    void showNotice(String message) {
      _notice = message;
      notifyListeners();
    }

    _bowlViewModel.onSyncFailed = showNotice;
    _routineViewModel.onSyncFailed = showNotice;
    _plantViewModel.onSyncFailed = showNotice;
    _mealDraftViewModel.inputs = (() => MealDraftInputs(
      baseKcal: _photoAnalysisViewModel.baseKcal,
      bowl: _bowlViewModel.currentBowl,
    ));
    Listenable.merge([
      _photoAnalysisViewModel,
      _bowlViewModel,
    ]).addListener(_mealDraftViewModel.refresh);
    // 미션과 리포트는 여러 기록에서 값을 계산하므로, 그 기록이 바뀌면 다시 계산하게 알린다.
    final sources = Listenable.merge([
      _mealViewModel,
      _exerciseViewModel,
      _weightViewModel,
      _waterViewModel,
      _profileViewModel,
    ]);
    sources.addListener(_missionViewModel.refresh);
    sources.addListener(_reportViewModel.refresh);
    sources.addListener(_recordsViewModel.refresh);
    sources.addListener(_todayViewModel.refresh);
    _profileViewModel.onSyncFailed = showNotice;
    // 친구와 챌린지는 서로의 사람 정보를 쓰고, 내 닉네임은 AppState가 갖고 있다.
    _friendViewModel
      ..nickname = (() => nickname)
      ..onSyncFailed = showNotice;
    _challengeViewModel
      ..userFor = _friendViewModel.userFor
      ..onSyncFailed = showNotice;
  }

  // 화면이 필요한 ViewModel을 직접 구독할 수 있도록 밖으로 내놓는다 (AppProviders 참고).
  // AppState는 이것들을 만들고 서로 연결하는 일을 맡는다.
  AuthViewModel get authViewModel => _authViewModel;
  AiConsentViewModel get aiConsentViewModel => _aiConsentViewModel;
  NotificationInboxViewModel get notificationInboxViewModel =>
      _notificationInboxViewModel;
  ProfileViewModel get profileViewModel => _profileViewModel;
  WaterViewModel get waterViewModel => _waterViewModel;
  WeightViewModel get weightViewModel => _weightViewModel;
  ExerciseViewModel get exerciseViewModel => _exerciseViewModel;
  MealViewModel get mealViewModel => _mealViewModel;
  MealDraftViewModel get mealDraftViewModel => _mealDraftViewModel;
  BowlViewModel get bowlViewModel => _bowlViewModel;
  RoutineViewModel get routineViewModel => _routineViewModel;
  PlantViewModel get plantViewModel => _plantViewModel;
  PhotoAnalysisViewModel get photoAnalysisViewModel => _photoAnalysisViewModel;
  MissionViewModel get missionViewModel => _missionViewModel;
  RecordsViewModel get recordsViewModel => _recordsViewModel;
  TodayViewModel get todayViewModel => _todayViewModel;
  ReportViewModel get reportViewModel => _reportViewModel;
  RecommendationViewModel get recommendationViewModel =>
      _recommendationViewModel;
  FriendViewModel get friendViewModel => _friendViewModel;
  ChallengeViewModel get challengeViewModel => _challengeViewModel;

  final AuthViewModel _authViewModel;
  final MealDraftViewModel _mealDraftViewModel = MealDraftViewModel();
  final AiConsentViewModel _aiConsentViewModel;
  final NotificationInboxViewModel _notificationInboxViewModel;
  final ProfileViewModel _profileViewModel;

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

  /// 기록 탭의 달력과 "기록한 날" 계산, 홈의 오늘 수치 — 둘 다 기록을 읽어 계산만 한다.
  late final RecordsViewModel _recordsViewModel = RecordsViewModel(
    snapshot: _recordsSnapshot,
    now: _now,
    onViewedMonthChanged: (y, m) =>
        unawaited(_loadMonth(y, m).then((_) => notifyListeners())),
  );
  late final TodayViewModel _todayViewModel = TodayViewModel(
    snapshot: _recordsSnapshot,
    now: _now,
  );

  RecordsSnapshot _recordsSnapshot() => RecordsSnapshot(
    meals: _mealViewModel.mealLogs,
    exercises: _exerciseViewModel.exerciseLogs,
    weights: _weightViewModel.weightEntries,
    waterEntries: _waterViewModel.waterEntries,
    mealsOn: _mealViewModel.mealsOn,
    exercisesOn: _exerciseViewModel.exercisesOn,
    dailyTarget: dailyTarget,
    profileWeightKg: profile.weightKg,
    latestLoggedWeightKg: _weightViewModel.latestWeightKg,
    mealById: _mealViewModel.mealById,
  );

  /// 미션도 오늘의 기록을 읽어 계산하고, 수동 완료하면 식물 경험치를 올린다.
  late final MissionViewModel _missionViewModel = MissionViewModel(
    inputs: _missionInputs,
    gainExp: (exp) => _plantViewModel.gainExp(exp),
  );

  /// 리포트는 다른 ViewModel의 기록을 읽어 계산만 해서, AppState가 만들어진 뒤에 연결한다.
  late final ReportViewModel _reportViewModel = ReportViewModel(
    inputs: _reportInputs,
  );
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

  // 오늘 날짜 — 날짜 문구와 오늘의 기록 요약은 TodayViewModel이 맡는다.
  static String dateKeyOf(DateTime d) => RecordsViewModel.dateKeyOf(d);

  /// 오늘 (시간은 버리고 날짜만)
  DateTime get today => _todayViewModel.today;

  int get todayYear => today.year;
  int get todayMonth => today.month;
  int get todayDay => today.day;

  String get _todayKey => _todayViewModel.todayKey;
  String get _selectedKey => _recordsViewModel.selectedKey;

  /// 예: "9월 21일"
  String get todayDateLabel => _todayViewModel.todayDateLabel;

  /// 예: "9월 21일 월요일"
  String get todayLabel => _todayViewModel.todayLabel;

  // 인증 · 온보딩
  String get provider => _authViewModel.provider;
  set provider(String value) => _authViewModel.provider = value;

  /// 로그인한 계정 (로그인 전에는 null). 바뀌면 내 정보 저장 대상도 함께 바뀐다.
  AuthAccount? get account => _authViewModel.account;
  set account(AuthAccount? value) {
    _authViewModel.account = value;
    _profileViewModel.uid = value?.uid;
  }

  // 로그인 · 로그아웃 · 계정 삭제의 진행 상태와 실패 문구는 AuthViewModel이 맡는다.
  // 로그인한 뒤 무엇을 불러오고 로그아웃 · 삭제 뒤 무엇을 비우는지는 여기서 정한다.
  bool get signingIn => _authViewModel.signingIn;

  /// 계정 삭제가 진행 중인 동안 true — 버튼 중복 탭을 막는다.
  bool get deleting => _authViewModel.deleting;

  /// 마지막 로그인 · 계정 삭제 실패 문구 (화면이 토스트로 보여주고 비운다)
  String? get authError => _authViewModel.authError;
  set authError(String? value) => _authViewModel.authError = value;

  /// 성공 true, 취소 false, 실패 false + authError.
  Future<bool> signIn(LoginProvider p) =>
      _authViewModel.signIn(p, enter: _enter);

  /// 앱을 켤 때 호출 — 로그인 · 온보딩 완료 여부에 따라 알맞은 화면으로 보낸다.
  Future<bool> restoreSession() async {
    await loadAiConsent();
    final current = await _authViewModel.restoreAccount();
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
    step = _profileViewModel.resumeStep;
    notifyListeners();
  }

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
    await _profileViewModel.persistAndReport();
  }

  /// 로그인한 계정의 저장된 프로필을 불러와 반영한다. 없으면 계정 이름을 닉네임으로 쓴다.
  Future<bool> _enter(AuthAccount a) async {
    try {
      // 웹 체험판(로그인 없는 데모)은 온보딩 없이 바로 홈의 예시 데이터를 보여준다.
      await _profileViewModel.loadFor(
        a,
        skipOnboardingForNewAccount: kIsWeb && _isDemo,
      );
      account = a;
      provider = a.provider.label;
      if (!_isDemo) _clearSampleRecords();
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
    if (await _profileViewModel.persist()) return true;
    authError = _profileViewModel.saveError;
    return false;
  }

  /// 가짜 로그인(Mock)일 때만 true — 이때는 예시 기록을 그대로 보여준다.
  bool get _isDemo => _authViewModel.isDemo;

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
    _profileViewModel.reset();
  }

  Future<void> signOut() async {
    await _authViewModel.signOut();
    _resetPersonal();
    _notice = '로그아웃했어요.';
    go('login');
  }

  /// 계정 삭제에 성공하면 true, 실패하면 false(authError에 사용자용 문구).
  Future<bool> deleteAccount() => _authViewModel.deleteAccount(
    uid: account?.uid,
    deleteUserData: _deleteAllUserData,
    afterDelete: () {
      _resetPersonal();
      _notice = '계정과 저장된 정보를 모두 삭제했어요.';
      go('login');
    },
  );

  // 내 정보 — 닉네임 · 신체 정보와 목표 · 약관 · 알림 · 공개 범위 · 온보딩 진행 상황은
  // ProfileViewModel이 맡는다. 화면이 예전처럼 s.nickname 같은 이름으로 쓸 수 있게,
  // 같은 이름으로 전달만 한다.
  String get nickname => _profileViewModel.nickname;
  set nickname(String value) => _profileViewModel.nickname = value;

  /// 1 계정연결 / 2 목표 / 3 신체 / 4 알림
  int get step => _profileViewModel.step;
  set step(int value) => _profileViewModel.step = value;

  bool get onboardingDone => _profileViewModel.onboardingDone;
  set onboardingDone(bool value) => _profileViewModel.onboardingDone = value;

  Map<String, bool> get terms => _profileViewModel.terms;
  bool get requiredTermsOk => _profileViewModel.requiredTermsOk;
  void toggleTerm(String k) => _profileViewModel.toggleTerm(k);
  void toggleAllTerms() => _profileViewModel.toggleAllTerms();

  UserProfile get profile => _profileViewModel.profile;
  set profile(UserProfile value) => _profileViewModel.profile = value;

  String get goal => _profileViewModel.goal;
  set goal(String v) => _profileViewModel.goal = v;

  String get activity => _profileViewModel.activity;
  set activity(String v) => _profileViewModel.activity = v;

  String get gender => _profileViewModel.gender;
  set gender(String v) => _profileViewModel.gender = v;

  double get heightCm => _profileViewModel.heightCm;
  set heightCm(double v) => _profileViewModel.heightCm = v;

  double get weightKg => _profileViewModel.weightKg;
  set weightKg(double v) => _profileViewModel.weightKg = v;

  int get age => _profileViewModel.age;
  set age(int v) => _profileViewModel.age = v;

  double get goalWeight => _profileViewModel.goalWeight;
  set goalWeight(double v) => _profileViewModel.goalWeight = v;

  NotificationSettings get notificationSettings =>
      _profileViewModel.notificationSettings;
  Map<String, bool> get onboardAlerts => _profileViewModel.onboardAlerts;
  void toggleOnboardAlert(String label) =>
      _profileViewModel.toggleOnboardAlert(label);

  double get bmi => _profileViewModel.bmi;
  double get bmr => _profileViewModel.bmr;
  int get dailyTarget => _profileViewModel.dailyTarget;
  String get goalDelta => _profileViewModel.goalDelta;

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

  // 오늘 수치 — 먹은 칼로리 · 영양소 합계 · 오늘 운동 시간 · 가장 최근 체중은
  // TodayViewModel이 맡는다. 화면이 예전처럼 s.intakeKcal 같은 이름으로 쓸 수 있게,
  // 같은 이름으로 전달만 한다.
  int get intakeKcal => _todayViewModel.intakeKcal;
  int get remainKcal => _todayViewModel.remainKcal;
  double get intakeRatio => _todayViewModel.intakeRatio;

  List<NutrientStat> get todayNutrientStats =>
      _todayViewModel.todayNutrientStats;
  double get todayProteinG => _todayViewModel.todayProteinG;
  double get todayCarbG => _todayViewModel.todayCarbG;
  double get todayFatG => _todayViewModel.todayFatG;
  ({int proteinPct, int carbPct, int fatPct}) get macroRatio =>
      _todayViewModel.macroRatio;

  /// 홈 화면 "오늘 섭취" 계산에 쓰는, 고정된 오늘 날짜의 식단.
  List<MealLog> get todayMeals => _todayViewModel.todayMeals;

  /// 홈 · 미션에서 쓰는, 고정된 오늘 날짜의 운동 시간 합계.
  int get todayExerciseMinutes => _todayViewModel.todayExerciseMinutes;

  /// 지금까지 저장한 체중 기록 횟수.
  int get weightRecordCount => _todayViewModel.weightRecordCount;

  /// 기록 탭 요약 카드에 쓰는, 가장 최근에 저장한 체중.
  double get latestWeightKg => _todayViewModel.latestWeightKg;

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

  // 식단 기록 · 부가 정보
  // 식단 기록 · 부가 정보 — 입력값(끼니 · 소스 · 양 · 태그 · 메모)은 MealDraftViewModel이 맡는다.
  // 화면이 예전처럼 s.extras 같은 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  MealDraft get mealDraft => _mealDraftViewModel.mealDraft;
  Map<String, String> get extras => _mealDraftViewModel.extras;
  Map<String, String> get customInputs => _mealDraftViewModel.customInputs;
  String get portion => _mealDraftViewModel.portion;
  int get portionPct => _mealDraftViewModel.portionPct;
  String get fill => _mealDraftViewModel.fill;
  List<String> get tags => _mealDraftViewModel.tags;
  List<String> get customTags => _mealDraftViewModel.customTags;
  String get tagInput => _mealDraftViewModel.tagInput;
  set tagInput(String value) => _mealDraftViewModel.tagInput = value;
  String get memo => _mealDraftViewModel.memo;
  set memo(String value) => _mealDraftViewModel.memo = value;
  double get portionRatio => _mealDraftViewModel.portionRatio;

  Map<String, String>? get savedPreset => _mealDraftViewModel.savedPreset;
  int? get savedPresetBowlIndex => _mealDraftViewModel.savedPresetBowlIndex;
  String? get savedPresetPortion => _mealDraftViewModel.savedPresetPortion;
  String? get savedPresetFill => _mealDraftViewModel.savedPresetFill;
  void saveExtrasAsPreset() =>
      _mealDraftViewModel.saveExtrasAsPreset(bowlIndex: bowlIndex);

  void setExtra(String key, String value) =>
      _mealDraftViewModel.setExtra(key, value);
  void setCustomInput(String key, String value) =>
      _mealDraftViewModel.setCustomInput(key, value);
  bool applyCustom(String key) => _mealDraftViewModel.applyCustom(key);
  void setPortion(String p) => _mealDraftViewModel.setPortion(p);
  void setPortionPct(int pct) => _mealDraftViewModel.setPortionPct(pct);
  void setFill(String f) => _mealDraftViewModel.setFill(f);
  void toggleTag(String t) => _mealDraftViewModel.toggleTag(t);
  bool addCustomTag() => _mealDraftViewModel.addCustomTag();

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

  // 외부 AI로 데이터를 보내기 전에 받는 동의는 AiConsentViewModel이 맡는다.
  bool get aiConsent => _aiConsentViewModel.aiConsent;
  Future<void> loadAiConsent() => _aiConsentViewModel.loadAiConsent();
  Future<void> setAiConsent(bool value) =>
      _aiConsentViewModel.setAiConsent(value);

  /// 사진을 고르고 즉시 AI 분석을 요청한다 (지금 고른 그릇을 함께 알려 준다).
  Future<void> pickAndAnalyzeMealPhoto(ImageSource source) =>
      _photoAnalysisViewModel.pickAndAnalyze(source, bowl: currentBowl);

  /// 지금 선택된 그릇 — 등록한 그릇이 하나도 없으면 null (그릇 없이도 기록할 수 있다).
  Bowl? get currentBowl => _bowlViewModel.currentBowl;

  /// 부가 정보 반영 보정 칼로리 (입력값 + 사진 분석의 기본 칼로리 + 고른 그릇)
  int get adjustedKcal => _mealDraftViewModel.adjustedKcal;

  void selectBowl(int i) {
    bowlIndex = i;
    mealDraft.bowlId = bowls[i].id;
    notifyListeners();
  }

  // 기록 탭 — 달력(보고 있는 달 · 날짜)과 "기록한 날 · 연속 기록" 계산은
  // RecordsViewModel이 맡는다.
  int get year => _recordsViewModel.year;
  int get month => _recordsViewModel.month;
  int get day => _recordsViewModel.day;

  Map<String, bool> get logged => _recordsViewModel.logged;
  void prevMonth() => _recordsViewModel.prevMonth();
  bool get canGoNextMonth => _recordsViewModel.canGoNextMonth;
  bool nextMonth() => _recordsViewModel.nextMonth();
  bool isFutureDay(int d) => _recordsViewModel.isFutureDay(d);
  void selectDay(int d) => _recordsViewModel.selectDay(d);

  bool hasRecordOn(DateTime date) => _recordsViewModel.hasRecordOn(date);
  int get streakDays => _recordsViewModel.streakDays;

  /// 기록 탭에서 지금 보고 있는 날짜(month/day)의 식단.
  List<MealLog> get meals => _recordsViewModel.meals;

  /// 지금 보고 있는 날짜의 총 섭취 칼로리.
  int get selectedDayKcal => _recordsViewModel.selectedDayKcal;

  /// 촬영/기록 화면에서 저장한 값으로 실제 MealLog를 만들어 저장한다.
  void logMeal() {
    final bowl = currentBowl;
    final log = MealLog(
      id: 'meal_${DateTime.now().microsecondsSinceEpoch}',
      userId: _uid,
      mealType: MealDraftViewModel.mealTypeFromLabel(extras['meal'] ?? '점심'),
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

  /// 상세 화면에서 보여줄 식단은 RecordsViewModel이 기억한다.
  MealLog? get detailMeal => _recordsViewModel.detailMeal;

  void openMeal(MealLog m) {
    _recordsViewModel.selectDetailMeal(m);
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

  /// 체중 화면 "최근 7일" — 그날 마지막으로 기록한 체중(기록이 없는 날은 kg가 null).
  List<({int day, double? kg, bool isToday})> get recentWeightDays =>
      _recordsViewModel.recentWeightDays;

  void onWeightLogged(double kg) {
    _profileViewModel.onWeightLogged(kg);
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
    await _profileViewModel.deleteProfile(uid).timeout(limit);
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

  // 식물
  //
  // 성장 상태 · 저장 · 도감 수집 현황은 PlantViewModel이 맡는다. 화면이 예전처럼
  // s.plantLevel 같은 이름으로 쓸 수 있게, 같은 이름으로 전달만 한다.
  Plant get plant => _plantViewModel.plant;

  int get plantExp => _plantViewModel.plantExp;
  Map<PlantAxis, int> get axisScore => _plantViewModel.axisScore;
  Map<String, int> get cares => _plantViewModel.cares;
  int get missedDays => _plantViewModel.missedDays;
  bool get revived => _plantViewModel.revived;
  List<String> get wateredFriends => _plantViewModel.wateredFriends;
  Map<String, int> get inventory => _plantViewModel.inventory;
  int get giftTickets => _plantViewModel.giftTickets;

  int get plantLevel => _plantViewModel.plantLevel;
  bool get wilting => _plantViewModel.wilting;
  int get graceLeft => _plantViewModel.graceLeft;
  int get axisSpread => _plantViewModel.axisSpread;
  bool get balanced => _plantViewModel.balanced;
  PlantAxis get weakestAxis => _plantViewModel.weakestAxis;
  ({String emoji, String name, int lv, double size}) get plantStage =>
      _plantViewModel.plantStage;
  String get plantExpLeft => _plantViewModel.plantExpLeft;
  String get plantMood => _plantViewModel.plantMood;
  String get plantMessage => _plantViewModel.plantMessage;
  String get balanceHint => _plantViewModel.balanceHint;

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

  // 친구에게 보이는 공개 범위 — ProfileViewModel이 맡는다.
  PrivacySettings get privacySettings => _profileViewModel.privacySettings;
  String get shareScope => _profileViewModel.shareScope;
  set shareScope(String value) => _profileViewModel.shareScope = value;
  void setShareScope(String s) => _profileViewModel.setShareScope(s);

  static const friendVisibilityDesc = ProfileViewModel.friendVisibilityDesc;
  Map<String, bool> get friendVisibility => _profileViewModel.friendVisibility;
  void toggleFriendVisibility(String k) =>
      _profileViewModel.toggleFriendVisibility(k);
  String get friendVisibilitySummary =>
      _profileViewModel.friendVisibilitySummary;
  bool get gardenPublic => _profileViewModel.gardenPublic;
  void toggleGardenPublic() => _profileViewModel.toggleGardenPublic();

  void setFriendTab(String t) {
    friendTab = t;
    notifyListeners();
  }

  // 설정
  //
  // 알림 토글 · 시간은 ProfileViewModel이 저장하고, 바뀌면 기기 알림 예약을 다시 한다.
  Map<String, bool> get notifyToggles => _profileViewModel.notifyToggles;
  Map<String, String> get alertTime => _profileViewModel.alertTime;

  void toggleNotify(String k) {
    _profileViewModel.toggleNotify(k);
    unawaited(_applyNotificationSchedule());
  }

  void setAlertTime(String key, String value) {
    _profileViewModel.setAlertTime(key, value);
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
