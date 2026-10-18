import 'dart:async';

import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/rules/dex_rules.dart';
import 'package:diet_project/utils/date_format.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';

/// 하루가 바뀌었거나 기록이 바뀌었을 때, 식물 상태를 맞추는 데 필요한 값 — AppState가 만들어 준다.
class PlantSyncInput {
  const PlantSyncInput({
    required this.today,
    required this.hasRecordOn,
    required this.streakDays,
    required this.onboardingDone,
  });

  /// 오늘 (시간은 버리고 날짜만)
  final DateTime today;

  /// 그 날짜에 식단 · 운동 · 체중 · 물 중 하나라도 기록했는지.
  final bool Function(DateTime date) hasRecordOn;

  /// 지금 이어지고 있는 연속 기록 일수.
  final int streakDays;
  final bool onboardingDone;
}

/// 정원 화분 한 칸의 종류.
enum GardenPotKind { growing, collected, empty }

/// 정원 화분 한 칸 — 보여줄 그림(emoji), 이름, 종류.
typedef GardenPot = ({String emoji, String label, GardenPotKind kind});

/// "내 식물"의 성장 상태와 식물 도감(수집 현황)을 담당한다.
///
/// 성장 상태와 거기서 계산되는 값(레벨 · 시듦 여부 …)은 Plant 모델이,
/// 어떤 종이 있는지는 PlantSpecies.catalog가 맡고, 여기서는 그 둘을 들고
/// 계정에 저장하는 일만 한다. 식물은 자주 바뀌어서 저장은 잠깐 모아서 한 번만 한다.
class PlantViewModel extends ChangeNotifier {
  PlantViewModel({
    required RecordRepository<Plant> plantRepo,
    required RecordRepository<DexEntry> dexRepo,
    Duration saveDelay = const Duration(milliseconds: 500),
    DateTime Function()? now,
  }) : _plantRepo = plantRepo,
       _dexRepo = dexRepo,
       _saveDelay = saveDelay,
       _now = now ?? DateTime.now;

  final RecordRepository<Plant> _plantRepo;
  final RecordRepository<DexEntry> _dexRepo;
  final Duration _saveDelay;
  final DateTime Function() _now;

  String get _todayKey => formatDateKey(_now());

  String? uid;
  String get _uid => uid ?? User.meId;

  /// 서버 저장이 실패했거나 불러오지 못했을 때, 사용자에게 보여줄 문구와 함께 불린다.
  void Function(String message)? onSyncFailed;

  // ── 내 식물 ─────────────────────────────────────────────────────────
  Plant plant = Plant(
    userId: User.meId,
    exp: 240,
    axisScore: {PlantAxis.water: 82, PlantAxis.sun: 45, PlantAxis.nutri: 68},
    cares: {'물 주기': 3, '햇빛 받기': 2, '영양 주기': 2},
    missedDays: 0,
    inventory: {'물방울': 6, '희귀 씨앗': 2, '전설 씨앗': 0, '정원 장식': 1},
    giftTickets: 1,
  );

  Timer? _saveTimer;

  /// 식물을 불러오지 못했을 때는 저장도 멈춘다 (덮어쓰기 방지).
  bool _syncOk = true;

  void care(String name) {
    plant.care(name);
    notifyListeners();
    _scheduleSave();
  }

  /// "회복 돌보기" — 오늘 하루는 시들지 않은 것으로 한다.
  void revive() {
    plant.revive(_todayKey);
    notifyListeners();
    _scheduleSave();
  }

  /// friendUserId(친구의 User.id)의 정원에 물을 준다. 하루 한도는 날짜가 바뀌면 새로 시작한다.
  void waterFriend(String friendUserId) {
    if (plant.friendWaterKey != _todayKey) {
      plant.wateredFriendIds = [];
      plant.friendWaterKey = _todayKey;
    }
    if (!plant.waterFriend(friendUserId)) return;
    notifyListeners();
    _scheduleSave();
  }

  /// 보관함 아이템 사용 — 즉시 1개 소모하고 효과를 바로 반영해요.
  void useInventoryItem(String key) {
    plant.useInventoryItem(key);
    notifyListeners();
    _scheduleSave();
  }

  void sendGiftFlower() {
    if (!plant.sendGiftFlower()) return;
    notifyListeners();
    _scheduleSave();
  }

  /// 미션 보상 등으로 경험치를 얻는다.
  void gainExp(int amount) {
    plant.exp += amount;
    notifyListeners();
    _scheduleSave();
  }

