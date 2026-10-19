/// 하루에 쓸 수 있는 AI 호출 횟수를 모두 쓴 경우. 일반 실패와 달리 다시 시도해도 소용없고,
/// 사용자에게 "내일 다시"라고 알려야 한다.
class AiQuotaExceeded implements Exception {
  const AiQuotaExceeded();

  @override
  String toString() => 'AiQuotaExceeded';
}
