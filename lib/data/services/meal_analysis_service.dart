import 'package:diet_project/domain/models/models.dart';

/// 식사 사진을 보내 음식 이름과 영양소를 추정받는 서비스.
/// 화면 쪽(ViewModel)은 이 인터페이스만 알고, 실제 호출 방법(Cloud Functions)은 구현이 안다.
abstract class MealAnalysisService {
  /// [imageBase64] 사진, [mediaType] 파일 형식, [bowl] 사용한 그릇(있으면 양을 더 잘 가늠한다).
  Future<MealAnalysisResult> analyze({
    required String imageBase64,
    required String mediaType,
    ({String name, int capacityMl})? bowl,
  });
}
