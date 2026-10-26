import 'dart:typed_data';

/// 식단 사진을 이 기기 안에 보관하는 곳.
///
/// 사진은 서버로 보내 저장하지 않는다 (AI 분석을 위해 한 번 보낼 뿐이다). 갤러리에서 원본을
/// 지워도 앱에서는 볼 수 있도록 앱 전용 공간에 복사본을 둔다. 앱을 지우거나 기기를 바꾸면 사라진다.
abstract class MealPhotoStore {
  /// [id]로 사진을 저장한다. 같은 id가 있으면 덮어쓴다.
  Future<void> save(String id, Uint8List bytes);

  /// 사진을 읽는다. 없으면(다른 기기에서 만든 기록 · 지워진 사진) null.
  Future<Uint8List?> load(String id);

  /// 사진 한 장을 지운다. 없어도 오류가 아니다.
  Future<void> delete(String id);

  /// 보관한 사진을 모두 지운다 (계정 삭제).
  Future<void> deleteAll();
}
