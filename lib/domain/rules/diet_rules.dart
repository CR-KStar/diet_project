// 다이어트 앱의 계산 규칙(칼로리 보정 계수 · 식물 성장 규칙 등) — 화면과 상관없는 값들이다.

abstract final class DietRules {
  /// 부가 정보 보정 계수 — 조리법
  static const cookFactor = <String, double>{
    '구이': 1.0,
    '볶음': 1.0,
    '찜': 0.9,
    '튀김': 1.25,
    '생식': 0.9,
    '찌개': 1.0,
  };

  /// 부가 정보 보정 계수 — 소스
  static const sauceFactor = <String, double>{
    '저당 소스': 0.94,
    '일반 소스': 1.0,
    '올리브오일': 1.0,
    '버터': 1.0,
    '무가당': 0.94,
  };

  /// 부가 정보 보정 계수 — 단백질
  static const proteinFactor = <String, double>{
    '돼지고기': 1.0,
    '소고기': 1.0,
    '닭가슴살': 0.88,
    '생선': 1.0,
    '두부': 0.88,
  };

  /// 섭취 분량 비율
  static const portionRatio = <String, double>{
    '전체': 1.0,
    '반절': 0.5,
    '1/3': 0.33,
  };

  /// 그릇 채움 정도
  static const fillRatio = <String, double>{'가득': 1.0, '반': 0.5, '1/3': 0.33};

  /// 운동 종류 계수 (미등록 종류는 1.0)
  static const exerciseTypeFactor = <String, double>{
    '달리기': 1.2,
    '걷기': 0.7,
    '자전거': 1.0,
    '근력': 0.9,
    '요가': 0.6,
    '수영': 1.3,
    '등산': 1.1,
  };

  /// 운동 강도 계수 (분당 kcal 기준값)
  static const exerciseIntensityFactor = <String, int>{
    '낮음': 5,
    '보통': 8,
    '높음': 11,
  };

  /// 활동량 계수 (권장 칼로리 산출)
  static const activityFactor = <String, double>{
    '적음': 1.2,
    '보통': 1.375,
    '많음': 1.55,
  };

  /// 식물 성장 축 — 돌보기 1회당 EXP
  static const careExp = <String, int>{'물 주기': 10, '햇빛 받기': 15, '영양 주기': 20};

  /// 식물 단계 (레벨 하한)
  static const plantStages = <String, int>{
    '씨앗': 1,
    '새싹': 5,
    '어린잎': 10,
    '무성한잎': 15,
    '꽃': 20,
  };

  /// 균형 판정: 3축 최대-최소 차이가 이 값 이하면 '균형'
  static const balanceSpreadThreshold = 20;

  /// 시듦 시작 (미기록 일수) / 회복 유예 (일)
  static const wiltAfterDays = 2;
  static const graceDays = 3;

  /// 목표 체중 감량 페이스 (kg/주)
  static const weeklyLossPace = 0.4;

  /// 그릇 최대 등록 개수
  static const maxBowls = 20;

  /// 친구 정원 물 주기 하루 한도 / 회당 EXP
  static const dailyFriendWatering = 3;
  static const friendWateringExp = 5;
}
