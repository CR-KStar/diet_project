/// 다른 사용자를 신고하는 사유.
enum ReportReason {
  inappropriateName('부적절한 닉네임'),
  harassment('괴롭힘 · 욕설'),
  spam('스팸 · 광고'),
  other('기타');

  const ReportReason(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
