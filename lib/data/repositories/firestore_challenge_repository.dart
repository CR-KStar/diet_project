import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diet_project/domain/models/models.dart';

import 'challenge_repository.dart';

/// 챌린지를 Firestore 최상위 `challenges` 컬렉션에 저장하는 저장소.
///
/// users/{uid} 밑이 아니다 — 챌린지는 여러 사용자가 같이 보고 참여하는
/// 공유 데이터라서다. 참여자별 오늘 진행 상황은 별도의 `challengeProgress`
/// 컬렉션(문서 id: `{challengeId}_{uid}`)에 각자 자기 것만 쓴다.
class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository({FirebaseFirestore? db}) : _injected = db;

  final FirebaseFirestore? _injected;

  // AppState가 만들어지는 시점(테스트 포함)엔 Firebase가 아직 초기화되지
  // 않았을 수 있어서, 실제로 어떤 메서드가 호출될 때만 늦게 가져온다.
  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('challenges');

  CollectionReference<Map<String, dynamic>> get _progressCol =>
      _db.collection('challengeProgress');

  @override
  Future<List<Challenge>> loadAll() async {
    final snap = await _col.get();
    return [for (final d in snap.docs) _fromMap(d.id, d.data())];
  }

  @override
  Future<void> create(Challenge challenge) {
    return _col.doc(challenge.id).set(_toMap(challenge));
  }

  @override
  Future<void> join(String challengeId, String userId) {
    return _col.doc(challengeId).update({
      'participantIds': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> reportProgress(String challengeId, String userId, num value) {
    return _progressCol.doc('${challengeId}_$userId').set({
      'challengeId': challengeId,
      'uid': userId,
      'value': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, num>> loadProgress(
    String challengeId,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    final result = <String, num>{for (final id in userIds) id: 0};
    // 문서 id를 알고 있으니 whereIn 없이 개별 조회로 간단히 처리한다.
    final docs = await Future.wait([
      for (final id in userIds) _progressCol.doc('${challengeId}_$id').get(),
    ]);
    for (final doc in docs) {
      final data = doc.data();
      if (data == null) continue;
      final uid = data['uid'];
      final value = data['value'];
      if (uid is String && value is num) result[uid] = value;
    }
    return result;
  }

  Map<String, Object?> _toMap(Challenge c) => {
    'title': c.title,
    'description': c.description,
    'icon': c.icon,
    'category': c.category,
    'period': c.period,
    'creatorId': c.creatorId,
    'participantIds': c.participantIds,
    'metricType': c.metricType.name,
    'targetValue': c.targetValue,
    'isPublic': c.isPublic,
    'rewardDescription': c.rewardDescription,
    'bonusDescription': c.bonusDescription,
  };

  Challenge _fromMap(String id, Map<String, dynamic> m) => Challenge(
    id: id,
    title: (m['title'] as String?) ?? '',
    description: (m['description'] as String?) ?? '',
    icon: (m['icon'] as String?) ?? '🎯',
    category: (m['category'] as String?) ?? '',
    period: (m['period'] as String?) ?? '',
    creatorId: (m['creatorId'] as String?) ?? '',
    participantIds: ((m['participantIds'] as List?) ?? const []).cast<String>(),
    metricType:
        ChallengeType.values.asNameMap()[m['metricType']] ??
        ChallengeType.water,
    targetValue: (m['targetValue'] as num?) ?? 1,
    isPublic: m['isPublic'] as bool? ?? true,
    rewardDescription: (m['rewardDescription'] as String?) ?? '',
    bonusDescription: (m['bonusDescription'] as String?) ?? '',
  );
}
