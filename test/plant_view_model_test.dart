import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/ui/growth/viewmodel/plant_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// 저장 횟수를 세고, 불러오기 · 저장을 실패시킬 수 있는 저장소.
class _Repo<T> extends MemoryRecordRepository<T> {
  _Repo(super.codec, {this.failLoad = false, this.failSave = false});

  final bool failLoad;
  final bool failSave;
  int saves = 0;

  @override
  Future<void> save(String uid, T entry) async {
    saves++;
    if (failSave) throw Exception('network down');
    return super.save(uid, entry);
  }

  @override
  Future<List<T>> loadAll(String uid) async {
    if (failLoad) throw Exception('network down');
    return super.loadAll(uid);
  }
}

Future<void> _wait([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late _Repo<Plant> plantRepo;
  late _Repo<DexEntry> dexRepo;

  PlantViewModel build({bool failLoad = false, bool failSave = false}) {
    plantRepo = _Repo(plantCodec, failLoad: failLoad, failSave: failSave);
    dexRepo = _Repo(dexEntryCodec, failLoad: failLoad);
    return PlantViewModel(
      plantRepo: plantRepo,
      dexRepo: dexRepo,
      saveDelay: const Duration(milliseconds: 10),
    );
  }

  group('PlantViewModel · 식물', () {
    test('돌보면 경험치가 오르고 알린다', () {
      final vm = build();
      final before = vm.plant.exp;
      var notified = 0;
      vm.addListener(() => notified++);

      vm.care('물 주기');

      expect(vm.plant.exp, greaterThan(before));
      expect(notified, 1);
    });

    test('로그인 전(데모)에는 서버에 저장하지 않는다', () async {
      build().care('물 주기');
      await _wait();
      expect(plantRepo.saves, 0);
    });

    test('연달아 돌봐도 저장은 한 번만 한다', () async {
      final vm = build()..uid = 'uid_1';
      vm
        ..care('물 주기')
        ..care('햇빛 받기')
        ..care('영양 주기');
      await _wait();
      expect(plantRepo.saves, 1);
    });

    test('미션 보상 경험치도 저장된다', () async {
      final vm = build()..uid = 'uid_1';
      final before = vm.plant.exp;
      vm.gainExp(30);
      await _wait();
      expect(vm.plant.exp, before + 30);
      expect(plantRepo.saves, 1);
    });

    test('저장이 실패하면 안내 문구와 함께 알린다', () async {
      final messages = <String>[];
      final vm = build(failSave: true)
        ..uid = 'uid_1'
        ..onSyncFailed = messages.add;
      vm.care('물 주기');
      await _wait();
      expect(messages, ['식물 상태 저장에 실패했어요. 네트워크를 확인해 주세요.']);
    });
  });

  group('PlantViewModel · 불러오기', () {
    test('서버에 아무것도 없으면 새 식물과 빈 도감으로 시작한다', () async {
      final vm = build();
      await vm.loadForUid('uid_1');

      expect(vm.uid, 'uid_1');
      expect(vm.plant.userId, 'uid_1');
      expect(vm.plant.exp, 0);
      expect(vm.dexOwned, 0);
      expect(vm.dexEntries.every((e) => e.userId == 'uid_1'), isTrue);
      await _wait();
      expect(dexRepo.saves, vm.dexEntries.length); // 빈 도감을 서버에 만들어 둔다
    });

    test('식물을 불러오지 못하면 알리고, 덮어쓰지 않도록 저장도 멈춘다', () async {
      final messages = <String>[];
      final vm = build(failLoad: true)..onSyncFailed = messages.add;
      await vm.loadForUid('uid_1');

      expect(messages, hasLength(2)); // 식물, 도감
      expect(messages.first, contains('식물 정보를 불러오지 못했어요'));

      vm.care('물 주기');
      await _wait();
      expect(plantRepo.saves, 0);
    });

    test('clear는 대기 중인 저장을 취소하고 새 식물로 바꾼다', () async {
      final vm = build()..uid = 'uid_1';
      vm.care('물 주기');
      vm.clear('uid_1');
      await _wait();

      expect(plantRepo.saves, 0);
      expect(vm.plant.exp, 0);
      expect(vm.dexOwned, 0);
    });

    test('deleteAll은 식물과 도감을 모두 지운다', () async {
      final vm = build();
      await vm.loadForUid('uid_1');
      vm.care('물 주기');
      await _wait();
      await vm.deleteAll('uid_1');
      expect(await plantRepo.loadAll('uid_1'), isEmpty);
      expect(await dexRepo.loadAll('uid_1'), isEmpty);
    });
  });

  group('PlantViewModel · 도감', () {
    test('데모 도감은 일부를 획득한 상태이고 비율은 0~100 사이다', () {
      final vm = build();
      expect(vm.dexTotal, greaterThan(0));
      expect(vm.dexOwned, inInclusiveRange(1, vm.dexTotal));
      expect(vm.dexPct, inInclusiveRange(1, 100));
    });

    test('탭을 고르면 그 등급만 보이고, 등급별 개수의 합은 전체와 같다', () {
      final vm = build();
      final all = vm.dexFiltered;
      expect(vm.dexTab, '전체');

      final tier = all.first.tier;
      vm.setDexTab(tier);
      expect(vm.dexFiltered, isNotEmpty);
      expect(vm.dexFiltered.every((c) => c.tier == tier), isTrue);

      final tiers = all.map((c) => c.tier).toSet();
      final sum = tiers.fold(0, (a, t) => a + vm.dexTierCount(t).all);
      expect(sum, vm.dexTotal);
    });

    test('카드를 고르면 선택이 바뀌고 알린다', () {
      final vm = build();
      var notified = 0;
      vm.addListener(() => notified++);
      final second = vm.dexFiltered[1];

      vm.setDexPick(second);

      expect(vm.dexSelected.species.id, second.species.id);
      expect(notified, 1);
    });
  });

  group('PlantViewModel · 도감 선택 (회귀)', () {
    test('어떤 카드를 눌러도 그 카드가 선택된다 (예전에는 항상 첫 카드였다)', () {
      final vm = build();
      for (final card in vm.dexFiltered) {
        vm.setDexPick(card);
        expect(vm.dexSelected.speciesId, card.speciesId);
      }
    });
  });

  group('AppState와의 연결', () {
    test('식물을 돌보면 AppState를 구독한 화면에도 알려진다', () {
      final s = AppState();
      var notified = 0;
      s.addListener(() => notified++);
      final before = s.plantExp;

      s.care('물 주기');

      expect(s.plantExp, greaterThan(before));
      expect(notified, greaterThanOrEqualTo(1));
    });

    test('도감 탭을 바꾸면 AppState에서도 읽힌다', () {
      final s = AppState();
      final tier = s.dexFiltered.first.tier;
      s.setDexTab(tier);
      expect(s.dexTab, tier);
      expect(s.dexFiltered.every((c) => c.tier == tier), isTrue);
    });
  });
}
