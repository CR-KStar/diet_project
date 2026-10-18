import 'dart:async';

import 'package:diet_project/common.dart' show AppStateFormat;
import 'package:diet_project/data/repositories/challenge_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/social/viewmodel/friend_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

/// 챌린지 목록 · 참여 · 순위 · 진행 상황 보고와, 챌린지 만들기 화면의 입력값을 담당한다.
///
/// 참가자를 화면에 보여줄 때 필요한 "uid → 사람"은 친구 쪽 일이라 [userFor]로
/// 넘겨받는다. 챌린지를 만든 뒤 어느 화면으로 이동할지는 AppState가 맡는다.
class ChallengeViewModel extends ChangeNotifier {
  ChallengeViewModel({
    required ChallengeRepository challengeRepo,
    DateTime Function()? now,
  }) : _challengeRepo = challengeRepo,
       _now = now ?? DateTime.now;

  final ChallengeRepository _challengeRepo;
  final DateTime Function() _now;

  /// 로그인한 계정의 uid. 데모 계정(로그인 안 함)에서는 null.
  String? uid;
  String get _uid => uid ?? User.meId;

  /// 불러오지 못했을 때, 사용자에게 보여줄 문구와 함께 불린다.
  void Function(String message)? onSyncFailed;

  /// 참가자 uid를 화면에 보여줄 사람으로 바꾼다 — AppState가 FriendViewModel.userFor로 연결한다.
  User Function(String uid) userFor = FriendViewModel.personById;

  DateTime get _today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── 챌린지 목록 ──────────────────────────────────────────────────────

  /// 데모(Mock) 계정에서 보여줄 예시 챌린지. 실제 계정은 로그인 후
  /// [loadForUid]에서 Firestore에 저장된 전체 목록으로 덮어쓴다.
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
      bonusDescription: '보너스 15% 희귀 씨앗',
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
      bonusDescription: '보너스 10% 스페셜 아이템',
    ),
  ];

  /// 챌린지별 · 참가자별 오늘 진행 상황(리더보드용). 내가 참여 중인
  /// 챌린지만 불러온다.
  Map<String, Map<String, num>> _challengeProgress = {};

  /// 아직 내가 참여하지 않은 공개 챌린지
  List<Challenge> get joinableChallenges =>
      challenges.where((c) => c.isPublic && !c.isParticipant(_uid)).toList();

  /// 내가 만들었거나 참여 중인 챌린지
  List<Challenge> get myChallenges =>
      challenges.where((c) => c.isParticipant(_uid)).toList();

  Future<void> joinChallenge(String challengeId) async {
    final target = challenges.where((c) => c.id == challengeId);
    if (target.isEmpty) return;
    if (!target.first.participantIds.contains(_uid)) {
      target.first.participantIds.add(_uid); // 화면에 바로 반영
    }
    notifyListeners();
    await _challengeRepo.join(challengeId, _uid);
  }

  /// 내가 참여 중인, metricType이 일치하는 모든 챌린지에 오늘 진행 상황을 보고한다.
  /// 데모 계정(로그인 안 함)에서는 아무것도 하지 않는다.
  void reportProgress(ChallengeType type, num value) {
    final id = uid;
    if (id == null) return;
    for (final c in myChallenges.where((c) => c.metricType == type)) {
      unawaited(
        _challengeRepo.reportProgress(c.id, id, value).catchError((
          Object e,
          StackTrace stack,
        ) {
          debugPrint('챌린지 진행 상황을 저장하지 못했어요: $e\n$stack');
        }),
      );
    }
  }

  // ── 활동 요약 · 순위 ─────────────────────────────────────────────────
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
      for (final id in c.participantIds)
        (
          user: userFor(id),
          ratio: c.targetValue <= 0
              ? 0.0
              : ((progress[id] ?? 0) / c.targetValue).clamp(0.0, 1.0),
        ),
    ];
  }

  List<({User user, int pct})> _rankedParticipants(Challenge? c) {
    if (c == null) return [];
    final progress = _challengeProgress[c.id] ?? const {};
    final list = [
      for (final id in c.participantIds)
        (
          user: userFor(id),
          pct: c.targetValue <= 0
              ? 0
              : (((progress[id] ?? 0) / c.targetValue) * 100).round().clamp(
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

  // ── 챌린지 만들기 폼 ─────────────────────────────────────────────────

  /// 챌린지 생성 화면의 임시 입력값입니다. Challenge는 저장 시에만 만듭니다.
  final ChallengeDraft challengeDraft = ChallengeDraft();

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
      .map((id) => FriendViewModel.personById(id).nickname)
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
    final start = _today;
    final end = start.add(Duration(days: chDays.clamp(1, 365) - 1));
    return '${start.month}월 ${start.day}일 ~ ${end.month}월 ${end.day}일 ($chDays일)';
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

  /// 닉네임으로 초대할 친구를 켜고 끈다.
  void toggleChInvite(String n) {
    final id = _inviteeIdOf(n);
    challengeDraft.invitedUserIds.contains(id)
        ? challengeDraft.invitedUserIds.remove(id)
        : challengeDraft.invitedUserIds.add(id);
    notifyListeners();
  }

  String _inviteeIdOf(String nickname) => FriendViewModel.people
      .firstWhere(
        (u) => u.nickname == nickname,
        orElse: () => User(
          id: 'u_$nickname',
          nickname: nickname,
          emoji: '🙂',
          tint: 0xFFEDEDED,
        ),
      )
      .id;

  void setChPublic(bool v) {
    chPublic = v;
    notifyListeners();
  }

  void setChReward(String r) {
    chReward = r;
    notifyListeners();
  }

  /// 입력값으로 챌린지를 만든다. 목록에는 바로 넣어 화면에 반영하고, 저장은 이어서 기다린다.
  Future<void> createChallenge() async {
    final start = _today;
    final end = start.add(Duration(days: chDays.clamp(1, 365) - 1));
    final challenge = Challenge(
      id: 'c_${DateTime.now().microsecondsSinceEpoch}',
      title: chName,
      description:
          '매일 ${AppStateFormat.comma(chTarget)}$chUnit 달성 · 보상 $chReward',
      icon: chKindMeta[chKind]!.icon,
      category: chDurLabel,
      period: '${start.month}/${start.day} ~ ${end.month}/${end.day}',
      creatorId: _uid,
      participantIds: [_uid, ...challengeDraft.invitedUserIds],
      metricType: challengeDraft.type,
      targetValue: chTarget,
      isPublic: chPublic,
      rewardDescription: chRewardDesc,
    );
    challenges.add(challenge);
    notifyListeners();
    await _challengeRepo.create(challenge);
  }

  // ── 불러오기 · 삭제 ──────────────────────────────────────────────────

  /// 저장된 전체 챌린지와, 그중 내가 참여 중인 챌린지의 진행 상황을 불러온다.
  Future<void> loadForUid(String uid) async {
    this.uid = uid;
    try {
      // 저장소가 읽기 전용 목록을 줘도 참여 · 생성으로 늘릴 수 있게 복사해 둔다.
      challenges = List.of(await _challengeRepo.loadAll());
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
      onSyncFailed?.call('챌린지를 불러오지 못했어요.');
    }
    notifyListeners();
  }

  /// 계정 삭제 — 혼자 만든 챌린지는 지우고, 함께한 챌린지에서는 내가 빠진다.
  Future<void> deleteAll(String uid) => _challengeRepo.removeUser(uid);
}
