import 'dart:async';

import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';

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
  }) : _plantRepo = plantRepo,
       _dexRepo = dexRepo,
       _saveDelay = saveDelay;

  final RecordRepository<Plant> _plantRepo;
  final RecordRepository<DexEntry> _dexRepo;
  final Duration _saveDelay;

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

  void revive() {
    plant.revive();
    notifyListeners();
    _scheduleSave();
  }

  /// friendUserId(친구의 User.id)의 정원에 물을 준다.
  void waterFriend(String friendUserId) {
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

  void _scheduleSave() {
    if (uid == null || !_syncOk) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, () {
      _saveTimer = null;
      unawaited(
        _plantRepo.save(uid!, plant).catchError((Object e, StackTrace stack) {
          debugPrint('식물 상태 저장 실패: $e\n$stack');
          onSyncFailed?.call('식물 상태 저장에 실패했어요. 네트워크를 확인해 주세요.');
        }),
      );
    });
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
