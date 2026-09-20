// 앱 전역 상태 — 프로토타입의 Component.state를 그대로 옮긴 ChangeNotifier.
//
// 화면 전환도 여기서 관리합니다 (Navigator 대신 screen 문자열).
// 통합된 화면은 부모 screen + 서브 모드 플래그로 표현합니다.

import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/repositories.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart' show Offset, Color;
import 'package:flutter/foundation.dart';

export 'package:diet_project/domain/models/models.dart';

// ─────────────────────────────────────────────────────────
// AppState
// ─────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  AppState({AuthService? auth}) : _auth = auth ?? MockAuthService();

  final AuthService _auth;

  // ── 화면 전환 ──────────────────────────────────────────
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

  void go(String id) {
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

  /// 하단 탭 활성 판정용 그룹
  static const tabGroups = <String, List<String>>{
    'home': ['home', 'notif', 'nutrition', 'recommend', 'plant'],
    'records': ['records', 'capture', 'exercise', 'weight', 'mealDetail'],
    'report': ['report'],
    'friends': ['friends', 'chNew'],
    'my': ['my', 'bowls', 'profile', 'settings'],
  };

  bool get showShell => screen != 'login' && screen != 'onboard';

  // ── 오늘 날짜 ─────────────────────────────────────────
  //
  // 이 프로토타입은 "지금"을 8월 19일로 고정해 둔다. month/day는 기록 탭
  // 달력에서 사용자가 넘겨보는 "보고 있는 날짜"라서, 홈 화면의 오늘 수치는
  // 그 값이 아니라 이 고정된 오늘 날짜를 기준으로 계산해야 한다.
  static const int todayMonth = 8;
  static const int todayDay = 19;

  static String _dateKey(int m, int d) =>
      '${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  String get _todayKey => _dateKey(todayMonth, todayDay);
  String get _selectedKey => _dateKey(month, day);
  bool get _viewingToday => month == todayMonth && day == todayDay;

  // ── 인증 · 온보딩 ─────────────────────────────────────
  String provider = 'Google';
  String nickname = '채린';

  /// 로그인한 계정 (로그인 전에는 null)
  AuthAccount? account;

  /// 로그인 창이 열려 있는 동안 true — 버튼 중복 탭을 막는다.
  bool signingIn = false;

  /// 마지막 로그인 · 계정 삭제 실패 문구 (화면이 토스트로 보여주고 비운다)
  String? authError;

  /// 로그인에 성공하면 true. 사용자가 창을 닫아 취소하면 false(authError 없음),
  /// 실패하면 false(authError에 사용자용 문구).
  Future<bool> signIn(LoginProvider p) async {
    if (signingIn) return false;
    signingIn = true;
    authError = null;
    notifyListeners();
    try {
      final result = await _auth.signIn(p);
      if (result == null) return false;
      account = result;
      provider = p.label;
      final name = result.displayName?.trim();
      if (name != null && name.isNotEmpty) nickname = name;
      return true;
    } on AuthFailure catch (e) {
      authError = e.message;
      return false;
    } finally {
      signingIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    account = null;
    go('login');
  }

  /// 계정 삭제에 성공하면 true, 실패하면 false(authError에 사용자용 문구).
  Future<bool> deleteAccount() async {
    try {
      await _auth.deleteAccount();
      account = null;
      go('login');
      return true;
    } on AuthFailure catch (e) {
      authError = e.message;
      notifyListeners();
      return false;
    }
  }
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
  }

  void toggleAllTerms() {
    final all = terms.values.every((v) => v);
    for (final k in terms.keys) {
      terms[k] = !all;
    }
    notifyListeners();
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
  final NotificationSettings notificationSettings = NotificationSettings(userId: User.meId);

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
        notificationSettings.waterReminder = !notificationSettings.waterReminder;
        break;
      case '운동 리마인드':
        notificationSettings.exerciseReminder = !notificationSettings.exerciseReminder;
        break;
      case '친구 응원 알림':
        notificationSettings.friendActivity = !notificationSettings.friendActivity;
        break;
    }
    notifyListeners();
  }

  double get bmi => profile.bmi;
  double get bmr => profile.bmr;
  int get dailyTarget => profile.dailyTarget;
  String get goalDelta => profile.goalDelta;

  // ── 홈 · 오늘 수치 ────────────────────────────────────
  /// 고정된 오늘 날짜(_todayKey)의 기록 요약. 기록 탭에서 넘겨보는 날짜(month/day)와
  /// 무관해야 하므로 식단 · 운동 · 체중 모두 _todayKey로 걸러낸다.
  /// 물은 아직 날짜별 히스토리가 없어서 항상 "오늘" 목록 하나를 그대로 쓴다.
  DailyRegistry get todayRegistry => DailyRegistry(
    userId: User.meId,
    dateKey: _todayKey,
    meals: todayMeals,
    waterEntries: waterEntries,
    exerciseLogs: _exerciseLogs
        .where((e) => e.userId == User.meId && e.dateKey == _todayKey)
        .toList(),
    weightEntry: _todayWeightEntry,
  );

  /// 오늘 저장한 가장 최근 체중 기록 (없으면 null)
  WeightEntry? get _todayWeightEntry {
    for (final w in weightEntries.reversed) {
      if (w.userId == User.meId && w.dateKey == _todayKey) return w;
    }
    return null;
  }

  int get intakeKcal => todayRegistry.totalIntakeKcal;
  int get remainKcal => dailyTarget - intakeKcal;
  double get intakeRatio => dailyTarget > 0 ? (intakeKcal / dailyTarget).clamp(0.0, 1.0) : 0.0;
  int streakDays = 12;

  // ── 미션 (자동 생성) ─────────────────────────────────
  List<Mission> get missions {
    // 실제 구현에서는 카테고리 풀에서 매일 3~5개를 선정합니다.
    // 규칙: 같은 카테고리 2개 초과 금지 / 전날 실패 카테고리 우선 /
    //       난이도는 최근 7일 평균의 90~110%
    return [
      Mission(
          id: 'm_meal3',
          category: '식단',
          title: '식단 3끼 기록하기',
          current: todayMeals.length.clamp(0, 3).toDouble(),
          target: 3.0,
          unit: '끼',
          exp: 20,
          axis: PlantAxis.nutri,
          route: 'capture'),
      Mission(
          id: 'm_water1500',
          category: '생활',
          title: '물 1.5L 마시기',
          current: waterTotal.toDouble(),
          target: 1500.0,
          unit: 'ml',
          exp: 10,
          axis: PlantAxis.water,
          route: 'water'),
      Mission(
          id: 'm_exercise30',
          category: '운동',
          title: '30분 운동하기',
          current: todayExerciseMinutes.toDouble(),
          target: 30.0,
          unit: '분',
          exp: 15,
          axis: PlantAxis.sun,
          route: 'exercise',
          special: '변이 기회'),
      const Mission(
          id: 'm_nutrition80',
          category: '꾸준함',
          title: '영양소 목표 80% 달성',
          current: 73.0,
          target: 80.0,
          unit: '%',
          exp: 15,
          axis: PlantAxis.nutri,
          route: 'nutrition'),
      Mission(
          id: 'm_streak7',
          category: '꾸준함',
          title: '7일 연속 기록하기',
          current: streakDays.clamp(0, 7).toDouble(),
          target: 7.0,
          unit: '일',
          exp: 25,
          axis: PlantAxis.nutri,
          route: 'records'),
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
  }

  int get missionDone => missions.where(missionEffectivelyDone).length;
  int get missionExp =>
      missions.where(missionEffectivelyDone).fold(0, (a, m) => a + m.exp);

  // ── 알림 ──────────────────────────────────────────────
  String notifTab = '전체';

  static const _unreadNotifIds = ['저녁 식단을 기록하지 않았어요', '식물이 물을 기다려요', '지현님이 응원을 보냈어요'];
  final Set<String> readNotifIds = {};

  int get unread => _unreadNotifIds.where((id) => !readNotifIds.contains(id)).length;

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

  // ── 식단 기록 · 부가 정보 ────────────────────────────
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
    'meat': '', 'sauce': '', 'cook': '', 'carb': '', 'meal': '', 'context': '',
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
  int get baseKcal => 450;

  /// 부가 정보 반영 보정 칼로리
  int get adjustedKcal {
    var v = baseKcal *
        portionRatio *
        (DietRules.fillRatio[fill] ?? 1.0) *
        bowls[bowlIndex.clamp(0, bowls.length - 1)].capacityFactor;
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
    mealDraft.portionPercent = {'전체': 100, '반절': 50, '1/3': 33}[p] ?? mealDraft.portionPercent;
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

  // ── 기록 탭 ───────────────────────────────────────────
  int month = 8;
  int day = 19;

  /// 실제 기록 존재 여부로 계산한다. 식단 · 운동은 날짜별로 기록이 남으니
  /// 지금 보고 있는 날짜(month/day) 기준으로, 물 · 체중은 아직 날짜별
  /// 히스토리를 모델링하지 않아서(항상 "오늘" 하나의 목록) 오늘을 보고
  /// 있을 때만 실제 기록 여부를 반영한다.
  Map<String, bool> get logged => {
    '식단': meals.isNotEmpty,
    '운동': _exerciseLogs.any((e) => e.userId == User.meId && e.dateKey == _selectedKey),
    '체중': _viewingToday && weightEntries.isNotEmpty,
    '물': _viewingToday && waterEntries.isNotEmpty,
  };

  void prevMonth() {
    month = (month - 1).clamp(1, 12);
    final total = DateTime(2026, month + 1, 0).day;
    day = day.clamp(1, total);
    notifyListeners();
  }

  bool nextMonth() {
    if (month >= 12) return false;
    month += 1;
    notifyListeners();
    return true;
  }

  void selectDay(int d) {
    day = d;
    notifyListeners();
  }

  /// 전체 식단 기록 저장소. bowlId로 Bowl을, dateKey로 날짜를 참조한다.
  final List<MealLog> _mealLogs = [
    MealLog(id: 'meal_seed_breakfast', userId: User.meId, mealType: MealType.breakfast, name: '오트밀 · 바나나', meta: '집 밥그릇 · 가득 · 집밥', kcal: 320, dateKey: '08-19', bowlId: 'bowl_home'),
    MealLog(id: 'meal_seed_lunch', userId: User.meId, mealType: MealType.lunch, name: '볶음밥 (추정)', meta: '회사 도시락 · 가득 · 도시락', kcal: 450, dateKey: '08-19', bowlId: 'bowl_lunchbox', needsReview: true),
    MealLog(id: 'meal_seed_dinner', userId: User.meId, mealType: MealType.dinner, name: '닭가슴살 샐러드', meta: '샐러드 볼 · 반 · 집밥', kcal: 480, dateKey: '08-19', bowlId: 'bowl_salad'),
    MealLog(id: 'meal_seed_snack', userId: User.meId, mealType: MealType.snack, name: '그릭요거트', meta: '컵 · 가득 · 외식', kcal: 200, dateKey: '08-19'),
  ];

  /// 기록 탭에서 지금 보고 있는 날짜(month/day)의 식단.
  List<MealLog> get meals =>
      _mealLogs.where((m) => m.userId == User.meId && m.dateKey == _selectedKey).toList();

  /// 지금 보고 있는 날짜의 총 섭취 칼로리.
  int get selectedDayKcal => meals.fold(0, (a, m) => a + m.kcal);

  /// 홈 화면 "오늘 섭취" 계산에 쓰는, 고정된 오늘 날짜의 식단.
  List<MealLog> get todayMeals =>
      _mealLogs.where((m) => m.userId == User.meId && m.dateKey == _todayKey).toList();

  /// 촬영/기록 화면에서 저장한 값으로 실제 MealLog를 만들어 저장한다.
  void logMeal() {
    final bowl = bowls.isEmpty ? null : bowls[bowlIndex.clamp(0, bowls.length - 1)];
    _mealLogs.add(MealLog(
      id: 'meal_${DateTime.now().microsecondsSinceEpoch}',
      userId: User.meId,
      mealType: _mealTypeFromLabel(extras['meal'] ?? '점심'),
      name: '볶음밥 (추정)',
      meta: bowl == null ? '기록 · $fill · ${extras['context']}' : '${bowl.name} · $fill · ${extras['context']}',
      kcal: adjustedKcal,
      dateKey: _todayKey,
      bowlId: bowl?.id,
      needsReview: true,
    ));
    notifyListeners();
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

  // ── 운동 ──────────────────────────────────────────────
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
      .where((e) => e.userId == User.meId && e.dateKey == _todayKey)
      .fold(0, (a, e) => a + e.minutes);

  /// 지금 입력값으로 실제 운동 기록을 저장한다.
  void logExercise() {
    _exerciseLogs.add(ExerciseLog(
      id: 'ex_${DateTime.now().microsecondsSinceEpoch}',
      userId: User.meId,
      type: exType,
      minutes: exMinutes,
      intensity: exerciseDraft.intensity,
      kcal: exKcal,
      dateKey: _selectedKey,
      time: '지금',
    ));
    notifyListeners();
  }

  List<Routine> routines = [
    Routine(id: 'routine_morning_run', userId: User.meId, name: '아침 러닝', type: '달리기', minutes: 30, intensity: ExerciseIntensity.moderate, icon: '🏃', used: 12, weeklyUsed: 3),
    Routine(id: 'routine_home_workout', userId: User.meId, name: '홈트 세트', type: '근력', minutes: 40, intensity: ExerciseIntensity.high, icon: '🏋️', used: 8, weeklyUsed: 2),
    Routine(id: 'routine_evening_walk', userId: User.meId, name: '저녁 산책', type: '걷기', minutes: 25, intensity: ExerciseIntensity.low, icon: '🚶', used: 5, weeklyUsed: 1),
  ];

  static const _routineIcons = {
    '달리기': '🏃', '걷기': '🚶', '자전거': '🚴', '근력': '🏋️',
    '요가': '🧘', '수영': '🏊', '등산': '🥾',
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
    routines.add(Routine(
      id: 'routine_${DateTime.now().microsecondsSinceEpoch}',
      userId: User.meId,
      name: '$exType $exMinutes분',
      type: exType,
      minutes: exMinutes,
      intensity: exerciseDraft.intensity,
      icon: _routineIcons[exType.trim()] ?? '💪',
    ));
    notifyListeners();
  }

  void removeRoutine(Routine r) {
    routines.remove(r);
    notifyListeners();
  }

  // ── 체중 ──────────────────────────────────────────────
  double weightInput = 56.7;
  final Map<String, bool> bodyShots = {'FRONT': true, 'SIDE': false};

  bool get bodyShotsOk => bodyShots['FRONT'] == true && bodyShots['SIDE'] == true;

  void toggleBodyShot(String k) {
    bodyShots[k] = !(bodyShots[k] ?? false);
    notifyListeners();
  }

  /// 실제로 저장한 체중 기록 저장소 — 최근 값이 "어제보다" 비교 기준이 된다.
  List<WeightEntry> weightEntries = [
    WeightEntry(id: 'weight_seed', userId: User.meId, kg: 56.9, dateKey: _dateKey(todayMonth, todayDay - 1), time: '어제'),
  ];

  /// 기록 탭 요약 카드에 쓰는, 가장 최근에 저장한 체중.
  double get latestWeightKg => weightEntries.isEmpty ? profile.weightKg : weightEntries.last.kg;

  String get weightDiff {
    final last = weightEntries.isEmpty ? profile.weightKg : weightEntries.last.kg;
    return '${(weightInput - last).toStringAsFixed(1)}kg';
  }

  /// 눈바디 2장을 확인한 뒤 지금 입력값으로 실제 체중 기록을 저장한다.
  void logWeight() {
    weightEntries.add(WeightEntry(
      id: 'weight_${DateTime.now().microsecondsSinceEpoch}',
      userId: User.meId,
      kg: weightInput,
      dateKey: _todayKey,
      time: '지금',
    ));
    profile.weightKg = weightInput;
    notifyListeners();
  }

  // ── 물 ────────────────────────────────────────────────
  bool waterSheet = false;
  int waterInput = 250;

  List<WaterEntry> waterEntries = [
    WaterEntry(id: 'water_seed_1', userId: User.meId, ml: 250, time: '08:10'),
    WaterEntry(id: 'water_seed_2', userId: User.meId, ml: 350, time: '10:30'),
    WaterEntry(id: 'water_seed_3', userId: User.meId, ml: 500, time: '12:45'),
    WaterEntry(id: 'water_seed_4', userId: User.meId, ml: 350, time: '15:20'),
  ];

  int get waterTotal => waterEntries.fold(0, (a, e) => a + e.ml);
  int get waterLeft => (2000 - waterTotal).clamp(0, 2000);
  int get waterPct => ((waterTotal / 2000) * 100).round().clamp(0, 100);

  void addWater([int? ml]) {
    final v = ml ?? waterInput;
    if (v <= 0) return;
    waterEntries.add(WaterEntry(
      id: 'water_${DateTime.now().microsecondsSinceEpoch}',
      userId: User.meId,
      ml: v,
      time: '지금',
    ));
    notifyListeners();
  }

  void editWater(int i, int ml) {
    waterEntries[i].ml = ml.clamp(0, 3000);
    notifyListeners();
  }

  void removeWater(int i) {
    waterEntries.removeAt(i);
    notifyListeners();
  }

  void undoWater() {
    if (waterEntries.isNotEmpty) waterEntries.removeLast();
    notifyListeners();
  }

  // ── 그릇 ──────────────────────────────────────────────
  bool bowlSheet = false;
  int? bowlEditing; // null = 편집 중 아님, -1 = 신규 추가

  List<Bowl> bowls = [
    Bowl(id: 'bowl_lunchbox', userId: User.meId, name: '회사 도시락', capacityMl: 500, portion: '1인분', material: '플라스틱', shape: '도시락', memo: '항상 가득 채워 먹음', isDefault: true, icon: '🍱'),
    Bowl(id: 'bowl_home', userId: User.meId, name: '집 밥그릇', capacityMl: 300, portion: '소', material: '도자기', shape: '원형', memo: '반만 채움', icon: '🍚'),
    Bowl(id: 'bowl_salad', userId: User.meId, name: '샐러드 볼', capacityMl: 900, portion: '대', material: '유리', shape: '원형', memo: '드레싱 따로', icon: '🥗'),
    Bowl(id: 'bowl_tumbler', userId: User.meId, name: '텀블러', capacityMl: 450, portion: '중', material: '스테인리스', shape: '컵', memo: '물 기록용', icon: '☕'),
  ];

  Bowl draftBowl = Bowl(id: '', userId: User.meId, name: '', capacityMl: 400, portion: '1인분', material: '플라스틱', shape: '원형');

  void startAddBowl() {
    draftBowl = Bowl(id: '', userId: User.meId, name: '', capacityMl: 400, portion: '1인분', material: '플라스틱', shape: '원형');
    bowlEditing = -1;
    notifyListeners();
  }

  void startEditBowl(int i) {
    final b = bowls[i];
    draftBowl = Bowl(
      id: b.id, userId: b.userId, name: b.name, capacityMl: b.capacityMl, portion: b.portion,
      material: b.material, shape: b.shape, memo: b.memo,
      isDefault: b.isDefault, icon: b.icon,
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
    if (draftBowl.isDefault) {
      for (final b in bowls) {
        b.isDefault = false;
      }
    }
    if (bowlEditing == -1) {
      if (bowls.length >= DietRules.maxBowls) return false;
      bowls.add(Bowl(
        id: 'bowl_${DateTime.now().microsecondsSinceEpoch}',
        userId: User.meId,
        name: draftBowl.name, capacityMl: draftBowl.capacityMl, portion: draftBowl.portion,
        material: draftBowl.material, shape: draftBowl.shape, memo: draftBowl.memo,
        isDefault: draftBowl.isDefault, icon: draftBowl.icon,
      ));
    } else if (bowlEditing != null) {
      bowls[bowlEditing!] = draftBowl;
    }
    bowlEditing = null;
    notifyListeners();
    return true;
  }

  void removeBowl(int i) {
    bowls.removeAt(i);
    if (bowlIndex >= bowls.length) bowlIndex = 0;
    bowlEditing = null;
    notifyListeners();
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

  // ── 식물 ──────────────────────────────────────────────
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
  ({String emoji, String name, int lv, double size}) get plantStage => plant.stage;
  String get plantExpLeft => plant.expLeft;
  String get plantMood => plant.mood;
  String get plantMessage => plant.message;
  String get balanceHint => plant.balanceHint;

  void care(String name) {
    plant.care(name);
    notifyListeners();
  }

  void revive() {
    plant.revive();
    notifyListeners();
  }

  /// friendUserId(친구의 User.id)의 정원에 물을 준다.
  void waterFriend(String friendUserId) {
    if (plant.waterFriend(friendUserId)) notifyListeners();
  }

  /// 보관함 아이템 사용 — 즉시 1개 소모하고 효과를 바로 반영해요.
  void useInventoryItem(String key) {
    plant.useInventoryItem(key);
    notifyListeners();
  }

  void sendGiftFlower() {
    if (plant.sendGiftFlower()) notifyListeners();
  }

  // ── 도감 ──────────────────────────────────────────────
  //
  // 카탈로그(어떤 종이 있는지)는 PlantSpecies.catalog가, "내가 그 종을
  // 얼마나 모았는지"는 DexRepository가 userId·speciesId 관계로 담당한다.
  // 여기서는 둘을 합친 DexCard 목록만 다룬다.
  String dexTab = '전체';
  int dexPick = 0;

  final DexRepository _dexRepo = DexRepository();

  /// 모두가 공유하는 도감 베이스 카탈로그.
  static List<PlantSpecies> get dexBase => PlantSpecies.catalog;

  List<DexCard> get _dexCards => _dexRepo.cardsFor(User.meId);

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
    return dexTab == '전체' ? cards : cards.where((c) => c.tier == dexTab).toList();
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

  // ── 식단 추천 ─────────────────────────────────────────
  List<String> needs = ['식이섬유', '칼슘'];
  String recMeal = '저녁';
  List<String> recPrefs = ['채식 위주'];
  int recMaxKcal = 600;
  String recSort = '추천순';
  int recSeed = 0;

  static const needOptions = [
    '탄수화물', '단백질', '지방', '식이섬유', '칼슘', '철분', '비타민D', '오메가3',
  ];

  static const _pool = <MealSuggestion>[
    MealSuggestion(name: '현미밥 · 두부구이 · 브로콜리', emoji: '🍚', kcal: 520, meta: '탄수화물 68g · 식이섬유 9g · 칼슘 240mg · 단백질 26g', covers: ['탄수화물', '식이섬유', '칼슘', '단백질'], prefs: ['채식 위주', '저나트륨'], meals: ['점심', '저녁'], tag: '집밥', why: '식이섬유와 칼슘을 한 끼로 함께 채울 수 있어요.'),
    MealSuggestion(name: '연어 샐러드 · 통밀빵', emoji: '🥗', kcal: 480, meta: '오메가3 1.8g · 지방 22g · 식이섬유 7g · 단백질 30g', covers: ['오메가3', '지방', '식이섬유', '단백질'], prefs: ['고단백', '간편식'], meals: ['점심', '저녁'], tag: '15분', why: '조리 없이 준비할 수 있고 좋은 지방과 단백질이 넉넉해요.'),
    MealSuggestion(name: '병아리콩 커리 · 현미', emoji: '🍛', kcal: 560, meta: '탄수화물 74g · 식이섬유 12g · 철분 5mg', covers: ['탄수화물', '식이섬유', '철분'], prefs: ['채식 위주'], meals: ['점심', '저녁'], tag: '든든', why: '탄수화물과 식이섬유를 한 번에 채워요.'),
    MealSuggestion(name: '그릭요거트 · 아몬드 · 블루베리', emoji: '🫐', kcal: 280, meta: '칼슘 300mg · 단백질 18g', covers: ['칼슘', '단백질'], prefs: ['간편식'], meals: ['아침', '간식'], tag: '5분', why: '간식으로 칼슘과 단백질을 함께 챙길 수 있어요.'),
    MealSuggestion(name: '닭가슴살 스테이크 · 시금치', emoji: '🍗', kcal: 430, meta: '단백질 38g · 철분 4mg', covers: ['단백질', '철분'], prefs: ['고단백', '저나트륨'], meals: ['점심', '저녁'], tag: '고단백', why: '단백질 목표가 남았을 때 가장 효율적이에요.'),
    MealSuggestion(name: '오트밀 · 바나나 · 우유', emoji: '🥛', kcal: 320, meta: '탄수화물 52g · 식이섬유 8g · 칼슘 320mg', covers: ['탄수화물', '식이섬유', '칼슘'], prefs: ['간편식', '채식 위주'], meals: ['아침', '간식'], tag: '5분', why: '아침 탄수화물과 칼슘을 동시에 챙기는 조합이에요.'),
    MealSuggestion(name: '고구마 · 삶은 달걀 · 그린샐러드', emoji: '🍠', kcal: 380, meta: '탄수화물 54g · 식이섬유 7g · 단백질 16g', covers: ['탄수화물', '식이섬유', '단백질'], prefs: ['간편식', '채식 위주'], meals: ['아침', '점심', '간식'], tag: '10분', why: '탄수화물이 부족한 날 혈당 부담이 적은 선택이에요.'),
    MealSuggestion(name: '아보카도 통밀 토스트 · 달걀', emoji: '🥑', kcal: 420, meta: '지방 26g · 탄수화물 34g · 식이섬유 9g', covers: ['지방', '탄수화물', '식이섬유'], prefs: ['간편식', '채식 위주'], meals: ['아침', '점심'], tag: '10분', why: '지방이 부족할 때 불포화지방으로 채우기 좋아요.'),
    MealSuggestion(name: '견과 한 줌 · 무가당 요거트', emoji: '🥜', kcal: 260, meta: '지방 19g · 칼슘 210mg · 단백질 12g', covers: ['지방', '칼슘', '단백질'], prefs: ['간편식'], meals: ['간식'], tag: '즉시', why: '간식으로 좋은 지방과 칼슘을 함께 보충해요.'),
    MealSuggestion(name: '고등어 구이 · 현미밥', emoji: '🐟', kcal: 540, meta: '오메가3 2.2g · 비타민D 12µg · 단백질 32g', covers: ['오메가3', '비타민D', '단백질'], prefs: ['저나트륨'], meals: ['점심', '저녁'], tag: '집밥', why: '비타민D와 오메가3를 한 번에 채우는 메뉴예요.'),
    MealSuggestion(name: '두부 김치 볶음 · 현미', emoji: '🍲', kcal: 470, meta: '단백질 24g · 식이섬유 8g', covers: ['단백질', '식이섬유'], prefs: ['채식 위주'], meals: ['점심', '저녁'], tag: '집밥', why: '익숙한 조합으로 단백질을 채울 수 있어요.'),
    MealSuggestion(name: '새우 두부면 파스타', emoji: '🍝', kcal: 410, meta: '단백질 34g · 식이섬유 7g', covers: ['단백질', '식이섬유'], prefs: ['고단백', '간편식'], meals: ['점심', '저녁'], tag: '20분', why: '면이 먹고 싶을 때 칼로리 부담을 줄인 선택이에요.'),
  ];

  /// 조건 기반 추천 결과 (점수 내림차순 또는 칼로리 오름차순)
  List<({MealSuggestion meal, int score, bool offMeal})> get recommendations {
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

    scored.sort((a, b) => recSort == '칼로리 낮은 순'
        ? a.meal.kcal.compareTo(b.meal.kcal)
        : b.score.compareTo(a.score));
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

  // ── 리포트 ────────────────────────────────────────────
  String period = '주간';

  void setPeriod(String p) {
    period = p;
    notifyListeners();
  }

  List<({String label, int value, int pct})> get kcalBars => period == '주간'
      ? const [
    (label: '월', value: 1720, pct: 78),
    (label: '화', value: 1450, pct: 66),
    (label: '수', value: 1810, pct: 82),
    (label: '목', value: 1590, pct: 72),
    (label: '금', value: 1980, pct: 90),
    (label: '토', value: 1380, pct: 63),
    (label: '일', value: 1450, pct: 66),
  ]
      : const [
    (label: '1주', value: 1740, pct: 79),
    (label: '2주', value: 1680, pct: 76),
    (label: '3주', value: 1620, pct: 74),
    (label: '4주', value: 1690, pct: 77),
    (label: '5주', value: 1450, pct: 66),
  ];

  List<({String label, double kg})> get weightSeries => period == '주간'
      ? const [
    (label: '8/13', kg: 57.5), (label: '8/14', kg: 57.4),
    (label: '8/15', kg: 57.2), (label: '8/16', kg: 57.3),
    (label: '8/17', kg: 57.0), (label: '8/18', kg: 56.9),
    (label: '8/19', kg: 56.7),
  ]
      : const [
    (label: '4주전', kg: 58.1), (label: '3주전', kg: 57.8),
    (label: '2주전', kg: 57.5), (label: '1주전', kg: 57.1),
    (label: '이번주', kg: 56.7),
  ];

  String get avgKcal => period == '주간' ? '1,612' : '1,684';
  String get periodDelta =>
      period == '주간' ? '지난주 대비 -120kcal' : '지난달 대비 -240kcal';

  int get avgExerciseMin => period == '주간' ? 38 : 34;
  int get exerciseMinDelta => period == '주간' ? 6 : 4;

  int get achieveRate => period == '주간' ? 72 : 68;

  int get recordDays => period == '주간' ? 6 : 24;
  int get recordGoalDays => period == '주간' ? 5 : 20;

  String get mostEatenFood => '닭가슴살 샐러드 · 5회';
  String get mostUsedBowl => '회사 도시락 · 8회';
  String get mostUsedSauce => '저당 소스 · 6회';
  String get lackingNutrient => '식이섬유 -28%';
  String get recommendedMeal => '식이섬유가 부족해요. 오늘 저녁은 현미밥 + 브로콜리 + 두부구이를 추천해요.';

  // ── 친구 · 챌린지 ─────────────────────────────────────
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
  User get currentUser =>
      User(id: User.meId, nickname: nickname, emoji: '🙂', tint: const Color(0xFFEAF1FE));

  /// id로 사람을 찾는다. 목록에 없는 id면(알 수 없는 사람) 안전한 대체 값을 준다.
  static User personById(String id) => people.firstWhere(
        (u) => u.id == id,
    orElse: () => User(id: id, nickname: '알 수 없음', emoji: '❓', tint: const Color(0xFFEDEDED)),
  );

  List<String> addedFriends = [];
  List<String> acceptedRequests = [];
  final PrivacySettings privacySettings = PrivacySettings(userId: User.meId);

  String get shareScope => privacySettings.scope.label;
  set shareScope(String value) => privacySettings.scope =
  value == '비공개' ? ShareScope.private : ShareScope.friends;

  String get inviteCode => 'SEED-4821';

  String friendSearchQuery = '';

  void setFriendSearchQuery(String v) {
    friendSearchQuery = v;
    notifyListeners();
  }

  static final List<({User user, String desc})> _friendRequestsAll = [
    (user: personById('u_minji'), desc: '함께 아는 친구 2명'),
    (user: personById('u_junho'), desc: '초대 코드로 요청'),
  ];

  List<({User user, String desc})> get friendRequests => _friendRequestsAll
      .where((f) => !acceptedRequests.contains(f.user.id))
      .toList();

  static final List<({User user, String desc})> _suggestedFriendsAll = [
    (user: personById('u_yujin'), desc: '같은 목표 · 체중 감량'),
    (user: personById('u_taeho'), desc: '물 챌린지 참여 중'),
  ];

  List<({User user, String desc})> get suggestedFriends => _suggestedFriendsAll
      .where((f) => !addedFriends.contains(f.user.id))
      .toList();

  void setFriendTab(String t) {
    friendTab = t;
    notifyListeners();
  }

  void setShareScope(String s) {
    shareScope = s;
    notifyListeners();
  }

  // ── 친구 탭 · 활동 요약 ────────────────────────────────
  String get activeChallengeName => '8월 물 마시기 챌린지';
  int get activeChallengeDaysLeft => 3;

  List<({User user, double ratio})> get activeChallengeProgress => [
    (user: currentUser, ratio: 1.0),
    (user: personById('u_jihyun'), ratio: 0.62),
    (user: personById('u_minsu'), ratio: 0.48),
    (user: personById('u_seoyeon'), ratio: 0.24),
    (user: personById('u_taeho'), ratio: 0.1),
    (user: personById('u_hyunwoo'), ratio: 0.08),
  ];

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
        privacySettings.shareChallengeRank = !privacySettings.shareChallengeRank;
        break;
    }
    notifyListeners();
  }

  String get friendVisibilitySummary {
    final on = friendVisibility.entries.where((e) => e.value).map((e) => e.key).toList();
    return on.isEmpty
        ? '$shareScope · 공개 항목 없음'
        : '$shareScope · 공개 항목 ${on.length}개 — ${on.join(', ')}';
  }

  bool get gardenPublic => privacySettings.shareGarden;

  void toggleGardenPublic() {
    privacySettings.shareGarden = !privacySettings.shareGarden;
    notifyListeners();
  }

  List<({User user, String activity, String time})> get friendActivity => [
    (user: personById('u_jihyun'), activity: '오늘 운동 60분 달성', time: '3시간 전'),
    (user: personById('u_minsu'), activity: '점심 식단 기록', time: '5시간 전'),
    (user: personById('u_seoyeon'), activity: '식물 꽃 피움 단계 도달', time: '어제'),
    (user: personById('u_taeho'), activity: '물 2,000ml 달성', time: '어제'),
  ];

  final Set<String> cheeredFriends = {};

  void cheerFriend(String userId) {
    cheeredFriends.add(userId);
    notifyListeners();
  }

  // ── 친구 탭 · 챌린지 ───────────────────────────────────
  int get myChallengeRank => 1;

  List<({int rank, User user, int pct})> get challengeLeaderboard => [
    (rank: 1, user: currentUser, pct: 92),
    (rank: 2, user: personById('u_jihyun'), pct: 80),
    (rank: 3, user: personById('u_minsu'), pct: 64),
    (rank: 4, user: personById('u_seoyeon'), pct: 50),
  ];

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

  /// 전체 챌린지를 관리하는 저장소. "챌린지 하나의 모양"은 Challenge 모델이,
  /// "지금 있는 챌린지 목록을 어떻게 저장 · 조회 · 수정할지"는 여기가 담당한다.
  final ChallengeRepository _challengeRepo = ChallengeRepository();

  /// 아직 내가 참여하지 않은 공개 챌린지
  List<Challenge> get joinableChallenges => _challengeRepo.joinable(currentUser.id);

  /// 내가 만들었거나 참여 중인 챌린지
  List<Challenge> get myChallenges => _challengeRepo.mine(currentUser.id);

  void acceptRequest(String userId) {
    if (!acceptedRequests.contains(userId)) acceptedRequests.add(userId);
    notifyListeners();
  }

  void addFriend(String userId) {
    if (!addedFriends.contains(userId)) addedFriends.add(userId);
    notifyListeners();
  }

  void joinChallenge(String challengeId) {
    _challengeRepo.join(challengeId, currentUser.id);
    notifyListeners();
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
  set chPublic(bool value) => challengeDraft.visibility =
  value ? ChallengeVisibility.public : ChallengeVisibility.private;

  String get chReward => challengeDraft.reward.label;
  set chReward(String value) => challengeDraft.reward = switch (value) {
    '배지' => ChallengeReward.badge,
    '없음' => ChallengeReward.none,
    _ => ChallengeReward.plantExperience,
  };

  static const chKindMeta = <String, ({String icon, String unit, int base, String desc})>{
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

  String get chName => '$chKind ${_comma(chTarget)}$chUnit $chDurLabel 챌린지';

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
      '참가 ${chInvites.length + 1}명 · $chDays일 · 매일 ${_comma(chTarget)}$chUnit 달성 · '
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
      orElse: () => User(id: 'u_$n', nickname: n, emoji: '🙂', tint: const Color(0xFFEDEDED)),
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

  void createChallenge() {
    final end = DateTime(2026, 9, chDays.clamp(1, 365));
    final invitedIds = chInvites
        .map((n) => people
        .firstWhere(
          (u) => u.nickname == n,
      orElse: () =>
          User(id: 'u_$n', nickname: n, emoji: '🙂', tint: const Color(0xFFEDEDED)),
    )
        .id)
        .toList();
    _challengeRepo.create(Challenge(
      id: 'c_${DateTime.now().microsecondsSinceEpoch}',
      title: chName,
      description: '매일 ${_comma(chTarget)}$chUnit 달성 · 보상 $chReward',
      icon: chKindMeta[chKind]!.icon,
      category: chDurLabel,
      period: '9/1 ~ ${end.month}/${end.day}',
      creatorId: currentUser.id,
      participantIds: [currentUser.id, ...invitedIds],
      isPublic: chPublic,
      rewardDescription: chRewardDesc,
    ));
    friendTab = '챌린지';
    screen = 'friends';
    notifyListeners();
  }

  // ── 설정 ──────────────────────────────────────────────
  final Map<String, bool> notifyToggles = {
    '식단 미기록 알림': true,
    '물 마시기 알림': true,
    '운동 리마인드': false,
    '친구 응원 알림': true,
  };

  final Map<String, String> alertTime = {
    '아침 기록 알림': '08:00',
    '저녁 정리 알림': '21:00',
    '주간 리포트': '일요일 20:00',
  };

  void toggleNotify(String k) {
    notifyToggles[k] = !(notifyToggles[k] ?? false);
    notifyListeners();
  }

  void setAlertTime(String key, String value) {
    alertTime[key] = value;
    notifyListeners();
  }

  void setSetTab(String t) {
    setTab = t;
    notifyListeners();
  }

  // ── FAB (드래그 가능) ────────────────────────────────
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

  static String _comma(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  static String comma(int n) => _comma(n);
}
