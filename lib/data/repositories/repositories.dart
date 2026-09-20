import 'package:diet_project/domain/models/models.dart';

/// 전체 챌린지 목록을 저장하고 관리하는 저장소.
///
/// Challenge 모델은 "챌린지 하나의 모양"만 설명한다. 지금 존재하는
/// 챌린지들을 어떻게 담아두고 · 찾고 · 새로 만들고 · 참여시킬지는
/// 모델이 아니라 이 저장소가 맡는다. 지금은 메모리(리스트)에만
/// 들고 있지만, 나중에 서버나 로컬 DB로 옮기더라도 AppState는
/// 이 클래스가 제공하는 메서드 이름과 사용법을 그대로 쓸 수 있다.
class ChallengeRepository {
  ChallengeRepository({List<Challenge>? seed}) : _all = seed ?? _seed();

  final List<Challenge> _all;

  static List<Challenge> _seed() => [
        Challenge(
          id: 'c_water_2l',
          title: '오늘 물 2L 마시기',
          description: '자정까지 물 2,000ml 기록하기',
          icon: '💧',
          category: '데일리',
          period: '오늘 하루',
          creatorId: 'u_jihyun',
          participantIds: ['u_jihyun', 'u_minsu', 'u_seoyeon'],
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
          isPublic: true,
          rewardDescription: '확정 전설 씨앗 + 정원 장식',
          bonusDescription: '보너스 10% 스페셜 아이템 · 실패 시 눈바디 전송',
        ),
      ];

  /// 전체 챌린지 (읽기 전용 복사본)
  List<Challenge> all() => List.unmodifiable(_all);

  /// 공개 챌린지 중 아직 이 사용자가 참여하지 않은 것
  List<Challenge> joinable(String userId) =>
      _all.where((c) => c.isPublic && !c.isParticipant(userId)).toList();

  /// 이 사용자가 만들었거나 참여 중인 챌린지
  List<Challenge> mine(String userId) =>
      _all.where((c) => c.isParticipant(userId)).toList();

  void create(Challenge challenge) {
    _all.add(challenge);
  }

  void join(String challengeId, String userId) {
    final target = _all.where((c) => c.id == challengeId);
    if (target.isEmpty) return;
    final challenge = target.first;
    if (!challenge.participantIds.contains(userId)) {
      challenge.participantIds.add(userId);
    }
  }
}

/// 도감 카탈로그(PlantSpecies)와 사용자별 수집 상태(DexEntry)를 이어주는 저장소.
///
/// PlantSpecies.catalog는 모두가 같은 값을 본다. 그 카탈로그의 각 종을
/// "이 userId가 획득했는지 · 진행률이 몇 %인지"는 DexEntry로 따로 들고
/// 있다가, 화면에 보여줄 때만 DexCard로 합쳐서 내놓는다.
class DexRepository {
  DexRepository({List<DexEntry>? seed}) : _entries = seed ?? _seed();

  final List<DexEntry> _entries;

  static List<DexEntry> _seed() {
    // 기존 프로토타입의 획득 상태를 그대로 시드 데이터로 옮겼다.
    const owned = <String, int>{
      'sp_tulip': 100, 'sp_sunflower': 100, 'sp_rose': 100, 'sp_daisy': 100,
      'sp_monstera': 100, 'sp_cactus': 100, 'sp_sprout': 100, 'sp_cherry_blossom': 100,
    };
    const inProgress = <String, int>{
      'sp_rubber_tree': 62, 'sp_clover': 75, 'sp_rice': 40, 'sp_lotus': 55,
      'sp_moss_fern': 30, 'sp_conifer': 45, 'sp_bamboo': 20,
      'sp_mutant_tulip': 12, 'sp_golden_rose': 33, 'sp_rare_hibiscus': 8,
    };
    return [
      for (final sp in PlantSpecies.catalog)
        DexEntry(
          userId: User.meId,
          speciesId: sp.id,
          owned: owned.containsKey(sp.id),
          progress: owned[sp.id] ?? inProgress[sp.id] ?? 0,
        ),
    ];
  }

  DexEntry _entryFor(String userId, String speciesId) => _entries.firstWhere(
        (e) => e.userId == userId && e.speciesId == speciesId,
        orElse: () => DexEntry(userId: userId, speciesId: speciesId),
      );

  /// userId가 본 도감 전체 — 카탈로그 순서 그대로, 각 종에 그 사람의 수집 상태를 붙여서.
  List<DexCard> cardsFor(String userId) =>
      PlantSpecies.catalog.map((sp) => DexCard(sp, _entryFor(userId, sp.id))).toList();
}
