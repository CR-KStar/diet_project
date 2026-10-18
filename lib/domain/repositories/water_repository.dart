import 'package:diet_project/domain/models/models.dart';

/// 물 기록을 저장하고 불러오는 저장소. (기록 한 건이 문서 하나입니다.)
abstract class WaterRepository {
  /// 이 계정이 [dateKey] 날짜에 남긴 물 기록 (마신 순서대로).
  Future<List<WaterEntry>> loadDay(String uid, String dateKey);

  /// 같은 id가 있으면 덮어씁니다 (용량을 고쳤을 때).
  Future<void> save(String uid, WaterEntry entry);

  Future<void> delete(String uid, String entryId);

  /// 이 계정의 물 기록을 전부 지웁니다 (계정 삭제 때 사용).
  Future<void> deleteAll(String uid);
}
