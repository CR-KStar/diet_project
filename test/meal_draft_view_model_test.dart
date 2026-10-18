import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/record/viewmodel/meal_draft_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

Bowl _bowl(int capacityMl) => Bowl(
  id: 'b',
  userId: User.meId,
  name: '그릇',
  capacityMl: capacityMl,
  portion: '1인분',
  material: '플라스틱',
  shape: '원형',
);

void main() {
  late MealDraftViewModel vm;
  setUp(() => vm = MealDraftViewModel());

  group('MealDraftViewModel · 입력값', () {
    test('처음 값: 점심 · 단백질 돼지고기 · 소스 저당 소스 · 조리 볶음 · 백미 · 전체 · 가득', () {
      expect(vm.extras, {
        'meat': '돼지고기',
        'sauce': '저당 소스',
        'cook': '볶음',
        'carb': '백미',
        'meal': '점심',
        'context': vm.extras['context'], // 기본 상황
      });
      expect(vm.portion, '전체');
      expect(vm.portionPct, 100);
      expect(vm.fill, '가득');
      expect(vm.tags, isEmpty);
    });

    test('항목을 고르면 바뀌고 알린다', () {
      var notified = 0;
      vm.addListener(() => notified++);

      vm.setExtra('meat', '닭고기');
      vm.setExtra('sauce', '간장');
      vm.setExtra('cook', '구이');
      vm.setExtra('carb', '현미');

      expect(vm.extras['meat'], '닭고기');
      expect(vm.extras['sauce'], '간장');
      expect(vm.extras['cook'], '구이');
      expect(vm.extras['carb'], '현미');
      expect(notified, 4);
    });

    test('끼니와 상황은 정해진 이름이면 그 종류로, 직접 입력한 이름이면 이름을 따로 기억한다', () {
      vm.setExtra('meal', '아침');
      expect(vm.mealDraft.mealType, MealType.breakfast);
      expect(vm.mealDraft.customMealTypeLabel, isNull);

      vm.setExtra('meal', '야식');
      expect(vm.extras['meal'], '야식');
      expect(vm.mealDraft.customMealTypeLabel, '야식');

      vm.setExtra('context', '배달');
      expect(vm.mealDraft.context, MealContext.delivery);
      vm.setExtra('context', '회식');
      expect(vm.extras['context'], '회식');
    });

    test('라벨을 종류로 바꾸는 규칙', () {
      expect(MealDraftViewModel.mealTypeFromLabel('저녁'), MealType.dinner);
      expect(MealDraftViewModel.mealTypeFromLabel('간식'), MealType.snack);
      expect(MealDraftViewModel.mealTypeFromLabel('모르는 값'), MealType.lunch);
      expect(MealDraftViewModel.portionFromLabel('반절'), PortionSize.half);
      expect(MealDraftViewModel.portionFromLabel('직접'), PortionSize.custom);
      expect(MealDraftViewModel.portionFromLabel('?'), PortionSize.full);
    });

    test('직접 입력한 값은 비어 있으면 적용하지 않고, 적용하면 입력칸을 비운다', () {
      expect(vm.applyCustom('meat'), isFalse);

      vm.setCustomInput('meat', '  오리고기 ');
      expect(vm.applyCustom('meat'), isTrue);

      expect(vm.extras['meat'], '오리고기');
      expect(vm.customInputs['meat'], '');
    });

    test('양: 이름으로 고르면 퍼센트가, 퍼센트로 정하면 이름이 맞춰진다', () {
      vm.setPortion('반절');
      expect(vm.portionPct, 50);
      vm.setPortion('1/3');
      expect(vm.portionPct, 33);

      vm.setPortionPct(100);
      expect(vm.portion, '전체');
      vm.setPortionPct(50);
      expect(vm.portion, '반절');
      vm.setPortionPct(70);
      expect(vm.portion, '직접');
      expect(vm.portionRatio, 0.7);
    });

    test('양 퍼센트는 1~300% 안으로 제한한다', () {
      vm.setPortionPct(0);
      expect(vm.portionPct, 1);
      vm.setPortionPct(999);
      expect(vm.portionPct, 300);
    });

    test('채운 정도를 바꾼다', () {
      vm.setFill('반');
      expect(vm.mealDraft.fillLevel, BowlFillLevel.half);
      vm.setFill('1/3');
      expect(vm.mealDraft.fillLevel, BowlFillLevel.third);
      vm.setFill('가득');
      expect(vm.mealDraft.fillLevel, BowlFillLevel.full);
    });
  });

  group('MealDraftViewModel · 태그', () {
    test('태그는 누를 때마다 켜지고 꺼진다', () {
      vm.toggleTag('#집밥');
      expect(vm.tags, ['#집밥']);
      vm.toggleTag('#집밥');
      expect(vm.tags, isEmpty);
    });

    test('직접 입력한 태그는 #을 붙여 추가하고, 입력칸을 비우며, 중복은 막는다', () {
      vm.tagInput = '다이어트';
      expect(vm.addCustomTag(), isTrue);
      expect(vm.tags, ['#다이어트']);
      expect(vm.customTags, ['#다이어트']);
      expect(vm.tagInput, '');

      vm.tagInput = '#다이어트';
      expect(vm.addCustomTag(), isFalse); // 이미 있다
      vm.tagInput = '   ';
      expect(vm.addCustomTag(), isFalse); // 비어 있다
    });
  });

  group('MealDraftViewModel · 보정 칼로리', () {
    int expected(
      int base, {
      double portion = 1,
      double fill = 1,
      double bowl = 1,
    }) {
      var v = base * portion * fill * bowl;
      v *= DietRules.cookFactor['볶음'] ?? 1.0;
      v *= DietRules.sauceFactor['저당 소스'] ?? 1.0;
      v *= DietRules.proteinFactor['돼지고기'] ?? 1.0;
      return v.round();
    }

    test('처음 값에서는 조리법 · 소스 · 단백질 보정만 반영한다', () {
      expect(vm.adjustedKcal(baseKcal: 450), expected(450));
    });

    test('양이 절반이면 칼로리도 절반이다', () {
      vm.setPortion('반절');

      expect(vm.adjustedKcal(baseKcal: 450), expected(450, portion: 0.5));
    });

    test('직접 정한 퍼센트는 그 비율로 계산한다', () {
      vm.setPortionPct(150);

      expect(vm.adjustedKcal(baseKcal: 400), expected(400, portion: 1.5));
    });

    test('그릇 크기가 반영된다 (그릇이 없으면 1배)', () {
      final big = _bowl(900);
      final small = _bowl(300);

      expect(
        vm.adjustedKcal(baseKcal: 400, bowl: big),
        greaterThan(vm.adjustedKcal(baseKcal: 400, bowl: small)),
      );
      expect(vm.adjustedKcal(baseKcal: 400), expected(400));
    });

    test('채운 정도가 적으면 칼로리도 줄어든다', () {
      final full = vm.adjustedKcal(baseKcal: 500);
      vm.setFill('반');

      expect(vm.adjustedKcal(baseKcal: 500), lessThan(full));
    });
  });

  group('MealDraftViewModel · 자주 쓰는 설정', () {
    test('지금 값을 스냅샷으로 저장해 둔다', () {
      vm.setExtra('meat', '두부');
      vm.setPortion('반절');
      vm.setFill('반');

      vm.saveExtrasAsPreset(bowlIndex: 2);

      expect(vm.savedPreset!['meat'], '두부');
      expect(vm.savedPresetBowlIndex, 2);
      expect(vm.savedPresetPortion, '반절');
      expect(vm.savedPresetFill, '반');

      // 이후 값을 바꿔도 저장해 둔 값은 그대로다.
      vm.setExtra('meat', '소고기');
      expect(vm.savedPreset!['meat'], '두부');
    });
  });

  group('AppState 연결', () {
    test('입력값을 바꾸면 보정 칼로리가 바뀌고 구독자에게도 전달된다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      var notified = 0;
      s.addListener(() => notified++);
      final before = s.adjustedKcal;

      s.setPortion('반절');

      expect(s.adjustedKcal, lessThan(before));
      expect(notified, greaterThan(0));
    });

    test('식단을 기록하면 지금 입력값(끼니 · 소스)이 담긴다', () {
      final s = AppState(now: () => DateTime(2026, 10, 18));
      s.setExtra('meal', '저녁');
      s.setExtra('sauce', '간장');

      s.logMeal();

      final log = s.todayMeals.last;
      expect(log.mealType, MealType.dinner);
      expect(log.sauce, '간장');
    });
  });
}
