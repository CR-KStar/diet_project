import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/challenge_repository.dart';

/// Firebase 없이 메모리에만 저장하는 버전 — 데모 모드 · 테스트용.
class MemoryChallengeRepository implements ChallengeRepository {
  MemoryChallengeRepository({List<Challenge>? seed}) : _all = seed ?? _seed();

  final List<Challenge> _all;
  final Map<String, num> _progress = {}; // '{challengeId}_{userId}' -> value

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

  @override
  Future<List<Challenge>> loadAll() async => List.unmodifiable(_all);

  @override
  Future<void> create(Challenge challenge) async {
    _all.add(challenge);
  }

  @override
  Future<void> join(String challengeId, String userId) async {
    final target = _all.where((c) => c.id == challengeId);
    if (target.isEmpty) return;
    final challenge = target.first;
    if (!challenge.participantIds.contains(userId)) {
      challenge.participantIds.add(userId);
    }
  }

  @override
  Future<void> leave(String challengeId, String userId) async {
    for (final c in _all.where((c) => c.id == challengeId)) {
      c.participantIds.remove(userId);
    }
    _progress.remove('${challengeId}_$userId');
  }

  @override
  Future<void> delete(String challengeId) async {
    _all.removeWhere((c) => c.id == challengeId);
    _progress.removeWhere((key, _) => key.startsWith('${challengeId}_'));
  }

  @override
  Future<void> reportProgress(
    String challengeId,
    String userId,
    num value,
  ) async {
    _progress['${challengeId}_$userId'] = value;
  }

  @override
  Future<Map<String, num>> loadProgress(
    String challengeId,
    List<String> userIds,
  ) async => {
    for (final id in userIds) id: _progress['${challengeId}_$id'] ?? 0,
  };

  @override
  Future<void> removeUser(String userId) async {
    _all.removeWhere(
      (c) =>
          c.creatorId == userId && c.participantIds.every((p) => p == userId),
    );
    for (final c in _all) {
      c.participantIds.remove(userId);
    }
    _progress.removeWhere((key, _) => key.endsWith('_$userId'));
  }
}
