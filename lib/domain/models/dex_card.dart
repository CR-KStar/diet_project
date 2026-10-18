import 'package:diet_project/domain/models/dex_entry.dart';
import 'package:diet_project/domain/models/plant_species.dart';
import 'package:diet_project/domain/rules/dex_rules.dart';

/// 도감 화면용 결합 모델
class DexCard {
  DexCard(this.species, this.entry);

  final PlantSpecies species;
  final DexEntry entry;

  String get speciesId => species.id;
  String get name => species.name;
  String get tier => species.tier;
  String get emoji => species.emoji;
  String get condition => species.condition;

  /// 이 조건을 계산할 기록이 아직 없어서 열 수 없는 식물.
  bool get comingSoon => !entry.owned && DexRules.isComingSoon(species.id);
  bool get owned => entry.owned;
  int get progress => entry.progress;

  /// AppState와 도감 화면에서 요구하는 필드들
  int get ownedVariants => owned ? 1 : 0;
  List<String> get variants => ['기본']; // 일단 기본형만 있다고 가정
}
