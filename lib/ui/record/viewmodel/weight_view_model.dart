import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class WeightViewModel extends ChangeNotifier {
  WeightViewModel({
    required RecordRepository<WeightEntry> weightRepo,
    DateTime Function()? now,
  }) : _weightRepo = weightRepo,
       _now = now ?? DateTime.now;

  final RecordRepository<WeightEntry> _weightRepo;
  final DateTime Function() _now;

  String get _todayKey {
    final n = _now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  double weightInput = 56.7;
  void setWeightInput(double v) {
    weightInput = v;
    notifyListeners();
  }

  String _keyDaysAgo(int days) {
    final n = _now();
    final y = DateTime(n.year, n.month, n.day - days);
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
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

  String get _clockTime {
    final n = _now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

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

  void _saveWeight(WeightEntry entry) {
    if (uid == null) return;
    unawaited(
      _weightRepo.save(uid!, entry).catchError((Object e, StackTrace stack) {
        debugPrint('체중 기록을 저장하지 못했어요: $e\n$stack');
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