  // ── 기록과 이어지는 성장 ─────────────────────────────────────────────

  /// 마지막으로 알게 된 "시작 안내(온보딩)를 마쳤는지" — 도감 조건에 쓴다.
  bool _onboardingDone = false;

  /// 기록을 하나 남겼을 때 — 누적 횟수를 세고, 그 기록에 맞는 돌보기를 1회 충전하고,
  /// 새로 열린 도감이 있는지 확인한다.
  void onRecorded(
    RecordKind kind, {
    int minutes = 0,
    int ml = 0,
    bool breakfast = false,
  }) {
    final t = plant.tally;
    switch (kind) {
      case RecordKind.meal:
        t.meals++;
        if (breakfast) t.breakfasts++;
      case RecordKind.exercise:
        t.exercises++;
        t.exerciseMinutes += minutes;
      case RecordKind.water:
        t.waterEntries++;
        t.waterMl += ml;
      case RecordKind.weight:
        t.weights++;
    }
    plant.recharge(kind);
    _evaluateDex();
    notifyListeners();
    _saveNow();
  }

  /// 하루가 바뀌었거나 기록이 바뀌었을 때 식물 상태를 맞춘다 — 기록을 쉰 날 수(시듦),
  /// 친구 물주기 하루 한도, 가장 긴 연속 기록, 도감 조건.
  void syncDay(PlantSyncInput input) {
    var changed = false;
    final todayKey = formatDateKey(input.today);

    if (plant.startedKey.isEmpty) {
      plant.startedKey = todayKey;
      changed = true;
    }
    if (plant.friendWaterKey != todayKey) {
      plant.wateredFriendIds = [];
      plant.friendWaterKey = todayKey;
      changed = true;
    }
    final revivedToday = plant.revivedKey == todayKey;
    if (plant.revived != revivedToday) {
      plant.revived = revivedToday;
      changed = true;
    }
    final missed = _missedDays(input);
    if (plant.missedDays != missed) {
      plant.missedDays = missed;
      changed = true;
    }
    if (input.streakDays > plant.tally.bestStreakDays) {
      plant.tally.bestStreakDays = input.streakDays;
      changed = true;
    }
    _onboardingDone = input.onboardingDone;
    if (_evaluateDex()) changed = true;

    if (changed) {
      notifyListeners();
      _saveNow();
    }
  }

