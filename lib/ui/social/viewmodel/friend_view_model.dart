import 'dart:async';

import 'package:diet_project/data/repositories/activity_feed_repository.dart';
import 'package:diet_project/data/repositories/friend_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';

/// 친구 목록 · 친구 요청 · 초대 코드 검색 · 친구 활동 피드를 담당한다.
///
/// 화면에 보여줄 "사람"(User)을 만드는 일도 여기서 한다. 챌린지 쪽도 참가자를
/// 보여줄 때 [userFor]를 가져다 쓴다. 내 닉네임은 AppState가 갖고 있어서
/// [nickname]으로 매번 물어본다.
class FriendViewModel extends ChangeNotifier {
  FriendViewModel({
    required FriendRepository friendRepo,
    required ActivityFeedRepository activityFeedRepo,
    DateTime Function()? now,
  }) : _friendRepo = friendRepo,
       _activityFeedRepo = activityFeedRepo,
       _now = now ?? DateTime.now;

  final FriendRepository _friendRepo;
  final ActivityFeedRepository _activityFeedRepo;
  final DateTime Function() _now;

  /// 로그인한 계정의 uid. 데모 계정(로그인 안 함)에서는 null.
  String? uid;
  String get _uid => uid ?? User.meId;

  /// 내 닉네임 — 온보딩 · 마이페이지에서 바뀌므로 필요할 때마다 AppState에 묻는다.
  String Function() nickname = () => '';

  /// 불러오지 못했을 때, 사용자에게 보여줄 문구와 함께 불린다.
  void Function(String message)? onSyncFailed;

  // 사람은 이름 문자열이 아니라 User 모델(id로 구분)로 다룬다.
  // "나"는 currentUser로, 그 외 사람들은 아래 people 목록에서 가져온다.
  static const List<User> people = [
    User(id: 'u_jihyun', nickname: '지현', emoji: '🏃', tint: 0xFFFFEDE3),
    User(id: 'u_minsu', nickname: '민수', emoji: '🪴', tint: 0xFFEAF5E7),
    User(id: 'u_seoyeon', nickname: '서연', emoji: '🌸', tint: 0xFFFCEAF1),
    User(id: 'u_taeho', nickname: '태호', emoji: '💧', tint: 0xFFEAF1FE),
    User(id: 'u_hyunwoo', nickname: '현우', emoji: '🙂', tint: 0xFFF7EFE7),
    User(id: 'u_minji', nickname: '민지', emoji: '🏃', tint: 0xFFFFEDE3),
    User(id: 'u_junho', nickname: '준호', emoji: '🥗', tint: 0xFFEAF5E7),
    User(id: 'u_yujin', nickname: '유진', emoji: '🌱', tint: 0xFFEAF5E7),
  ];

  /// 지금 로그인한 사용자.
  User get currentUser =>
      User(id: _uid, nickname: nickname(), emoji: '🙂', tint: 0xFFEAF1FE);

  /// id로 사람을 찾는다. 목록에 없는 id면(알 수 없는 사람) 안전한 대체 값을 준다.
  static User personById(String id) => people.firstWhere(
    (u) => u.id == id,
    orElse: () =>
        User(id: id, nickname: '알 수 없음', emoji: '❓', tint: 0xFFEDEDED),
  );

  /// uid로 화면에 보여줄 User를 만든다 — 나 → 실제 친구 프로필 → 데모 인물 순으로 찾는다.
  User userFor(String uid) {
    if (uid == _uid) return currentUser;
    for (final f in realFriends) {
      if (f.uid == uid) {
        return User(
          id: f.uid,
          nickname: f.nickname,
          emoji: '🙂',
          tint: 0xFFEAF1FE,
        );
      }
    }
    return personById(uid);
  }

  List<String> addedFriends = [];

  void addFriend(String userId) {
    if (!addedFriends.contains(userId)) addedFriends.add(userId);
    notifyListeners();
  }

  // ── 실제 친구 데이터 ─────────────────────────────────────────────────

  /// 이 계정의 진짜 초대 코드. 로그인 직후 [loadForUid]에서 채워진다.
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

  /// friendSearchQuery를 초대 코드로 취급해 상대를 찾는다.
  Future<void> searchFriendByCode() async {
    final code = friendSearchQuery.trim();
    if (code.isEmpty) return;
    final found = await _friendRepo.findUidByCode(code);
    if (found == null || found == _uid) {
      friendSearchResult = null;
      friendSearchNotFound = true;
      notifyListeners();
      return;
    }
    friendSearchResult = await _friendRepo.loadPublicProfile(found);
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

  // ── 활동 피드 · 응원 ─────────────────────────────────────────────────

  List<({User user, String activity, String time})> get friendActivity => [
    for (final e in realActivityFeed)
      (user: userFor(e.uid), activity: e.message, time: _relativeTime(e.at)),
  ];

  final Set<String> cheeredFriends = {};

  void cheerFriend(String userId) {
    cheeredFriends.add(userId);
    notifyListeners();
  }

  String _relativeTime(DateTime at) {
    final diff = _now().difference(at);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 2) return '어제';
    return '${diff.inDays}일 전';
  }

  /// 친구 활동 피드에 한 줄을 남긴다. 데모 계정(로그인 안 함)에서는 아무것도 하지 않는다.
  void postActivity(String message) {
    final id = uid;
    if (id == null) return;
    unawaited(
      _activityFeedRepo.post(id, message).catchError((
        Object e,
        StackTrace stack,
      ) {
        debugPrint('활동 피드를 기록하지 못했어요: $e\n$stack');
      }),
    );
  }

  // ── 불러오기 · 비우기 · 삭제 ─────────────────────────────────────────

  /// 로그인 직후 초대 코드 · 친구 목록 · 받은 요청 · 활동 피드를 불러온다.
  Future<void> loadForUid(String uid) async {
    this.uid = uid;
    try {
      inviteCode = await _friendRepo.ensureInviteCode(uid, nickname());
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
      onSyncFailed?.call('친구 정보를 불러오지 못했어요.');
    }
    notifyListeners();
  }

  /// 친구 데이터를 비운다 (실제 계정으로 로그인할 때).
  void clear() {
    inviteCode = '';
    realFriends = [];
    realActivityFeed = [];
    incomingFriendRequests = [];
    requesterProfiles = {};
    friendSearchResult = null;
    friendSearchNotFound = false;
    notifyListeners();
  }

  /// 계정 삭제 — 공개 프로필 · 친구 관계 · 친구 요청 · 내 활동 피드를 지운다.
  Future<void> deleteAll(String uid) => Future.wait<void>([
    _friendRepo.deleteAllForUser(uid),
    _activityFeedRepo.deleteAllForUser(uid),
  ]);
}
