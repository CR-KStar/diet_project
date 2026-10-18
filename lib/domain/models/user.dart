/// 앱 사용자 기본 정보
class User {
  const User({
    required this.id,
    required this.nickname,
    required this.emoji,
    required this.tint,
  });

  static const String meId = 'u_me';

  final String id;
  final String nickname;
  final String emoji;

  /// 프로필 배경색 (ARGB 값) — 실제 색으로 바꾸는 일은 화면이 한다.
  final int tint;
}
