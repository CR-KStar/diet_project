import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/home/viewmodel/mission_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var uid = 'u1';
  var todayKey = '2026-10-18';
  var meals = 0;
  var exerciseMin = 0;
  var waterMl = 0;
  var streak = 0;
  late List<int> gained;
  late MissionViewModel vm;

  MissionInputs inputs() => MissionInputs(
    uid: uid,
    todayKey: todayKey,
    mealsToday: meals,
    exerciseMinutesToday: exerciseMin,
    waterMl: waterMl,
    streakDays: streak,
  );

  setUp(() {
    uid = 'u1';
    todayKey = '2026-10-18';
    meals = exerciseMin = waterMl = streak = 0;
    gained = [];
    vm = MissionViewModel(inputs: inputs, gainExp: gained.add);
  });

  /// 날짜를 바꿔 가며 미션 구성을 모아 본다.
  List<List<Mission>> acrossDays([int days = 60]) => [
    for (var d = 1; d <= days; d++)
      () {
        todayKey = '2026-11-${d.toString().padLeft(2, '0')}';
        return vm.missions;
      }(),
  ];

  group('MissionViewModel · 뽑기', () {
    test('같은 사용자 · 같은 날이면 몇 번을 불러도 같은 미션이다', () {
      final first = vm.missions.map((m) => m.id).toList();

      expect(vm.missions.map((m) => m.id), first);
      expect(
        MissionViewModel(
          inputs: inputs,
          gainExp: (_) {},
        ).missions.map((m) => m.id),
        first,
      );
    });

    test('날짜가 바뀌면 다른 조합이 나온다', () {
      final sets = {
        for (final day in acrossDays()) day.map((m) => m.id).join(','),
      };

      expect(sets.length, greaterThan(10));
    });

    test('사용자가 다르면 같은 날에도 다른 조합이 나올 수 있다', () {
      final mine = vm.missions.map((m) => m.id).join(',');
      final others = {
        for (var i = 0; i < 30; i++)
          () {
            uid = 'user_$i';
            return vm.missions.map((m) => m.id).join(',');
          }(),
      };

      expect(others, isNot({mine}));
      expect(others.length, greaterThan(1));
    });

    test('하루 3~5개이고, 같은 미션이 겹치지 않으며, 한 카테고리에서 2개를 넘지 않는다', () {
      final sizes = <int>{};
      for (final day in acrossDays(120)) {
        sizes.add(day.length);
        expect(day.length, inInclusiveRange(3, 5));
        expect(day.map((m) => m.id).toSet(), hasLength(day.length));
        final perCategory = <String, int>{};
        for (final m in day) {
          perCategory[m.category] = (perCategory[m.category] ?? 0) + 1;
        }
        expect(perCategory.values.every((n) => n <= 2), isTrue);
      }
      expect(sizes, {3, 4, 5}); // 3개 · 4개 · 5개인 날이 모두 있다
    });

    test('카테고리는 식단 · 운동 · 생활 · 꾸준함 중 하나다', () {
      final categories = {
        for (final day in acrossDays()) ...day.map((m) => m.category),
      };

      expect(categories, {'식단', '운동', '생활', '꾸준함'});
    });
  });

  group('MissionViewModel · 진행도', () {
    Map<String, Mission> byCategory() {
      // 카테고리마다 미션이 하나씩 있는 날을 찾는다.
      for (final day in acrossDays(200)) {
        final map = {for (final m in day) m.category: m};
        if (map.length == 4 && day.length == 4) return map;
      }
      fail('4개 카테고리가 모두 나오는 날이 없다');
    }

    test('식단 · 운동 · 물 · 연속 기록 미션이 각자의 기록으로 진행도를 계산한다', () {
      meals = 2;
      exerciseMin = 25;
      waterMl = 1200;
      streak = 4;

      // 위에서 찾은 날의 기록으로 진행도를 본다.
      final picked = byCategory();
      final expected = {'식단': 2.0, '운동': 25.0, '생활': 1200.0, '꾸준함': 4.0};
      for (final entry in picked.entries) {
        expect(entry.value.current, expected[entry.key], reason: entry.key);
      }
    });

    test('목표에 닿으면 done이고, 비율은 1.0을 넘지 않는다', () {
      meals = 10;
      exerciseMin = 500;
      waterMl = 9000;
      streak = 99;

      for (final m in acrossDays().expand((d) => d)) {
        expect(m.done, isTrue, reason: m.id);
        expect(m.ratio, 1.0);
      }
    });

    test('기록이 하나도 없으면 아무것도 완료되지 않는다', () {
      for (final m in acrossDays().expand((d) => d)) {
        expect(m.done, isFalse, reason: m.id);
      }
      expect(vm.missionDone, 0);
      expect(vm.missionExp, 0);
    });

    test('완료한 미션 수와 얻은 경험치를 센다', () {
      meals = 10;
      exerciseMin = 500;
      waterMl = 9000;
      streak = 99;

      expect(vm.missionDone, vm.missions.length);
      expect(vm.missionExp, vm.missions.fold(0, (a, m) => a + m.exp));
    });
  });

  group('MissionViewModel · 수동 완료', () {
    test('달성 처리하면 완료로 보이고, 경험치를 한 번 준다', () {
      final m = vm.missions.first;
      var notified = 0;
      vm.addListener(() => notified++);
      expect(vm.missionEffectivelyDone(m), isFalse);

      vm.completeMissionManually(m);

      expect(vm.missionEffectivelyDone(m), isTrue);
      expect(gained, [m.exp]);
      expect(notified, 1);
      expect(vm.missionDone, 1);
      expect(vm.missionExp, m.exp);
    });

    test('같은 미션을 다시 달성 처리해도 경험치는 늘지 않는다', () {
      final m = vm.missions.first;

      vm.completeMissionManually(m);
      vm.completeMissionManually(m);

      expect(gained, [m.exp]);
    });

    test('어제 달성 처리한 미션은 오늘 같은 미션이 나와도 완료로 보이지 않는다', () {
      final yesterday = vm.missions.first;
      vm.completeMissionManually(yesterday);

      // 어제와 같은 미션이 나오는 날을 찾는다.
      Mission? sameToday;
      for (var d = 19; d <= 60 && sameToday == null; d++) {
        todayKey = '2026-10-$d';
        for (final m in vm.missions) {
          if (m.id == yesterday.id) sameToday = m;
        }
      }

      expect(sameToday, isNotNull);
      expect(vm.missionEffectivelyDone(sameToday!), isFalse);
      vm.completeMissionManually(sameToday); // 오늘은 오늘대로 달성 처리할 수 있다
      expect(gained, [yesterday.exp, sameToday.exp]);
    });

    test('이미 기록으로 완료된 미션은 달성 처리해도 경험치를 주지 않는다', () {
      meals = 10;
      exerciseMin = 500;
      waterMl = 9000;
      streak = 99;

      vm.completeMissionManually(vm.missions.first);

      expect(gained, isEmpty);
    });
  });

  group('MissionViewModel · 필터', () {
    test('처음에는 전체이고, 바꾸면 알린다', () {
      var notified = 0;
      vm.addListener(() => notified++);
      expect(vm.missionFilterTab, '전체');

      vm.setMissionFilterTab('운동');

      expect(vm.missionFilterTab, '운동');
      expect(notified, 1);
    });
  });

  group('AppState 연결', () {
    test('미션 진행도가 실제 기록을 따라간다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      final before = s.missions.where((m) => m.category == '식단');

      s.logMeal();
      s.logMeal();
      s.logMeal();
      s.logMeal();

      final after = s.missions.where((m) => m.category == '식단');
      for (final m in after) {
        expect(m.current, greaterThan(before.first.current));
        expect(m.done, isTrue);
      }
    });

    test('수동 완료하면 식물 경험치가 오른다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      final m = s.missions.first;
      final exp = s.plantExp;

      s.completeMissionManually(m);

      expect(s.plantExp, exp + m.exp);
    });

    test('미션 상태가 바뀌면 AppState 구독자에게도 전달된다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      var notified = 0;
      s.addListener(() => notified++);

      s.setMissionFilterTab('식단');

      expect(notified, 1);
      expect(s.missionFilterTab, '식단');
    });
  });
}
