import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/profile_repository.dart';
import 'package:diet_project/data/repositories/water_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _account = AuthAccount(uid: 'uid_1', provider: LoginProvider.google, displayName: '지민');

class _FakeAuth implements AuthService {
  @override
  AuthAccount? get currentAccount => _account;

  @override
  Future<AuthAccount?> restoreAccount() async => _account;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => _account;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {
    await beforeDelete?.call();
  }
}

class _LoadFailsRepo extends MemoryWaterRepository {
  @override
  Future<List<WaterEntry>> loadDay(String uid, String dateKey) async => throw Exception('network down');
}

class _SaveFailsRepo extends MemoryWaterRepository {
  @override
  Future<void> save(String uid, WaterEntry entry) async => throw Exception('network down');
}

WaterEntry _entry(String id, int ml, String dateKey, {String time = '10:00'}) =>
    WaterEntry(id: id, userId: 'uid_1', ml: ml, dateKey: dateKey, time: time);

/// 로그인한 실제 계정으로 [now] 시각에 시작한 앱 상태
Future<AppState> _start(WaterRepository water, {DateTime Function()? now}) async {
  final s = AppState(
    auth: _FakeAuth(),
    profiles: MemoryProfileRepository(),
    waterRepo: water,
    now: now ?? () => DateTime(2026, 9, 21, 14, 5),
  );
  await s.restoreSession();
  return s;
}

Future<void> _settleEdits() => Future<void>.delayed(const Duration(milliseconds: 700));

