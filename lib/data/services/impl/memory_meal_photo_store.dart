import 'dart:typed_data';

import 'package:diet_project/data/services/meal_photo_store.dart';

/// 메모리에만 보관하는 사진 보관소 — 테스트와 웹(파일 저장 불가)이 쓴다.
/// 앱을 닫거나 새로고침하면 사라진다.
class MemoryMealPhotoStore implements MealPhotoStore {
  final Map<String, Uint8List> _photos = {};

  @override
  Future<void> save(String id, Uint8List bytes) async => _photos[id] = bytes;

  @override
  Future<Uint8List?> load(String id) async => _photos[id];

  @override
  Future<void> delete(String id) async => _photos.remove(id);

  @override
  Future<void> deleteAll() async => _photos.clear();
}
