import 'package:flutter/foundation.dart';

/// 지금 보이는 화면과, 한 화면 안의 서브 모드(미션 열기 · 탭 선택 …)를 담당한다.
///
/// 이 앱은 Navigator 라우트 대신 [screen] 문자열 하나로 화면을 바꾼다. 통합된 화면은
/// 부모 화면 + 서브 모드 플래그로 표현한다. 화면을 옮길 때 다른 기능이 해야 할 일(식물 날짜
/// 맞추기 · 시트 닫기 …)은 [onNavigated]로 AppState에 알린다.
class NavigationViewModel extends ChangeNotifier {
  String screen = 'login';

  // 서브 모드 (통합된 화면)
  bool missionOpen = false; // home
  bool extraOpen = false; // capture
  bool editing = false; // mealDetail
  bool profileEdit = false; // my
  String plantTab = '식물'; // 식물 / 도감
  String friendTab = '활동'; // 활동 / 챌린지 / 친구 추가
  String setTab = '알림'; // 알림 / 데이터 · 개인정보

  /// 화면을 옮긴 직후 불린다. 인자는 `go`에 넘어온 id(별칭이면 별칭 그대로)다.
  void Function(String id)? onNavigated;

  /// 옛 화면 id → 부모 화면 + 서브 모드
  static const _alias = <String, Map<String, Object>>{
    'signup': {'screen': 'onboard'},
    'mission': {'screen': 'home', 'missionOpen': true},
    'dex': {'screen': 'plant', 'plantTab': '도감'},
    'extra': {'screen': 'capture', 'extraOpen': true},
    'mealEdit': {'screen': 'mealDetail', 'editing': true},
    'challenge': {'screen': 'friends', 'friendTab': '챌린지'},
    'alerts': {'screen': 'settings', 'setTab': '알림'},
    'privacy': {'screen': 'settings', 'setTab': '데이터 · 개인정보'},
  };

  /// 하단 탭 활성 판정용 그룹
  static const tabGroups = <String, List<String>>{
    'home': ['home', 'notif', 'nutrition', 'recommend', 'plant'],
    'records': ['records', 'capture', 'exercise', 'weight', 'mealDetail'],
    'report': ['report'],
    'friends': ['friends', 'chNew'],
    'my': ['my', 'bowls', 'profile', 'settings'],
  };

  /// 화면 이동 기록 — 안드로이드 시스템 뒤로가기 버튼으로 이전 화면에
  /// 돌아가는 데 쓴다.
  final List<String> _history = [];

  /// 로그인 · 온보딩 화면에서는 하단 탭 · 빠른 기록 버튼을 숨긴다.
  bool get showShell => screen != 'login' && screen != 'onboard';

  /// [id] 화면으로 옮긴다. 별칭 id는 부모 화면 + 서브 모드로 풀어서 연다.
  void go(String id) {
    final alias = _alias[id];
    final resolvedScreen = (alias?['screen'] as String?) ?? id;
    if (showShell && screen != resolvedScreen) {
      _history.add(screen);
    }

    missionOpen = alias?['missionOpen'] as bool? ?? false;
    extraOpen = alias?['extraOpen'] as bool? ?? false;
    editing = alias?['editing'] as bool? ?? false;
    profileEdit = false;
    plantTab = alias?['plantTab'] as String? ?? '식물';
    friendTab = alias?['friendTab'] as String? ?? '활동';
    setTab = alias?['setTab'] as String? ?? '알림';
    screen = resolvedScreen;

    onNavigated?.call(id);
    notifyListeners();
  }

  /// 이동 기록을 남기지 않고 [target] 화면으로 바꾼다 (저장 직후 결과 화면 등).
  void replaceWith(String target, {String? friendTab}) {
    screen = target;
    if (friendTab != null) this.friendTab = friendTab;
    notifyListeners();
  }

  /// 열려 있는 서브 모드(미션 · 부가 정보 · 프로필 편집 …)를 하나 닫는다.
  /// 닫을 게 없으면 false.
  bool closeSubMode() {
    if (!(missionOpen || extraOpen || editing || profileEdit)) return false;
    missionOpen = false;
    extraOpen = false;
    editing = false;
    profileEdit = false;
    notifyListeners();
    return true;
  }

  /// 이전 화면으로 돌아간다. 돌아갈 곳이 없으면 false.
  bool goBack() {
    if (_history.isEmpty) return false;
    screen = _history.removeLast();
    notifyListeners();
    return true;
  }

  void setMissionOpen(bool v) {
    missionOpen = v;
    notifyListeners();
  }

  void setExtraOpen(bool v) {
    extraOpen = v;
    notifyListeners();
  }

  void setPlantTab(String t) {
    plantTab = t;
    notifyListeners();
  }

  void setFriendTab(String t) {
    friendTab = t;
    notifyListeners();
  }

  void setSetTab(String t) {
    setTab = t;
    notifyListeners();
  }
}