  /// 기록을 쉰 날 수 — 오늘 기록이 있으면 0, 없으면 어제부터 거꾸로 기록 없는 날을 센다.
  /// 식물을 키우기 시작한 날보다 앞은 세지 않는다.
  int _missedDays(PlantSyncInput input) {
    if (input.hasRecordOn(input.today)) return 0;
    final start = DateTime.tryParse(plant.startedKey);
    var d = DateTime(input.today.year, input.today.month, input.today.day - 1);
    var missed = 0;
    while (missed < 30 &&
        (start == null || !d.isBefore(start)) &&
        !input.hasRecordOn(d)) {
      missed++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return missed;
  }

  /// 도감 조건을 확인해, 새로 모았거나 진행도가 오른 식물을 반영한다. 바뀐 게 있으면 true.
  /// 한 번 모은 식물은 줄어들지 않는다.
  bool _evaluateDex() {
    var anyChanged = false;
    for (var pass = 0; pass < 3; pass++) {
      final owned = dexEntries.where((e) => e.owned).length;
      final ctx = DexContext(
        tally: plant.tally,
        axisScore: plant.axisScore,
        onboardingDone: _onboardingDone,
        ownedCount: owned,
        totalCount: PlantSpecies.catalog.length,
      );
      var changedThisPass = false;
      for (final sp in PlantSpecies.catalog) {
        final old = _dexEntryFor(sp.id);
        final result = DexRules.evaluate(sp.id, ctx);
        final nowOwned = old.owned || result.done;
        final progress = nowOwned
            ? 100
            : (result.progress > old.progress ? result.progress : old.progress);
        if (nowOwned == old.owned && progress == old.progress) continue;
        final updated = DexEntry(
          userId: old.userId,
          speciesId: sp.id,
          owned: nowOwned,
          progress: progress,
        );
        final i = dexEntries.indexWhere((e) => e.speciesId == sp.id);
        if (i >= 0) {
          dexEntries[i] = updated;
        } else {
          dexEntries.add(updated);
        }
        _saveDexEntry(updated);
        changedThisPass = true;
      }
      if (!changedThisPass) break;
      anyChanged = true;
    }
    return anyChanged;
  }

  void _saveDexEntry(DexEntry entry) {
    if (uid == null) return;
    unawaited(
      _dexRepo.save(uid!, entry).catchError((Object e, StackTrace stack) {
        debugPrint('도감 저장 실패: $e\n$stack');
        onSyncFailed?.call('도감을 저장하지 못했어요. 네트워크를 확인해 주세요.');
      }),
    );
  }

  // 화면이 바로 쓰는 값들 — 계산은 Plant 모델이 하고, 여기서는 이름만 붙여 내놓는다.
  int get plantExp => plant.exp;
  Map<PlantAxis, int> get axisScore => plant.axisScore;
  Map<String, int> get cares => plant.cares;
  int get missedDays => plant.missedDays;
  bool get revived => plant.revived;
  List<String> get wateredFriends => plant.wateredFriendIds;
  Map<String, int> get inventory => plant.inventory;
  int get giftTickets => plant.giftTickets;

  int get plantLevel => plant.level;
  bool get wilting => plant.wilting;
  int get graceLeft => plant.graceLeft;
  int get axisSpread => plant.axisSpread;
  bool get balanced => plant.balanced;
  PlantAxis get weakestAxis => plant.weakestAxis;
  ({String emoji, String name, int lv, double size}) get plantStage =>
      plant.stage;
  String get plantExpLeft => plant.expLeft;
  String get plantMood => plant.mood;
  String get plantMessage => plant.message;
  String get balanceHint => plant.balanceHint;

  // ── 정원 ────────────────────────────────────────────────────────────

  /// 정원의 화분 칸 수.
  static const gardenSlots = 8;

  /// 정원 화분들 — 지금 키우는 식물이 맨 앞, 그다음에 도감에서 모은 식물, 나머지는 빈 화분.
  /// 실제로 키우거나 모은 것만 보여준다 (모은 게 없으면 빈 화분으로 남는다).
  List<GardenPot> get gardenPots {
    final owned = [
      for (final sp in PlantSpecies.catalog)
        if (dexEntries.any((e) => e.speciesId == sp.id && e.owned))
          (emoji: sp.emoji, label: sp.name, kind: GardenPotKind.collected),
    ];
    final pots = <GardenPot>[
      (emoji: plantStage.emoji, label: '키우는 중', kind: GardenPotKind.growing),
      ...owned.take(gardenSlots - 1),
    ];
    while (pots.length < gardenSlots) {
      pots.add((emoji: '', label: '빈 화분', kind: GardenPotKind.empty));
    }
    return pots;
  }

  void _scheduleSave() {
    if (uid == null || !_syncOk) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, () {
      _saveTimer = null;
      _saveNow();
    });
  }

  /// 기다리지 않고 바로 저장한다 — 기록을 남기거나 하루가 바뀌어 상태가 맞춰질 때처럼
  /// 자주 일어나지 않는 변화에 쓴다(돌보기를 연달아 누르는 경우는 [_scheduleSave]로 모아서 저장한다).
  void _saveNow() {
    if (uid == null || !_syncOk) return;
    _saveTimer?.cancel();
    _saveTimer = null;
    unawaited(
      _plantRepo.save(uid!, plant).catchError((Object e, StackTrace stack) {
        debugPrint('식물 상태 저장 실패: $e\n$stack');
        onSyncFailed?.call('식물 상태 저장에 실패했어요. 네트워크를 확인해 주세요.');
      }),
    );
  }

  // ── 도감 ────────────────────────────────────────────────────────────
  //
  // 카탈로그(어떤 종이 있는지)는 PlantSpecies.catalog가 담당하고, "내가 그
  // 종을 얼마나 모았는지"는 계정별로 저장되는 dexEntries가 담당한다.
  // 여기서는 둘을 합친 DexCard 목록만 다룬다.
  String dexTab = '전체';
  int dexPick = 0;

  static const _dexDemoOwned = {
    'sp_tulip',
    'sp_sunflower',
    'sp_rose',
    'sp_daisy',
    'sp_monstera',
    'sp_cactus',
    'sp_sprout',
    'sp_cherry_blossom',
  };
  static const _dexDemoProgress = <String, int>{
    'sp_rubber_tree': 62,
    'sp_clover': 75,
    'sp_rice': 40,
    'sp_lotus': 55,
    'sp_moss_fern': 30,
    'sp_conifer': 45,
    'sp_bamboo': 20,
    'sp_mutant_tulip': 12,
    'sp_golden_rose': 33,
    'sp_rare_hibiscus': 8,
  };