void main() {
  group('MemoryWaterRepository', () {
    test('날짜로 골라 불러오고, 마신 순서대로 돌려준다', () async {
      final repo = MemoryWaterRepository();
      await repo.save('uid_1', _entry('water_2', 350, '2026-09-21'));
      await repo.save('uid_1', _entry('water_1', 250, '2026-09-21'));
      await repo.save('uid_1', _entry('water_0', 500, '2026-09-20'));

      final today = await repo.loadDay('uid_1', '2026-09-21');
      expect(today.map((e) => e.ml), [250, 350]);
      expect((await repo.loadDay('uid_1', '2026-09-20')).single.ml, 500);
    });

    test('같은 id로 저장하면 덮어쓴다', () async {
      final repo = MemoryWaterRepository();
      await repo.save('uid_1', _entry('water_1', 250, '2026-09-21'));
      await repo.save('uid_1', _entry('water_1', 400, '2026-09-21'));

      final list = await repo.loadDay('uid_1', '2026-09-21');
      expect(list, hasLength(1));
      expect(list.single.ml, 400);
    });

    test('계정별로 분리되고, deleteAll은 그 계정 것만 지운다', () async {
      final repo = MemoryWaterRepository();
      await repo.save('uid_1', _entry('a', 250, '2026-09-21'));
      await repo.save('uid_2', _entry('b', 300, '2026-09-21'));

      await repo.deleteAll('uid_1');

      expect(await repo.loadDay('uid_1', '2026-09-21'), isEmpty);
      expect(await repo.loadDay('uid_2', '2026-09-21'), hasLength(1));
    });

    test('저장 형식: 저장했다가 복원하면 같고, 타입이 이상해도 기본값으로 복원한다', () {
      final entry = _entry('water_1', 350, '2026-09-21', time: '14:05');
      final back = waterFromMap('water_1', waterToMap(entry), userId: 'uid_1');
      expect([back.ml, back.dateKey, back.time], [350, '2026-09-21', '14:05']);

      final odd = waterFromMap('x', {'ml': '많이', 'dateKey': 7, 'time': null}, userId: 'uid_1');
      expect([odd.ml, odd.dateKey, odd.time], [0, '', '']);
    });
  });

  group('물 기록하기', () {
    test('기록하면 화면에 바로 반영되고, 계정 · 오늘 날짜 · 실제 시각으로 저장된다', () async {
      final repo = MemoryWaterRepository();
      final s = await _start(repo);

      s.waterInput = 300;
      s.addWater();

      expect(s.waterTotal, 300);
      final saved = await repo.loadDay('uid_1', '2026-09-21');
      expect(saved, hasLength(1));
      expect([saved.single.ml, saved.single.dateKey, saved.single.time, saved.single.userId],
          [300, '2026-09-21', '14:05', 'uid_1']);
    });

    test('앱을 다시 켜면 오늘 마신 물이 그대로 불러와진다', () async {
      final repo = MemoryWaterRepository();
      final first = await _start(repo);
      first.addWater(250);
      first.addWater(500);

      final second = await _start(repo);

      expect(second.waterTotal, 750);
      expect(second.waterEntries.map((e) => e.ml), [250, 500]);
    });

    test('용량을 고치면 잠깐 뒤에 한 번만 저장된다', () async {
      final repo = MemoryWaterRepository();
      final s = await _start(repo);
      s.addWater(250);

      s.editWater(0, 2);
      s.editWater(0, 25);
      s.editWater(0, 400); // 타이핑하듯 여러 번 바뀜
      await _settleEdits();

      expect((await repo.loadDay('uid_1', '2026-09-21')).single.ml, 400);
    });

    test('삭제와 마지막 기록 취소가 저장소에도 반영된다', () async {
      final repo = MemoryWaterRepository();
      final s = await _start(repo);
      s.addWater(250);
      s.addWater(350);
      s.addWater(500);

      s.removeWater(0);
      s.undoWater();

      expect(s.waterEntries.map((e) => e.ml), [350]);
      expect((await repo.loadDay('uid_1', '2026-09-21')).map((e) => e.ml), [350]);
    });

    test('고치는 도중에 삭제하면 지운 기록이 되살아나지 않는다', () async {
      final repo = MemoryWaterRepository();
      final s = await _start(repo);
      s.addWater(250);

      s.editWater(0, 999);
      s.removeWater(0);
      await _settleEdits();

      expect(await repo.loadDay('uid_1', '2026-09-21'), isEmpty);
    });

    test('자정이 지나면 어제 기록은 내려가고 새 기록은 새 날짜로 저장된다', () async {
      var now = DateTime(2026, 9, 21, 23, 59);
      final repo = MemoryWaterRepository();
      final s = await _start(repo, now: () => now);
      s.addWater(250);

      now = DateTime(2026, 9, 22, 0, 1);
      s.addWater(400);

      expect(s.waterEntries.map((e) => e.ml), [400]);
      expect((await repo.loadDay('uid_1', '2026-09-21')).single.ml, 250);
      final second = (await repo.loadDay('uid_1', '2026-09-22')).single;
      expect([second.ml, second.time], [400, '00:01']);
    });

    test('다른 날의 기록은 오늘 합계에 섞이지 않는다', () async {
      final repo = MemoryWaterRepository();
      await repo.save('uid_1', _entry('water_1', 999, '2026-09-20'));

      final s = await _start(repo);

      expect(s.waterTotal, 0);
    });
  });

  group('실패했을 때', () {
    test('불러오기에 실패해도 로그인은 막지 않고 안내만 남긴다', () async {
      final s = AppState(
        auth: _FakeAuth(),
        waterRepo: _LoadFailsRepo(),
        now: () => DateTime(2026, 9, 21),
      );

      expect(await s.restoreSession(), isTrue);

      expect(s.account, isNotNull);
      expect(s.waterEntries, isEmpty);
      expect(s.takeNotice(), contains('물'));
    });

    test('저장에 실패하면 화면 기록은 두고 안내를 남긴다', () async {
      final s = await _start(_SaveFailsRepo());

      s.addWater(250);
      await Future<void>.delayed(Duration.zero);

      expect(s.waterTotal, 250);
      expect(s.takeNotice(), contains('저장하지 못했어요'));
    });
  });

  group('계정과 예시 기록', () {
    test('계정을 삭제하면 물 기록도 함께 지워진다', () async {
      final repo = MemoryWaterRepository();
      final s = await _start(repo);
      s.addWater(250);

      expect(await s.deleteAccount(), isTrue);

      expect(await repo.loadDay('uid_1', '2026-09-21'), isEmpty);
    });

    test('가짜 로그인(예시 모드)에서는 예시 물 기록을 그대로 보여준다', () {
      final s = AppState(now: () => DateTime(2026, 9, 21));

      expect(s.waterTotal, 1450);
      expect(s.waterEntries.every((e) => e.dateKey == '2026-09-21'), isTrue);
    });
  });

  testWidgets('물 기록 시트의 "추가" 버튼이 실제로 저장까지 이어진다', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final repo = MemoryWaterRepository();
    final state = await _start(repo);
    state.waterSheet = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump(const Duration(seconds: 1)); // 시트가 올라오는 애니메이션이 끝나기를 기다린다

    await tester.tap(find.text('추가'));
    await tester.pump();

    expect(state.waterTotal, 250); // 기본 입력값
    expect(await repo.loadDay('uid_1', '2026-09-21'), hasLength(1));
  });
}
