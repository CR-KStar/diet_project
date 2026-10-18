/// 초대 코드 검색 등에서 쓰는, 다른 사람에게 공개되는 최소 프로필.
class PublicProfile {
  const PublicProfile({required this.uid, required this.nickname});

  final String uid;
  final String nickname;
}
