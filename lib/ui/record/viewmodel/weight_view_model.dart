import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/utils/date_format.dart';

class WeightViewModel extends ChangeNotifier {
  WeightViewModel({required this._weightRepo, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RecordRepository<WeightEntry> _weightRepo;
  final DateTime Function() _now;

  String get _todayKey => formatDateKey(_now());

  /// 서버에서 지우지 못했을 때 불린다 (목록에는 되돌려 놓은 뒤다).
  void Function()? onDeleteFailed;

  /// 서버 저장이 실패했을 때 불린다.
  void Function()? onSaveFailed;

  double weightInput = 56.7;
  void setWeightInput(double v) {
    weightInput = v;
    notifyListeners();
  }

  String _keyDaysAgo(int days) {
    final n = _now();
    return formatDateKey(DateTime(n.year, n.month, n.day - days));
  }

  String get _yesterdayKey => _keyDaysAgo(1);

  late List<WeightEntry> weightEntries = [
    for (final (i, kg) in const [
      (6, 57.6),
      (5, 57.5),
      (4, 57.3),
      (3, 57.2),
      (2, 57.0),
    ])
      WeightEntry(
        id: 'weight_seed_$i',
        userId: User.meId,
        kg: kg,
        dateKey: _keyDaysAgo(i),
        time: '07:30',
      ),
    WeightEntry(
      id: 'weight_seed',
      userId: User.meId,
      kg: 56.9,
      dateKey: _yesterdayKey,
      time: '어제',
    ),
  ];

  double? get latestWeightKg =>
      weightEntries.isEmpty ? null : weightEntries.last.kg;

  /// 오늘 이전에 가장 최근에 기록한 체중. 오늘 이미 저장했어도 그 값이 아니라
  /// 이전 기록과 비교해야 "어제보다" 변화가 맞게 나온다.
  double? get previousWeightKg {
    final today = _keyDaysAgo(0);
    for (final e in weightEntries.reversed) {
      if (e.dateKey != today) return e.kg;
    }
    return null;
  }

  String weightDiffFrom(double baseline) {
    final last = previousWeightKg ?? baseline;
    return '${(weightInput - last).toStringAsFixed(1)}kg';
  }

  String? uid;
  String get _uid => uid ?? User.meId;

  String get _clockTime => formatClockTime(_now());

  void logWeight() {
    final entry = WeightEntry(
      id: 'weight_${DateTime.now().microsecondsSinceEpoch}',
      userId: _uid,
      kg: weightInput,
      dateKey: _todayKey,
      time: _clockTime,
    );
    weightEntries.add(entry);
    notifyListeners();
    _saveWeight(entry);
  }

  /// 체중 한 건을 고쳐서 저장한다. 없는 id면 false.
  bool updateWeight(WeightEntry updated) {
    final i = weightEntries.indexWhere((e) => e.id == updated.id);
    if (i < 0) return false;
    weightEntries[i] = updated;
    notifyListeners();
    _saveWeight(updated);
    return true;
  }

  /// 체중 한 건을 지운다. 없는 id면 false. 서버에서 지우지 못하면 목록에 되돌리고 알린다.
  bool deleteWeight(String id) {
    final i = weightEntries.indexWhere((e) => e.id == id);
    if (i < 0) return false;
    final removed = weightEntries.removeAt(i);
    notifyListeners();
    final owner = uid;
    if (owner != null) {
      unawaited(
        _weightRepo.delete(owner, id).catchError((Object e, StackTrace stack) {
          debugPrint('체중 기록 삭제 실패: $e\n$stack');
          if (!weightEntries.any((x) => x.id == id)) {
            weightEntries.insert(i.clamp(0, weightEntries.length), removed);
            notifyListeners();
          }
          onDeleteFailed?.call();
        }),
      );
    }
    return true;
  }

  void _saveWeight(WeightEntry entry) {
    if (uid == null) return;
    unawaited(
      _weightRepo.save(uid!, entry).catchError((Object e, StackTrace stack) {
        debugPrint('체중 기록을 저장하지 못했어요: $e\n$stack');
        onSaveFailed?.call();
      }),
    );
  }

  Future<void> loadForUid(String uid, {required double fallbackKg}) async {
    this.uid = uid;
    try {
      weightEntries = await _weightRepo.loadAll(uid);
    } catch (e, stack) {
      debugPrint('체중 기록을 불러오지 못했어요: $e\n$stack');
      weightEntries = [];
    }
    weightInput = weightEntries.isNotEmpty ? weightEntries.last.kg : fallbackKg;
    notifyListeners();
  }

  Future<void> deleteAll(String uid) => _weightRepo.deleteAll(uid);
}
