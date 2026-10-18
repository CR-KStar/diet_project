import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/record/viewmodel/exercise_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_project/data/repositories/impl/memory_record_repository.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';

/// 저장이 항상 실패하는 저장소 — 저장 실패 알림을 확인하는 데 쓴다.
class _FailingRepo extends MemoryRecordRepository<ExerciseLog> {
  _FailingRepo() : super(exerciseCodec);

  @override
  Future<void> save(String uid, ExerciseLog entry) async =>
      throw Exception('network down');
}

void main() {
  final now = DateTime(2026, 10, 18, 9, 5);
  const today = '2026-10-18';

  ExerciseViewModel build({RecordRepository<ExerciseLog>? repo}) =>
      ExerciseViewModel(
        exerciseRepo: repo ?? MemoryRecordRepository(exerciseCodec),
        now: () => now,
      );

  group('ExerciseViewModel', () {
    test('입력값에 따라 소모 칼로리를 계산한다 (달리기 30분 보통 = 30×8×1.2)', () {
      final vm = build();
      expect(vm.exType, '달리기');
      expect(vm.exMinutes, 30);
      expect(vm.exIntensity, '보통');
      expect(vm.exKcal, 288);
    });

    test('종류 · 강도 · 시간을 바꾸면 칼로리가 달라진다', () {
      final vm = build()
        ..exType = '걷기'
        ..exMinutes = 60
        ..exIntensity = '낮음';
      expect(vm.exKcal, (60 * 5 * 0.7).round());
      expect(vm.exTypeKnown, isTrue);

      vm.exType = '처음 보는 운동';
      expect(vm.exTypeKnown, isFalse);
      expect(vm.exKcal, 60 * 5); // 모르는 종류는 계수 1.0
    });

    test('logFromDraft는 입력값과 시계로 기록 한 건을 만든다', () {
      final vm = build();
      final log = vm.logFromDraft(dateKey: today);
      expect(log.type, '달리기');
      expect(log.minutes, 30);
      expect(log.kcal, 288);
      expect(log.dateKey, today);
      expect(log.time, '09:05');
      expect(log.userId, User.meId);
    });

    test('addExercise는 목록에 더하고 날짜별 합계에 반영한다', () {
      final vm = build();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.addExercise(vm.logFromDraft(dateKey: today));
      vm.exMinutes = 15;
      vm.addExercise(vm.logFromDraft(dateKey: today));

      expect(vm.exercisesOn(today), hasLength(2));
      expect(vm.minutesOn(today), 45);
      expect(vm.minutesOn('2026-10-17'), 0);
      expect(notified, 2);
    });

    test('로그인 전(데모)에는 서버에 저장하지 않고, 로그인하면 저장한다', () async {
      final repo = MemoryRecordRepository(exerciseCodec);
      final vm = build(repo: repo);

      vm.addExercise(vm.logFromDraft(dateKey: today));
      await Future<void>.delayed(Duration.zero);
      expect(await repo.loadAll('uid_1'), isEmpty);

      vm.uid = 'uid_1';
      final real = vm.logFromDraft(dateKey: today);
      vm.addExercise(real);
      await Future<void>.delayed(Duration.zero);
      expect((await repo.loadAll('uid_1')).map((e) => e.id), [real.id]);
      expect(real.userId, 'uid_1');
    });

    test('다른 사용자의 운동은 보이지 않는다', () {
      final vm = build();
      vm.exerciseLogs.add(
        ExerciseLog(
          id: 'other',
          userId: 'someone_else',
          type: '요가',
          minutes: 20,
          intensity: ExerciseIntensity.low,
          kcal: 60,
          dateKey: today,
          time: '08:00',
        ),
      );
      expect(vm.exercisesOn(today), isEmpty);
    });

    test('clear는 모두 비우고, mergeLoaded는 중복 없이 합친다', () {
      final vm = build();
      final a = vm.logFromDraft(dateKey: today);
      vm.addExercise(a);
      vm.clear();
      expect(vm.exerciseLogs, isEmpty);

      vm.mergeLoaded([a]);
      vm.mergeLoaded([a]);
      expect(vm.exerciseLogs, hasLength(1));
    });

    test('저장이 실패하면 onSaveFailed로 알리고 목록에는 남긴다', () async {
      final vm = build(repo: _FailingRepo())..uid = 'uid_1';
      var failed = 0;
      vm.onSaveFailed = () => failed++;

      vm.addExercise(vm.logFromDraft(dateKey: today));
      await Future<void>.delayed(Duration.zero);

      expect(failed, 1);
      expect(vm.exerciseLogs, hasLength(1));
    });
  });
}
