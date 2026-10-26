import 'dart:typed_data';

import 'package:diet_project/data/services/meal_photo_store.dart';
import 'package:diet_project/ui/core/ui/widgets/photo_placeholder.dart';
import 'package:flutter/material.dart';

/// 식단 사진 — 이 기기에 보관한 사진을 보여준다.
///
/// 사진이 없거나(사진 없이 기록 · 다른 기기에서 만든 기록) 찾지 못하면 줄무늬 자리표시를 보인다.
/// [showPlaceholder]가 false면 사진이 있을 때만 그리고, 없으면 아무것도 그리지 않는다.
class MealPhoto extends StatefulWidget {
  const MealPhoto({
    super.key,
    required this.store,
    required this.photoId,
    required this.height,
    this.width,
    this.radius = 18,
    this.decodeWidth,
    this.showPlaceholder = true,
  });

  final MealPhotoStore store;
  final String? photoId;
  final double height;
  final double? width;
  final double radius;

  /// 목록 썸네일처럼 작게 보일 때, 원본을 이 너비로 줄여서 읽는다 (메모리 절약).
  final int? decodeWidth;
  final bool showPlaceholder;

  @override
  State<MealPhoto> createState() => _MealPhotoState();
}

class _MealPhotoState extends State<MealPhoto> {
  Future<Uint8List?>? _photo;

  @override
  void initState() {
    super.initState();
    _photo = _load();
  }

  @override
  void didUpdateWidget(MealPhoto old) {
    super.didUpdateWidget(old);
    if (old.photoId != widget.photoId || old.store != widget.store) {
      _photo = _load();
    }
  }

  Future<Uint8List?>? _load() {
    final id = widget.photoId;
    return id == null ? null : widget.store.load(id);
  }

  @override
  Widget build(BuildContext context) {
    // 사진이 없을 때 — 자리표시를 보이거나(목록), 아예 그리지 않는다(상세).
    final fallback = widget.showPlaceholder
        ? _sized(PhotoPlaceholder(height: widget.height, radius: widget.radius))
        : const SizedBox.shrink();
    final photo = _photo;
    if (photo == null) return fallback;

    return FutureBuilder<Uint8List?>(
      future: photo,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return fallback;
        return _sized(
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: widget.width ?? double.infinity,
              height: widget.height,
              cacheWidth: widget.decodeWidth,
              gaplessPlayback: true,
              // 파일이 깨졌으면 오류 화면 대신 자리표시를 보인다.
              errorBuilder: (context, error, stack) => fallback,
            ),
          ),
        );
      },
    );
  }

  Widget _sized(Widget child) =>
      SizedBox(width: widget.width, height: widget.height, child: child);
}
