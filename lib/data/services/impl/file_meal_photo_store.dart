import 'dart:io';

import 'package:diet_project/data/services/meal_photo_store.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 앱 전용 폴더에 사진을 파일로 보관한다. 갤러리와 따로 있는 복사본이라
/// 폰에서 원본을 지워도 남는다. (iOS · Android 전용 — 웹은 [MemoryMealPhotoStore])
class FileMealPhotoStore implements MealPhotoStore {
  /// [baseDir]은 테스트에서 임시 폴더를 넣기 위한 것이다. 기본은 앱 전용 지원 폴더 아래 `meal_photos`.
  FileMealPhotoStore({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? _defaultDir;

  final Future<Directory> Function() _baseDir;

  /// 방금 저장한 사진은 파일을 다시 읽지 않고 바로 돌려주려고 잠깐 들고 있는다.
  final Map<String, Uint8List> _recent = {};

  static Future<Directory> _defaultDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/meal_photos');
  }

  /// 파일 이름으로 쓰기 안전한 id만 받는다 (`../` 같은 경로가 섞이지 않게).
  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,80}$');

  Future<File?> _file(String id) async {
    if (!_safeId.hasMatch(id)) return null;
    final dir = await _baseDir();
    return File('${dir.path}/$id.jpg');
  }

  @override
  Future<void> save(String id, Uint8List bytes) async {
    final file = await _file(id);
    if (file == null) return;
    _recent[id] = bytes;
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> load(String id) async {
    final cached = _recent[id];
    if (cached != null) return cached;
    try {
      final file = await _file(id);
      if (file == null || !await file.exists()) return null;
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('식단 사진을 읽지 못했어요: $e');
      return null;
    }
  }

  @override
  Future<void> delete(String id) async {
    _recent.remove(id);
    try {
      final file = await _file(id);
      if (file != null && await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('식단 사진을 지우지 못했어요: $e');
    }
  }

  @override
  Future<void> deleteAll() async {
    _recent.clear();
    try {
      final dir = await _baseDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('식단 사진을 모두 지우지 못했어요: $e');
    }
  }
}
