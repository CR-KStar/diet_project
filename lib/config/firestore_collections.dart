/// Firestore 컬렉션 이름 — firestore.rules의 경로와 같아야 한다.
abstract final class FirestoreCollections {
  /// 사용자별 문서. 프로필과 하위 기록(물 · 체중 · 운동 …)이 이 아래에 있다.
  static const users = 'users';
  static const water = 'water';
  static const weight = 'weight';
  static const exercise = 'exercise';
  static const meals = 'meals';
  static const bowls = 'bowls';
  static const routines = 'routines';
  static const plant = 'plant';
  static const dexEntries = 'dexEntries';

  /// 친구 · 초대 · 공개 프로필 (사용자 사이의 관계라서 users 밖에 둔다).
  static const publicProfiles = 'publicProfiles';
  static const inviteCodes = 'inviteCodes';
  static const friendRequests = 'friendRequests';
  static const friendships = 'friendships';

  static const activityFeed = 'activityFeed';

  /// 내가 차단한 사용자 (users/{uid}/blocks) · 운영자에게 접수한 신고 (최상위).
  static const blocks = 'blocks';
  static const reports = 'reports';
  static const challenges = 'challenges';
  static const challengeProgress = 'challengeProgress';
}
