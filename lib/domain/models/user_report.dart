import 'package:diet_project/domain/models/report_reason.dart';

/// 다른 사용자에 대한 신고 한 건 — 운영자가 검토한다.
class UserReport {
  const UserReport({
    required this.reporterUid,
    required this.targetUid,
    required this.targetNickname,
    required this.reason,
    this.detail = '',
  });

  final String reporterUid;
  final String targetUid;

  /// 신고 당시 상대의 닉네임 (상대가 나중에 바꿔도 무엇을 신고했는지 남도록).
  final String targetNickname;
  final ReportReason reason;

  /// 신고자가 덧붙인 설명 (선택).
  final String detail;
}
