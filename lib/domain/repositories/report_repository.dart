import 'package:diet_project/domain/models/models.dart';

/// 사용자 신고를 운영자에게 접수한다. 접수한 뒤에는 앱에서 다시 읽거나 지울 수 없다.
abstract class ReportRepository {
  Future<void> submit(UserReport report);
}