  /// 데모(Mock) 계정에서 보여줄 예시 수집 상태. 실제 계정은 로그인 후
  /// [loadForUid]에서 저장된 값(없으면 전부 미획득)으로 덮어쓴다.
  List<DexEntry> dexEntries = [
    for (final sp in PlantSpecies.catalog)
      DexEntry(
        userId: User.meId,
        speciesId: sp.id,
        owned: _dexDemoOwned.contains(sp.id),
        progress: _dexDemoOwned.contains(sp.id)
            ? 100
            : (_dexDemoProgress[sp.id] ?? 0),
      ),
  ];

  DexEntry _dexEntryFor(String speciesId) => dexEntries.firstWhere(
    (e) => e.speciesId == speciesId,
    orElse: () => DexEntry(userId: _uid, speciesId: speciesId),
  );

  List<DexCard> get _dexCards => [
    for (final sp in PlantSpecies.catalog) DexCard(sp, _dexEntryFor(sp.id)),
  ];

  int get dexTotal => _dexCards.fold(0, (a, b) => a + b.variants.length);
  int get dexOwned => _dexCards.fold(0, (a, b) => a + b.ownedVariants);
  int get dexPct => ((dexOwned / dexTotal) * 100).round();

  ({int own, int all}) dexTierCount(String tier) {
    final g = _dexCards.where((c) => c.tier == tier);
    return (
      own: g.fold(0, (a, b) => a + b.ownedVariants),
      all: g.fold(0, (a, b) => a + b.variants.length),
    );
  }

  List<DexCard> get dexFiltered {
    final cards = _dexCards;
    return dexTab == '전체'
        ? cards
        : cards.where((c) => c.tier == dexTab).toList();
  }

  DexCard get dexSelected {
    final cards = _dexCards;
    return cards[dexPick.clamp(0, cards.length - 1)];
  }

  void setDexTab(String t) {
    dexTab = t;
    notifyListeners();
  }

  void setDexPick(DexCard c) {
    // 카드는 부를 때마다 새로 만들어져서 객체끼리 비교(indexOf)하면 못 찾는다.
    // 어떤 종인지(speciesId)로 찾아야 누른 카드가 선택된다.
    final i = _dexCards.indexWhere((x) => x.speciesId == c.speciesId);
    if (i >= 0) dexPick = i;
    notifyListeners();
  }

  // ── 불러오기 · 비우기 · 삭제 ─────────────────────────────────────────

  /// 로그인한 계정의 식물과 도감을 서버에서 불러와 예시를 대체한다.
  Future<void> loadForUid(String uid) async {
    this.uid = uid;
    await _loadPlant(uid);
    await _loadDex(uid);
    notifyListeners();
  }

  Future<void> _loadPlant(String uid) async {
    _syncOk = true;
    try {
      final saved = await _plantRepo.loadAll(uid);
      plant = saved.isEmpty ? Plant.starter(uid) : saved.first;
      if (plant.startedKey.isEmpty) plant.startedKey = _todayKey;
    } catch (e, stack) {
      debugPrint('식물 정보를 불러오지 못했어요: $e\n$stack');
      plant = Plant.starter(uid);
      _syncOk = false;
      onSyncFailed?.call('식물 정보를 불러오지 못했어요. 다시 로그인하기 전까지 식물 변화는 저장되지 않아요.');
    }
  }

  List<DexEntry> _emptyDex(String uid) => [
    for (final sp in PlantSpecies.catalog)
      DexEntry(userId: uid, speciesId: sp.id),
  ];

  Future<void> _loadDex(String uid) async {
    try {
      final saved = await _dexRepo.loadAll(uid);
      if (saved.isNotEmpty) {
        dexEntries = saved;
        return;
      }
      dexEntries = _emptyDex(uid);
      for (final e in dexEntries) {
        unawaited(_dexRepo.save(uid, e));
      }
    } catch (e, stack) {
      debugPrint('도감 정보를 불러오지 못했어요: $e\n$stack');
      dexEntries = _emptyDex(uid);
      onSyncFailed?.call('도감 정보를 불러오지 못했어요.');
    }
  }

  /// 예시 식물과 도감을 비운다 (실제 계정으로 로그인할 때).
  void clear(String uid) {
    _saveTimer?.cancel();
    _saveTimer = null;
    plant = Plant.starter(uid);
    _syncOk = true;
    dexEntries = _emptyDex(uid);
    notifyListeners();
  }

  Future<void> deleteAll(String uid) =>
      Future.wait([_plantRepo.deleteAll(uid), _dexRepo.deleteAll(uid)]);

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
