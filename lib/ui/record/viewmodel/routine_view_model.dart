import 'dart:async';

import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';

/// 자주 하는 운동을 저장해 두는 "내 루틴"을 담당한다.
///
/// 루틴을 불러와 운동 입력값에 채우는 일은 운동 ViewModel과 만나는 부분이라
/// AppState가 맡고, 여기서는 루틴 목록과 저장·삭제만 다룬다.
class RoutineViewModel extends ChangeNotifier {
  RoutineViewModel({required RecordRepository<Routine> routineRepo})
    : _routineRepo = routineRepo;

  final RecordRepository<Routine> _routineRepo;

  String? uid;
  String get _uid => uid ?? User.meId;

  /// 서버 저장·삭제가 실패했을 때 사용자에게 보여줄 문구와 함께 불린다.
  void Function(String message)? onSyncFailed;

  List<Routine> routines = [
    Routine(
      id: 'routine_morning_run',
      userId: User.meId,
      name: '아침 러닝',
      type: '달리기',
      minutes: 30,
      intensity: ExerciseIntensity.moderate,
      icon: '🏃',
      used: 12,
      weeklyUsed: 3,
    ),
    Routine(
      id: 'routine_home_workout',
      userId: User.meId,
      name: '홈트 세트',
      type: '근력',
      minutes: 40,
      intensity: ExerciseIntensity.high,
      icon: '🏋️',
      used: 8,
      weeklyUsed: 2,
    ),
    Routine(
      id: 'routine_evening_walk',
      userId: User.meId,
      name: '저녁 산책',
      type: '걷기',
      minutes: 25,
      intensity: ExerciseIntensity.low,
      icon: '🚶',
      used: 5,
      weeklyUsed: 1,
    ),
  ];

  static const _routineIcons = {
    '달리기': '🏃',
    '걷기': '🚶',
    '자전거': '🚴',
    '근력': '🏋️',
    '요가': '🧘',
    '수영': '🏊',
    '등산': '🥾',
  };

  /// "내 루틴" 카드에서 추가/삭제 컨트롤(✕)을 보여줄지 여부
  bool routineEditMode = false;

  void toggleRoutineEditMode() {
    routineEditMode = !routineEditMode;
    notifyListeners();
  }

  /// 운동 종류 · 시간 · 강도로 새 루틴을 만들어 저장한다.
  void addRoutine({
    required String type,
    required int minutes,
    required ExerciseIntensity intensity,
  }) {
    final routine = Routine(
      id: 'routine_${DateTime.now().microsecondsSinceEpoch}',
      userId: _uid,
      name: '$type $minutes분',
      type: type,
      minutes: minutes,
      intensity: intensity,
      icon: _routineIcons[type.trim()] ?? '💪',
    );
    routines.add(routine);
    notifyListeners();
    _save(routine);
  }

  void removeRoutine(Routine r) {
    routines.remove(r);
    notifyListeners();
    _delete(r.id);
  }

  void _save(Routine r) {
    if (uid == null) return;
    unawaited(
      _routineRepo.save(uid!, r).catchError((Object e, StackTrace stack) {
        debugPrint('운동 루틴 저장 실패: $e\n$stack');
        onSyncFailed?.call('운동 루틴 저장에 실패했어요. 네트워크를 확인해 주세요.');
      }),
    );
  }

  void _delete(String id) {
    if (uid == null) return;
    unawaited(
      _routineRepo.delete(uid!, id).catchError((Object e, StackTrace stack) {
        debugPrint('운동 루틴 삭제 실패: $e\n$stack');
        onSyncFailed?.call('운동 루틴 삭제에 실패했어요. 네트워크를 확인해 주세요.');
      }),
    );
  }

  /// 로그인한 계정의 루틴을 서버에서 불러와 예시 루틴을 대체한다. 실패하면 false.
  Future<bool> loadForUid(String uid) async {
    this.uid = uid;
    var ok = true;
    try {
      routines = await _routineRepo.loadAll(uid);
    } catch (e, stack) {
      debugPrint('운동 루틴을 불러오지 못했어요: $e\n$stack');
      routines = [];
      ok = false;
    }
    notifyListeners();
    return ok;
  }

  /// 예시 루틴을 비운다 (실제 계정으로 로그인할 때).
  void clear() {
    routines = [];
    notifyListeners();
  }

  Future<void> deleteAll(String uid) => _routineRepo.deleteAll(uid);
}
