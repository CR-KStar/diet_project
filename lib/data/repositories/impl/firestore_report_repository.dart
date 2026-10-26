import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diet_project/config/firestore_collections.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/report_repository.dart';

/// 신고를 최상위 `reports` 컬렉션에 쌓는다. 보안 규칙상 앱은 만들기만 할 수 있고
/// 읽거나 고치거나 지울 수 없다 — 운영자가 콘솔에서 검토한다.
class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository({FirebaseFirestore? db}) : _injected = db;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  @override
  Future<void> submit(UserReport report) {
    return _db.collection(FirestoreCollections.reports).add({
      'reporterUid': report.reporterUid,
      'targetUid': report.targetUid,
      'targetNickname': report.targetNickname,
      'reason': report.reason.name,
      'detail': report.detail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
