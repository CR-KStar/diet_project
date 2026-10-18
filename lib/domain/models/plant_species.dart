/// 식물 종 정보 (도감 베이스)
class PlantSpecies {
  const PlantSpecies({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    this.condition = '성실하게 기록하면 피어나요.',
    this.emoji = '🌱',
  });

  final String id;
  final String name;
  final String tier;
  final String description;
  final String condition;
  final String emoji;

  static const catalog = [
    PlantSpecies(
      id: 'sp_tulip',
      name: '튤립',
      tier: '일반',
      description: '가장 대중적인 구근 식물입니다.',
      condition: '튜토리얼 완료 시 획득',
      emoji: '🌷',
    ),
    PlantSpecies(
      id: 'sp_sunflower',
      name: '해바라기',
      tier: '일반',
      description: '세 축을 골고루 돌봐주면 피어나요.',
      condition: '균형 7일 유지',
      emoji: '🌻',
    ),
    PlantSpecies(
      id: 'sp_rose',
      name: '장미',
      tier: '일반',
      description: '화려한 꽃의 대명사입니다.',
      condition: '식단 30회 기록',
      emoji: '🌹',
    ),
    PlantSpecies(
      id: 'sp_daisy',
      name: '데이지',
      tier: '일반',
      description: '순수한 마음을 상징합니다.',
      condition: '물 10L 마시기',
      emoji: '🌼',
    ),
    PlantSpecies(
      id: 'sp_monstera',
      name: '몬스테라',
      tier: '희귀',
      description: '정성이 많이 필요한 품종입니다.',
      condition: '연속 14일 기록',
      emoji: '🌿',
    ),
    PlantSpecies(
      id: 'sp_cactus',
      name: '선인장',
      tier: '일반',
      description: '물이 조금 적어도 잘 자라요.',
      condition: '운동 10회 기록',
      emoji: '🌵',
    ),
    PlantSpecies(
      id: 'sp_sprout',
      name: '새싹',
      tier: '일반',
      description: '모든 식물의 시작입니다.',
      condition: '첫 기록 시 획득',
      emoji: '🌱',
    ),
    PlantSpecies(
      id: 'sp_cherry_blossom',
      name: '벚꽃',
      tier: '희귀',
      description: '봄의 전령사입니다.',
      condition: '축 100% 달성',
      emoji: '🌸',
    ),
    PlantSpecies(
      id: 'sp_rubber_tree',
      name: '고무나무',
      tier: '일반',
      description: '공기 정화 능력이 탁월합니다.',
      condition: '누적 20회 기록',
      emoji: '🌳',
    ),
    PlantSpecies(
      id: 'sp_clover',
      name: '클로버',
      tier: '일반',
      description: '행운을 가져다줍니다.',
      condition: '미션 50회 달성',
      emoji: '☘️',
    ),
    PlantSpecies(
      id: 'sp_rice',
      name: '벼',
      tier: '일반',
      description: '한국인의 주식입니다.',
      condition: '아침 식사 10회',
      emoji: '🌾',
    ),
    PlantSpecies(
      id: 'sp_lotus',
      name: '연꽃',
      tier: '희귀',
      description: '진흙 속에서 피어나는 꽃입니다.',
      condition: '물 기록 50회',
      emoji: '🪷',
    ),
    PlantSpecies(
      id: 'sp_moss_fern',
      name: '이끼 고사리',
      tier: '희귀',
      description: '습한 곳을 좋아합니다.',
      condition: '밤 기록 10회',
      emoji: '🍄',
    ),
    PlantSpecies(
      id: 'sp_conifer',
      name: '침엽수',
      tier: '일반',
      description: '늘 푸른 나무입니다.',
      condition: '운동 300분',
      emoji: '🌲',
    ),
    PlantSpecies(
      id: 'sp_bamboo',
      name: '대나무',
      tier: '일반',
      description: '곧게 자라는 성질이 있습니다.',
      condition: '체중 5회 기록',
      emoji: '🎍',
    ),
    PlantSpecies(
      id: 'sp_mutant_tulip',
      name: '변이 튤립',
      tier: '전설',
      description: '기적적으로 태어난 튤립입니다.',
      condition: '전설 씨앗 부화',
      emoji: '🌷',
    ),
    PlantSpecies(
      id: 'sp_golden_rose',
      name: '황금 장미',
      tier: '전설',
      description: '영원한 사랑을 뜻합니다.',
      condition: '챌린지 1위 3회',
      emoji: '🌹',
    ),
    PlantSpecies(
      id: 'sp_rare_hibiscus',
      name: '희귀 무궁화',
      tier: '전설',
      description: '나라를 상징하는 귀한 꽃입니다.',
      condition: '도감 80% 달성',
      emoji: '🌺',
    ),
  ];
}
