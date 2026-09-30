import 'package:diet_project/data/repositories/water_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class WaterViewModel extends ChangeNotifier {
  WaterViewModel({required WaterRepository waterRepo, DateTime Function()? now})
    : _waterRepo = waterRepo,
      _now = now ?? DateTime.now;

  final WaterRepository _waterRepo;

  /// 테스트에서 날짜를 고정할 수 있도록 시계를 주입받는다 (AppState와 같은 패턴).
  final DateTime Function() _now;

  String get _todayKey {
    final n = _now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  bool waterSheet = false;
  int waterInput = 250;

  void setWaterInput(int v) {
    waterInput = v;
    notifyListeners();
  }

  late List<WaterEntry> waterEntries = [
    WaterEntry(
      id: 'water_seed_1',
      userId: User.meId,
      ml: 250,
      dateKey: _todayKey,
      time: '08:10',
    ),
    WaterEntry(
      id: 'water_seed_2',
      userId: User.meId,
      ml: 350,
      dateKey: _todayKey,
      time: '10:30',
    ),
    WaterEntry(
      id: 'water_seed_3',
      userId: User.meId,
      ml: 500,
      dateKey: _todayKey,
      time: '12:45',
    ),
    WaterEntry(
      id: 'water_seed_4',
      userId: User.meId,
      ml: 350,
      dateKey: _todayKey,
      time: '15:20',
    ),
  ];

  late String _waterDayKey = _todayKey;

  String? uid;
  String get _uid => uid ?? User.meId;

  /// 로그인한 실제 계정의 오늘 물 기록을 서버에서 불러와서, 데모용
  /// 예시 데이터(waterEntries의 기본값)를 실제 데이터로 덮어쓴다.
  Future<void> loadForUid(String uid) async {
    this.uid = uid;
    _waterDayKey = _todayKey;
    try {
      waterEntries = await _waterRepo.loadDay(uid, _todayKey);
    } catch (e, stack) {
      debugPrint('물 기록을 불러오지 못했어요: $e\n$stack');
      waterEntries = [];
    }
    notifyListeners();
  }

  String get _clockTime {
    final n = _now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  int _waterSeq = 0;

  final Map<String, Timer> _waterEditTimers = {};
  static const _waterEditDelay = Duration(milliseconds: 500);

  void _rollWaterDay() {
    if (_waterDayKey == _todayKey) return;
    waterEntries = [];
    _waterDayKey = _todayKey;
  }

  int get waterTotal => waterEntries.fold(0, (a, e) => a + e.ml);
  int get waterLeft => (2000 - waterTotal).clamp(0, 2000);
  int get waterPct => ((waterTotal / 2000) * 100).round().clamp(0, 100);

  void addWater([int? ml]) {
    final v = ml ?? waterInput;
    if (v <= 0) return;
    _rollWaterDay();
    final entry = WaterEntry(
      id: 'water_${DateTime.now().microsecondsSinceEpoch}_${_waterSeq++}',
      userId: _uid,
      ml: v,
      dateKey: _waterDayKey,
      time: _clockTime,
    );
    waterEntries.add(entry);
    notifyListeners();
    _saveWater(entry);
  }

  void _saveWater(WaterEntry entry) {
    if (uid == null) return;
    unawaited(
      _waterRepo.save(uid!, entry).catchError((Object e, StackTrace stack) {
        debugPrint('물 기록을 저장하지 못했어요: $e\n$stack');
      }),
    );
  }

  void _removeWaterEntry(WaterEntry entry) {
    _waterEditTimers.remove(entry.id)?.cancel();
    notifyListeners();
    if (uid == null) return;
    unawaited(
      _waterRepo.delete(uid!, entry.id).catchError((
        Object e,
        StackTrace stack,
      ) {
        debugPrint('물 기록을 지우지 못했어요: $e\n$stack');
      }),
    );
  }

  void editWater(int i, int ml) {
    final entry = waterEntries[i];
    entry.ml = ml.clamp(0, 3000);
    notifyListeners();
    _waterEditTimers[entry.id]?.cancel();
    _waterEditTimers[entry.id] = Timer(_waterEditDelay, () {
      _waterEditTimers.remove(entry.id);
      _saveWater(entry);
    });
  }

  void removeWater(int i) => _removeWaterEntry(waterEntries.removeAt(i));

  void undoWater() {
    if (waterEntries.isNotEmpty) _removeWaterEntry(waterEntries.removeLast());
  }

  Future<void> deleteAll(String uid) => _waterRepo.deleteAll(uid);
}
