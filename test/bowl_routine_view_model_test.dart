import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/domain/rules/diet_rules.dart';
import 'package:diet_project/ui/record/viewmodel/bowl_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/routine_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_project/data/repositories/impl/memory_record_repository.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/app_composition.dart';

/// 저장 · 삭제 · 불러오기 중 원하는 동작을 실패시킬 수 있는 저장소.
class _Flaky<T> extends MemoryRecordRepository<T> {
  _Flaky(super.codec, {this.failSave = false, this.failLoad = false});

  final bool failSave;
  final bool failLoad;

  @override
  Future<void> save(String uid, T entry) async {
    if (failSave) throw Exception('network down');
    return super.save(uid, entry);
  }

  @override
  Future<void> delete(String uid, String id) async {
    if (failSave) throw Exception('network down');
    return super.delete(uid, id);
  }

  @override
  Future<List<T>> loadAll(String uid) async {
    if (failLoad) throw Exception('network down');
    return super.loadAll(uid);
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('BowlViewModel', () {
    BowlViewModel build({RecordRepository<Bowl>? repo}) =>
        BowlViewModel(bowlRepo: repo ?? MemoryRecordRepository(bowlCodec));

    test('처음에는 예시 그릇 4개를 갖고 첫 번째 그릇이 선택돼 있다', () {
      final vm = build();
      expect(vm.bowls, hasLength(4));
      expect(vm.currentBowl?.id, 'bowl_lunchbox');
    });

    test('이름이 비어 있으면 저장할 수 없다', () {
      final vm = build()..startAddBowl();
      expect(vm.bowlEditing, -1);
      expect(vm.saveBowl(), isFalse);
      expect(vm.bowls, hasLength(4));
    });

    test('새 그릇을 저장하면 목록에 더하고, 로그인 전에는 서버에 저장하지 않는다', () async {
      final repo = MemoryRecordRepository(bowlCodec);
      final vm = build(repo: repo)..startAddBowl();
      vm.draftBowl.name = '새 그릇';

      expect(vm.saveBowl(), isTrue);
      await _settle();

      expect(vm.bowls.last.name, '새 그릇');
      expect(vm.bowlEditing, isNull);
      expect(await repo.loadAll('uid_1'), isEmpty);
    });

    test('로그인하면 저장한 그릇이 서버에도 저장된다', () async {
      final repo = MemoryRecordRepository(bowlCodec);
      final vm = build(repo: repo)
        ..uid = 'uid_1'
        ..startAddBowl();
      vm.draftBowl.name = '새 그릇';
      vm.saveBowl();
      await _settle();

      final saved = await repo.loadAll('uid_1');
      expect(saved.map((b) => b.name), ['새 그릇']);
      expect(saved.single.userId, 'uid_1');
    });

    test('기본 그릇으로 저장하면 이전 기본 그릇의 표시가 풀린다', () {
      final vm = build()..startAddBowl();
      vm.draftBowl
        ..name = '새 기본'
        ..isDefault = true;
      vm.saveBowl();

      expect(vm.bowls.where((b) => b.isDefault).map((b) => b.name), ['새 기본']);
    });

    test('그릇은 최대 개수까지만 등록할 수 있다', () {
      final vm = build();
      while (vm.bowls.length < DietRules.maxBowls) {
        vm.startAddBowl();
        vm.draftBowl.name = '그릇 ${vm.bowls.length}';
        expect(vm.saveBowl(), isTrue);
      }
      vm.startAddBowl();
      vm.draftBowl.name = '넘치는 그릇';
      expect(vm.saveBowl(), isFalse);
      expect(vm.bowls, hasLength(DietRules.maxBowls));
    });

    test('마지막 그릇을 선택한 채 지우면 선택이 처음으로 돌아간다', () {
      final vm = build();
      vm.bowlIndex = 3;
      vm.removeBowl(3);
      expect(vm.bowls, hasLength(3));
      expect(vm.bowlIndex, 0);
    });

    test('그릇이 하나도 없으면 선택된 그릇은 null이다', () {
      final vm = build()..clear();
      expect(vm.bowls, isEmpty);
      expect(vm.currentBowl, isNull);
    });

    test('불러오기에 성공하면 예시를 대체하고, 실패하면 비우고 false를 돌려준다', () async {
      final ok = build()..bowlIndex = 2;
      expect(await ok.loadForUid('uid_1'), isTrue);
      expect(ok.bowls, isEmpty); // 서버에 아직 없으니 비어 있다
      expect(ok.bowlIndex, 0);

      final bad = build(repo: _Flaky(bowlCodec, failLoad: true));
      expect(await bad.loadForUid('uid_1'), isFalse);
      expect(bad.bowls, isEmpty);
    });

    test('저장이 실패하면 안내 문구와 함께 알린다', () async {
      final messages = <String>[];
      final vm = build(repo: _Flaky(bowlCodec, failSave: true))
        ..uid = 'uid_1'
        ..onSyncFailed = messages.add
        ..startAddBowl();
      vm.draftBowl.name = '새 그릇';
      vm.saveBowl();
      await _settle();

      expect(messages, ['그릇 저장에 실패했어요. 네트워크를 확인해 주세요.']);
      expect(vm.bowls.last.name, '새 그릇'); // 화면에는 남는다
    });
  });

  group('RoutineViewModel', () {
    RoutineViewModel build({RecordRepository<Routine>? repo}) =>
        RoutineViewModel(
          routineRepo: repo ?? MemoryRecordRepository(routineCodec),
        );

    test('처음에는 예시 루틴 3개를 갖는다', () {
      expect(build().routines, hasLength(3));
    });

    test('루틴을 추가하면 이름과 아이콘이 운동 종류에 맞게 정해진다', () {
      final vm = build();
      vm.addRoutine(type: '요가', minutes: 20, intensity: ExerciseIntensity.low);
      vm.addRoutine(
        type: '처음 보는 운동',
        minutes: 10,
        intensity: ExerciseIntensity.high,
      );

      expect(vm.routines[3].name, '요가 20분');
      expect(vm.routines[3].icon, '🧘');
      expect(vm.routines[4].icon, '💪');
    });

    test('로그인하면 추가한 루틴을 서버에 저장하고, 삭제하면 서버에서도 지운다', () async {
      final repo = MemoryRecordRepository(routineCodec);
      final vm = build(repo: repo)..uid = 'uid_1';
      vm.addRoutine(
        type: '달리기',
        minutes: 30,
        intensity: ExerciseIntensity.moderate,
      );
      await _settle();
      final added = vm.routines.last;
      expect((await repo.loadAll('uid_1')).map((r) => r.id), [added.id]);

      vm.removeRoutine(added);
      await _settle();
      expect(vm.routines, hasLength(3));
      expect(await repo.loadAll('uid_1'), isEmpty);
    });

    test('편집 모드를 켜고 끄면 알린다', () {
      final vm = build();
      var notified = 0;
      vm.addListener(() => notified++);
      vm.toggleRoutineEditMode();
      expect(vm.routineEditMode, isTrue);
      vm.toggleRoutineEditMode();
      expect(vm.routineEditMode, isFalse);
      expect(notified, 2);
    });

    test('불러오기에 실패하면 비우고 false, 저장 실패는 문구와 함께 알린다', () async {
      final bad = build(repo: _Flaky(routineCodec, failLoad: true));
      expect(await bad.loadForUid('uid_1'), isFalse);
      expect(bad.routines, isEmpty);

      final messages = <String>[];
      final vm = build(repo: _Flaky(routineCodec, failSave: true))
        ..uid = 'uid_1'
        ..onSyncFailed = messages.add;
      vm.addRoutine(type: '걷기', minutes: 20, intensity: ExerciseIntensity.low);
      await _settle();
      expect(messages, ['운동 루틴 저장에 실패했어요. 네트워크를 확인해 주세요.']);
    });
  });

  group('AppState와의 연결', () {
    test('그릇 · 루틴이 바뀌면 화면이 구독하는 ViewModel에 전달된다', () {
      final s = AppState(dependencies: memoryDependencies());
      var notified = 0;
      s.bowlViewModel.addListener(() => notified++);
      s.routineViewModel.addListener(() => notified++);

      s.startAddBowl();
      expect(s.bowlEditing, -1);
      s.toggleRoutineEditMode();
      expect(s.routineEditMode, isTrue);

      expect(notified, greaterThanOrEqualTo(2));
    });

    test('운동 입력값을 루틴으로 저장하고 다시 불러올 수 있다', () {
      final s = AppState(dependencies: memoryDependencies())
        ..exType = '수영'
        ..exMinutes = 45
        ..exIntensity = '높음';
      s.saveCurrentAsRoutine();
      final saved = s.routines.last;
      expect(saved.name, '수영 45분');

      s
        ..exType = '걷기'
        ..exMinutes = 10;
      s.loadRoutine(saved);
      expect([s.exType, s.exMinutes, s.exIntensity], ['수영', 45, '높음']);
    });

    test('식사에 쓸 그릇을 고르면 식단 입력값에도 반영된다', () {
      final s = AppState(dependencies: memoryDependencies());
      s.selectBowl(2);
      expect(s.currentBowl?.id, 'bowl_salad');
      expect(s.mealDraft.bowlId, 'bowl_salad');
    });
  });
}
