import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/rules/diet_rules.dart';
import 'package:flutter/foundation.dart';

/// 식단 기록 화면의 입력값 — 끼니 · 상황 · 단백질 · 소스 · 조리법 · 탄수화물 · 양 · 채운 정도 ·
/// 태그 · 메모 — 를 담당한다.
///
/// 입력값은 저장 전까지만 유지되는 Draft 하나가 소유한다. 어느 그릇에 담았는지, 사진 분석으로
/// 얻은 기본 칼로리가 얼마인지는 다른 ViewModel의 일이라, 보정 칼로리는 그 값을 넘겨받아 계산한다.
/// 보정 칼로리 계산에 필요한 다른 ViewModel의 값 — AppState가 그때그때 최신 값으로 만들어 준다.
class MealDraftInputs {
  const MealDraftInputs({this.baseKcal = 450, this.bowl});

  /// AI가 사진만 보고 추정한 기본 칼로리 (분석 전에는 450).
  final int baseKcal;

  /// 지금 고른 그릇 (없으면 null).
  final Bowl? bowl;
}

class MealDraftViewModel extends ChangeNotifier {
  /// 사진 분석과 고른 그릇이 바뀌면 보정 칼로리도 다시 계산하도록 알린다 (AppState가 연결한다).
  void refresh() => notifyListeners();

  /// 보정 칼로리에 쓸 최신 값을 돌려주는 함수 (AppState가 연결한다).
  MealDraftInputs Function() inputs = MealDraftInputs.new;

  /// 지금 입력값과 사진 분석 · 고른 그릇을 반영한 보정 칼로리.
  int get adjustedKcal {
    final i = inputs();
    return adjustedKcalFor(baseKcal: i.baseKcal, bowl: i.bowl);
  }

  /// 식단 화면의 입력값은 이 Draft 하나가 소유합니다.
  final MealDraft mealDraft = MealDraft(
    proteinType: '돼지고기',
    sauce: '저당 소스',
    cookingMethod: '볶음',
    carbohydrateType: '백미',
  );

  Map<String, String> get extras => {
    'meat': mealDraft.proteinType ?? '',
    'sauce': mealDraft.sauce ?? '',
    'cook': mealDraft.cookingMethod ?? '',
    'carb': mealDraft.carbohydrateType ?? '',
    'meal': mealDraft.customMealTypeLabel ?? mealDraft.mealType.label,
    'context': mealDraft.customContextLabel ?? mealDraft.context.label,
  };

  final Map<String, String> customInputs = {
    'meat': '',
    'sauce': '',
    'cook': '',
    'carb': '',
    'meal': '',
    'context': '',
  };

  String get portion => mealDraft.portion.label;
  int get portionPct => mealDraft.portionPercent;
  String get fill => mealDraft.fillLevel.label;
  List<String> get tags => mealDraft.tags;
  List<String> customTags = [];
  String tagInput = '';
  String get memo => mealDraft.memo;
  set memo(String value) => mealDraft.memo = value;

  /// 부가 정보 화면에서 "자주 쓰는 설정으로 저장" 했을 때의 스냅샷
  Map<String, String>? savedPreset;
  int? savedPresetBowlIndex;
  String? savedPresetPortion;
  String? savedPresetFill;

  void saveExtrasAsPreset({required int bowlIndex}) {
    savedPreset = Map.of(extras);
    savedPresetBowlIndex = bowlIndex;
    savedPresetPortion = portion;
    savedPresetFill = fill;
    notifyListeners();
  }

  double get portionRatio => mealDraft.portion == PortionSize.custom
      ? mealDraft.portionPercent / 100
      : (DietRules.portionRatio[portion] ?? 1.0);

  /// 부가 정보(조리법 · 소스 · 단백질) · 양 · 채운 정도 · 그릇 크기를 반영한 보정 칼로리.
  /// [baseKcal]은 AI가 사진만 보고 추정한 기본 칼로리다.
  int adjustedKcalFor({required int baseKcal, Bowl? bowl}) {
    var v =
        baseKcal *
        portionRatio *
        (DietRules.fillRatio[fill] ?? 1.0) *
        (bowl?.capacityFactor ?? 1.0);
    v *= DietRules.cookFactor[extras['cook']] ?? 1.0;
    v *= DietRules.sauceFactor[extras['sauce']] ?? 1.0;
    v *= DietRules.proteinFactor[extras['meat']] ?? 1.0;
    return v.round();
  }

  void setExtra(String key, String value) {
    switch (key) {
      case 'meat':
        mealDraft.proteinType = value;
        break;
      case 'sauce':
        mealDraft.sauce = value;
        break;
      case 'cook':
        mealDraft.cookingMethod = value;
        break;
      case 'carb':
        mealDraft.carbohydrateType = value;
        break;
      case 'meal':
        final type = mealTypeFromLabel(value);
        mealDraft.mealType = type;
        mealDraft.customMealTypeLabel = type.label == value ? null : value;
        break;
      case 'context':
        final context = mealContextFromLabel(value);
        mealDraft.context = context;
        mealDraft.customContextLabel = context.label == value ? null : value;
        break;
    }
    notifyListeners();
  }

  void setCustomInput(String key, String value) {
    customInputs[key] = value;
    notifyListeners();
  }

  /// 직접 입력값 적용 — 칩으로 추가되고 즉시 선택됩니다.
  bool applyCustom(String key) {
    final v = (customInputs[key] ?? '').trim();
    if (v.isEmpty) return false;
    customInputs[key] = '';
    setExtra(key, v);
    return true;
  }

  void setPortion(String p) {
    mealDraft.portion = portionFromLabel(p);
    mealDraft.portionPercent =
        {'전체': 100, '반절': 50, '1/3': 33}[p] ?? mealDraft.portionPercent;
    notifyListeners();
  }

  void setPortionPct(int pct) {
    mealDraft.portionPercent = pct.clamp(1, 300);
    mealDraft.portion = pct == 100
        ? PortionSize.full
        : pct == 50
        ? PortionSize.half
        : pct == 33
        ? PortionSize.third
        : PortionSize.custom;
    notifyListeners();
  }

  void toggleTag(String t) {
    tags.contains(t) ? tags.remove(t) : tags.add(t);
    notifyListeners();
  }

  bool addCustomTag() {
    final raw = tagInput.trim();
    if (raw.isEmpty) return false;
    final t = raw.startsWith('#') ? raw : '#$raw';
    if (tags.contains(t)) return false;
    if (!customTags.contains(t)) customTags.add(t);
    tags.add(t);
    tagInput = '';
    notifyListeners();
    return true;
  }

  void setFill(String f) {
    mealDraft.fillLevel = switch (f) {
      '반' => BowlFillLevel.half,
      '1/3' => BowlFillLevel.third,
      _ => BowlFillLevel.full,
    };
    notifyListeners();
  }

  static MealType mealTypeFromLabel(String value) => switch (value) {
    '아침' => MealType.breakfast,
    '저녁' => MealType.dinner,
    '간식' => MealType.snack,
    _ => MealType.lunch,
  };

  static MealContext mealContextFromLabel(String value) => switch (value) {
    '집밥' => MealContext.home,
    '외식' => MealContext.diningOut,
    '배달' => MealContext.delivery,
    '도시락' => MealContext.lunchbox,
    _ => MealContext.other,
  };

  static PortionSize portionFromLabel(String value) => switch (value) {
    '반절' => PortionSize.half,
    '1/3' => PortionSize.third,
    '직접' => PortionSize.custom,
    _ => PortionSize.full,
  };
}
