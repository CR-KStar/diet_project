import 'package:diet_project/domain/models/models.dart';

/// 챌린지 저장소.
///
/// 챌린지는 "내 기록"이 아니라 여러 사용자가 함께 보는 공유 데이터라서,
/// 다른 저장소들처럼 users/{uid} 밑에 담기지 않는다 — 전체 목록을 한
/// 공간(구현체마다 다름)에 두고, 누구나 만들고 참여할 수 있게 한다.
abstract class ChallengeRepository {
  Future<List<Challenge>> loadAll();

  Future<void> create(Challenge challenge);

  /// challengeId에 userId를 참여자로 추가한다. 이미 참여 중이면 아무 일도
  /// 하지 않는다.
  Future<void> join(String challengeId, String userId);

  /// userId의 오늘 진행 상황을 challengeId에 보고한다(리더보드용).
  Future<void> reportProgress(String challengeId, String userId, num value);

  /// challengeId에 대한 userIds 각각의 오늘 진행 상황. 보고한 적 없으면 0.
  Future<Map<String, num>> loadProgress(
    String challengeId,
    List<String> userIds,
  );

  /// 계정 삭제 때 이 사용자를 챌린지에서 뺀다.
  /// 혼자 만들고 혼자 참여한 챌린지는 삭제하고, 다른 사람이 함께하는 챌린지는
  /// 참여자 목록에서만 이 사용자를 지운다. 이 사용자의 진행 기록도 지운다.
  Future<void> removeUser(String userId);
}
