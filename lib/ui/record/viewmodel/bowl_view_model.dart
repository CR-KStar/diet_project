import 'dart:async';

import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/rules/diet_rules.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';

/// 내 그릇 목록과 그릇 추가·수정 화면의 입력 상태를 담당한다.
///
/// 어떤 그릇으로 식사를 기록할지 고르는 일(식단 입력값과 만나는 부분)은
/// AppState가 맡고, 여기서는 그릇 자체만 다룬다.
class BowlViewModel extends ChangeNotifier {
  BowlViewModel({required RecordRepository<Bowl> bowlRepo})
    : _bowlRepo = bowlRepo;

  final RecordRepository<Bowl> _bowlRepo;

  String? uid;
  String get _uid => uid ?? User.meId;

  /// 서버 저장·삭제가 실패했을 때 사용자에게 보여줄 문구와 함께 불린다.
  void Function(String message)? onSyncFailed;

  bool bowlSheet = false;
  int? bowlEditing; // null = 편집 중 아님, -1 = 신규 추가
  int bowlIndex = 0;

  List<Bowl> bowls = [
    Bowl(
      id: 'bowl_lunchbox',
      userId: User.meId,
      name: '회사 도시락',
      capacityMl: 500,
      portion: '1인분',
      material: '플라스틱',
      shape: '도시락',
      memo: '항상 가득 채워 먹음',
      isDefault: true,
      icon: '🍱',
    ),
    Bowl(
      id: 'bowl_home',
      userId: User.meId,
      name: '집 밥그릇',
      capacityMl: 300,
      portion: '소',
      material: '도자기',
      shape: '원형',
      memo: '반만 채움',
      icon: '🍚',
    ),
    Bowl(
      id: 'bowl_salad',
      userId: User.meId,
      name: '샐러드 볼',
      capacityMl: 900,
      portion: '대',
      material: '유리',
      shape: '원형',
      memo: '드레싱 따로',
      icon: '🥗',
    ),
    Bowl(
      id: 'bowl_tumbler',
      userId: User.meId,
      name: '텀블러',
      capacityMl: 450,
      portion: '중',
      material: '스테인리스',
      shape: '컵',
      memo: '물 기록용',
      icon: '☕',
    ),
  ];

  static Bowl _emptyBowl() => Bowl(
    id: '',
    userId: User.meId,
    name: '',
    capacityMl: 400,
    portion: '1인분',
    material: '플라스틱',
    shape: '원형',
  );

  Bowl draftBowl = _emptyBowl();

  /// 지금 선택된 그릇 — 등록한 그릇이 하나도 없으면 null (그릇 없이도 기록할 수 있다).
  Bowl? get currentBowl =>
      bowls.isEmpty ? null : bowls[bowlIndex.clamp(0, bowls.length - 1)];

  void startAddBowl() {
    draftBowl = _emptyBowl();
    bowlEditing = -1;
    notifyListeners();
  }

  void startEditBowl(int i) {
    final b = bowls[i];
    draftBowl = Bowl(
      id: b.id,
      userId: b.userId,
      name: b.name,
      capacityMl: b.capacityMl,
      portion: b.portion,
      material: b.material,
      shape: b.shape,
      memo: b.memo,
      isDefault: b.isDefault,
      icon: b.icon,
    );
    bowlEditing = i;
    notifyListeners();
  }

  void cancelBowlEdit() {
    bowlEditing = null;
    notifyListeners();
  }

  /// 입력 중인 그릇을 저장한다. 이름이 비었거나 개수 한도를 넘으면 false.
  bool saveBowl() {
    if (draftBowl.name.trim().isEmpty) return false;
    final changed = <Bowl>[];
    if (draftBowl.isDefault) {
      for (final b in bowls) {
        if (b.isDefault) {
          b.isDefault = false;
          changed.add(b);
        }
      }
    }
    if (bowlEditing == -1) {
      if (bowls.length >= DietRules.maxBowls) return false;
      final created = Bowl(
        id: 'bowl_${DateTime.now().microsecondsSinceEpoch}',
        userId: _uid,
        name: draftBowl.name,
        capacityMl: draftBowl.capacityMl,
        portion: draftBowl.portion,
        material: draftBowl.material,
        shape: draftBowl.shape,
        memo: draftBowl.memo,
        isDefault: draftBowl.isDefault,
        icon: draftBowl.icon,
      );
      bowls.add(created);
      changed.add(created);
    } else if (bowlEditing != null) {
      bowls[bowlEditing!] = draftBowl;
      changed.add(draftBowl);
    }
    bowlEditing = null;
    notifyListeners();
    for (final b in {for (final b in changed) b.id: b}.values) {
      _save(b);
    }
    return true;
  }

  void removeBowl(int i) {
    final removed = bowls.removeAt(i);
    if (bowlIndex >= bowls.length) bowlIndex = 0;
    bowlEditing = null;
    notifyListeners();
    _delete(removed.id);
  }

  void _save(Bowl b) {
    if (uid == null) return;
    unawaited(
      _bowlRepo.save(uid!, b).catchError((Object e, StackTrace stack) {
        debugPrint('그릇 저장 실패: $e\n$stack');
        onSyncFailed?.call('그릇 저장에 실패했어요. 네트워크를 확인해 주세요.');
      }),
    );
  }

  void _delete(String id) {
    if (uid == null) return;
    unawaited(
      _bowlRepo.delete(uid!, id).catchError((Object e, StackTrace stack) {
        debugPrint('그릇 삭제 실패: $e\n$stack');
        onSyncFailed?.call('그릇 삭제에 실패했어요. 네트워크를 확인해 주세요.');
      }),
    );
  }

  /// 로그인한 계정의 그릇을 서버에서 불러와 예시 그릇을 대체한다. 실패하면 false.
  Future<bool> loadForUid(String uid) async {
    this.uid = uid;
    var ok = true;
    try {
      bowls = await _bowlRepo.loadAll(uid);
    } catch (e, stack) {
      debugPrint('그릇을 불러오지 못했어요: $e\n$stack');
      bowls = [];
      ok = false;
    }
    bowlIndex = 0;
    notifyListeners();
    return ok;
  }

  /// 예시 그릇을 비운다 (실제 계정으로 로그인할 때).
  void clear() {
    bowls = [];
    bowlIndex = 0;
    notifyListeners();
  }

  Future<void> deleteAll(String uid) => _bowlRepo.deleteAll(uid);
}
