/// 사용자별 식물 획득 상태
class DexEntry {
  DexEntry({
    required this.userId,
    required this.speciesId,
    this.owned = false,
    this.progress = 0,
  });

  final String userId;
  final String speciesId;
  final bool owned;
  final int progress;
}
