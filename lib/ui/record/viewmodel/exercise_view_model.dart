import 'dart:async';

import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/rules/diet_rules.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/utils/date_format.dart';

/// 운동 화면의 입력값(Draft)과 저장된 운동 기록을 담당한다.
///
/// 어떤 날짜의 운동을 보여줄지(기록 탭의 달력)는 여러 기록이 함께 쓰는 값이라
/// AppState가 갖고 있고, 여기서는 날짜를 매번 넘겨받는다.
class ExerciseViewModel extends ChangeNotifier {
  ExerciseViewModel({required this._exerciseRepo, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RecordRepository<ExerciseLog> _exerciseRepo;

  /// 테스트에서 시간을 고정할 수 있도록 시계를 주입받는다 (AppState와 같은 패턴).
  final DateTime Function() _now;

  String? uid;
  String get _uid => uid ?? User.meId;

  /// 서버 저장이 실패했을 때 불린다. AppState가 사용자에게 알림을 띄우는 데 쓴다.
  void Function()? onSaveFailed;

  String get _clockTime => formatClockTime(_now());

  // ── 입력값 (저장 전까지만 유지되는 Draft) ─────────────────────────────
  final ExerciseDraft exerciseDraft = ExerciseDraft();

  String get exType => exerciseDraft.type;
  set exType(String value) => exerciseDraft.type = value;

  int get exMinutes => exerciseDraft.minutes;
  set exMinutes(int value) => exerciseDraft.minutes = value;

  String get exIntensity => exerciseDraft.intensity.label;
  set exIntensity(String value) => exerciseDraft.intensity = switch (value) {
    '낮음' => ExerciseIntensity.low,
    '높음' => ExerciseIntensity.high,
    _ => ExerciseIntensity.moderate,
  };

  bool get exTypeKnown =>
      DietRules.exerciseTypeFactor.containsKey(exType.trim());

  int get exKcal {
    final f = DietRules.exerciseTypeFactor[exType.trim()] ?? 1.0;
    final i = DietRules.exerciseIntensityFactor[exIntensity] ?? 8;
    return (exMinutes * i * f).round();
  }

  // ── 저장된 기록 ──────────────────────────────────────────────────────
  final List<ExerciseLog> exerciseLogs = [];

  /// 특정 날짜([dateKey])의 내 운동 기록.
  List<ExerciseLog> exercisesOn(String dateKey) => exerciseLogs
      .where((e) => e.userId == _uid && e.dateKey == dateKey)
      .toList();

  /// 특정 날짜의 운동 시간 합계(분).
  int minutesOn(String dateKey) =>
      exercisesOn(dateKey).fold(0, (a, e) => a + e.minutes);

  /// 지금 입력값으로 [dateKey] 날짜의 운동 기록 한 건을 만든다(저장은 [addExercise]).
  ExerciseLog logFromDraft({required String dateKey}) => ExerciseLog(
    id: 'ex_${DateTime.now().microsecondsSinceEpoch}',
    userId: _uid,
    type: exType,
    minutes: exMinutes,
    intensity: exerciseDraft.intensity,
    kcal: exKcal,
    dateKey: dateKey,
    time: _clockTime,
  );

  /// 운동 한 건을 목록에 추가하고, 로그인한 계정이면 서버에도 저장한다.
  void addExercise(ExerciseLog log) {
    exerciseLogs.add(log);
    notifyListeners();
    _saveExercise(log);
  }

  void _saveExercise(ExerciseLog log) {
    if (uid == null) return;
    unawaited(
      _exerciseRepo.save(uid!, log).catchError((Object e, StackTrace stack) {
        debugPrint('운동 기록 저장 실패: $e\n$stack');
        onSaveFailed?.call();
      }),
    );
  }

  /// 예시 기록을 비운다 (실제 계정으로 로그인할 때).
  void clear() {
    exerciseLogs.clear();
    notifyListeners();
  }

  /// 서버에서 불러온 기록 중 목록에 없는 것만 합친다.
  void mergeLoaded(List<ExerciseLog> loaded) {
    final have = {for (final e in exerciseLogs) e.id};
    exerciseLogs.addAll(loaded.where((e) => !have.contains(e.id)));
    notifyListeners();
  }
}
