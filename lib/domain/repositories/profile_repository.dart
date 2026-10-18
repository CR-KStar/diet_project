import 'package:diet_project/domain/models/models.dart';

/// 계정별 프로필을 저장하고 불러오는 저장소.
abstract class ProfileRepository {
  /// 저장된 프로필이 없으면(처음 가입) null.
  Future<SavedProfile?> load(String uid);

  Future<void> save(String uid, SavedProfile profile);

  Future<void> delete(String uid);
}
