import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/report_repository.dart';

/// 접수한 신고를 메모리에만 담아 두는 저장소 — 테스트와 체험판이 쓴다.
class MemoryReportRepository implements ReportRepository {
  final List<UserReport> submitted = [];

  @override
  Future<void> submit(UserReport report) async => submitted.add(report);
}
