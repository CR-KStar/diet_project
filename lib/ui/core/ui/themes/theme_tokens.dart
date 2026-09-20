// 다이어트 관리 앱 v3.0 — Design Tokens
//
// HTML 프로토타입에서 확정된 디자인 값을 Dart 상수로 정리한 파일입니다.
// 화면 구현 시 하드코딩 대신 여기 값을 참조하세요.
//
// 의존: google_fonts (Noto Sans KR)
//
// test

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────
// Colors
// ─────────────────────────────────────────────────────────

abstract final class AppColor {
  // Brand
  static const primary = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF3B8F3F);
  static const primaryTint = Color(0xFFEDF7EE);
  static const primarySoft = Color(0xFFF7FCF7);
  static const secondary = Color(0xFFA8E0A2);

  // Semantic accents
  static const warn = Color(0xFFFFD566); // 탄수화물, 진행 중
  static const warnDeep = Color(0xFFFFB74D); // 지방, 식단
  static const alert = Color(0xFFFF8A65); // 나트륨, 배지, 삭제
  static const alertText = Color(0xFFE0603A); // 경고 텍스트
  static const info = Color(0xFF5D88F4); // 물
  static const teal = Color(0xFF4DB6AC); // 식이섬유, 체중
  static const purple = Color(0xFF9C7BE0); // 온보딩, 시즌 한정

  // Surfaces
  static const bg = Color(0xFFF5F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF7F9FA);
  static const divider = Color(0xFFF0F2F4);
  static const disabled = Color(0xFFE3E7E9);
  static const toggleOff = Color(0xFFDDE2E5);

  // Text
  static const text = Color(0xFF333333);
  static const textStrong = Color(0xFF22271F);
  static const textMuted = Color(0xFF6B7278);
  static const textFaint = Color(0xFF8A9199);
  static const textGhost = Color(0xFFA6ADB4);
  static const iconGhost = Color(0xFFC7CDD2);

  // Home hero gradient (상단 오버레이)
  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEFF8EE), Color(0xFFF5F8F4), Color(0x00F5F8F4)],
    stops: [0.0, 0.62, 1.0],
  );

  // Plant card gradient
  static const plantGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2F9F1), Color(0xFFEAF5E9), Color(0xFFF7FBF2)],
    stops: [0.0, 0.55, 1.0],
  );

  // Today-card tints (홈 오늘의 기록)
  static const tintWater = Color(0xFFEFF4FE);
  static const tintExercise = Color(0xFFEFF7EF);
  static const tintWeight = Color(0xFFECF6F5);
  static const tintMeal = Color(0xFFFFF7EC);
}

// ─────────────────────────────────────────────────────────
// Spacing / Radius / Shadow
// ─────────────────────────────────────────────────────────

abstract final class AppSpace {
  static const screenH = 16.0; // 화면 좌우 패딩 (폼 화면은 20)
  static const screenHForm = 20.0;
  static const cardPad = 18.0; // 카드 내부 (16~20)
  static const cardGap = 14.0; // 카드 사이
  static const sectionGap = 12.0; // 카드 안 섹션 사이
  static const chipGap = 8.0;
}

abstract final class AppRadius {
  static const card = 26.0;
  static const cardInner = 20.0;
  static const chip = 16.0;
  static const button = 20.0;
  static const badge = 10.0;
  static const iconTile = 10.0; // 28×28 타일
  static const phone = 44.0;

  static BorderRadius get cardR => BorderRadius.circular(card);
  static BorderRadius get cardInnerR => BorderRadius.circular(cardInner);
  static BorderRadius get chipR => BorderRadius.circular(chip);
  static BorderRadius get buttonR => BorderRadius.circular(button);
  static BorderRadius get sheetR =>
      const BorderRadius.vertical(top: Radius.circular(26));
}

abstract final class AppShadow {
  /// 카드 기본 — rgba(60, 80, 65, 0.07)
  static const card = [
    BoxShadow(color: Color(0x12435041), blurRadius: 14, offset: Offset(0, 3)),
  ];

  /// 주 버튼 — rgba(76, 175, 80, 0.30)
  static const primaryButton = [
    BoxShadow(color: Color(0x4D4CAF50), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// 플로팅 버튼 — rgba(76, 175, 80, 0.42)
  static const fab = [
    BoxShadow(color: Color(0x6B4CAF50), blurRadius: 20, offset: Offset(0, 8)),
  ];

  /// 홈 아이콘 타일 — rgba(76, 175, 80, 0.16)
  static const tile = [
    BoxShadow(color: Color(0x294CAF50), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

// ─────────────────────────────────────────────────────────
// Typography
// ─────────────────────────────────────────────────────────

abstract final class AppText {
  static TextStyle _base(double size, FontWeight weight,
          {Color? color, double? spacing, double? height}) =>
      GoogleFonts.notoSansKr(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColor.text,
        letterSpacing: spacing,
        height: height,
      );

  /// 탭 루트 화면 대제목
  static TextStyle get tabTitle =>
      _base(20, FontWeight.w900, color: AppColor.textStrong, spacing: -0.3);

  /// 서브 화면 제목
  static TextStyle get screenTitle =>
      _base(17, FontWeight.w900, color: AppColor.textStrong);

  /// 카드 제목
  static TextStyle get cardTitle => _base(15, FontWeight.w900);

  /// 큰 수치 (칼로리 링, 체중 입력)
  static TextStyle metricXL(Color color) =>
      _base(40, FontWeight.w900, color: color, spacing: -1.5);

  /// 중간 수치 (카드 값)
  static TextStyle metric(Color color) =>
      _base(21, FontWeight.w900, color: color, spacing: -0.4);

  /// 본문
  static TextStyle get body =>
      _base(13, FontWeight.w400, color: AppColor.text, height: 1.6);

  /// 라벨
  static TextStyle get label =>
      _base(12, FontWeight.w500, color: AppColor.textFaint);

  /// 힌트 / 단위
  static TextStyle get hint =>
      _base(11, FontWeight.w400, color: AppColor.textGhost, height: 1.55);

  /// 배지
  static TextStyle badge(Color color) =>
      _base(10, FontWeight.w700, color: color);

  /// 숫자 전용 (그릇 용량, 인증 코드)
  static TextStyle get mono => GoogleFonts.ibmPlexMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColor.text,
      );
}

// ─────────────────────────────────────────────────────────
// Reusable decorations
// ─────────────────────────────────────────────────────────

abstract final class AppDeco {
  /// 기본 카드
  static BoxDecoration get card => BoxDecoration(
        color: AppColor.surface,
        borderRadius: AppRadius.cardR,
        boxShadow: AppShadow.card,
      );

  /// 카드 안 서브 블록
  static BoxDecoration get sunken => BoxDecoration(
        color: AppColor.surfaceSunken,
        borderRadius: AppRadius.cardInnerR,
      );

  /// 칩 (선택 여부에 따라)
  static BoxDecoration chip({required bool selected}) => BoxDecoration(
        color: selected ? AppColor.primaryTint : AppColor.surfaceSunken,
        borderRadius: AppRadius.chipR,
        border: Border.all(
          color: selected ? AppColor.primary : Colors.transparent,
          width: 1.5,
        ),
      );

  /// 선택 가능한 카드 (라디오 카드, 그릇 항목)
  static BoxDecoration selectableCard({required bool selected}) =>
      BoxDecoration(
        color: selected ? AppColor.primarySoft : AppColor.surface,
        borderRadius: AppRadius.cardInnerR,
        border: Border.all(
          color: selected ? AppColor.primary : AppColor.divider,
          width: 1.5,
        ),
      );

  /// 주 버튼 (활성 / 비활성)
  static BoxDecoration primaryButton({bool enabled = true}) => BoxDecoration(
        color: enabled ? AppColor.primary : AppColor.disabled,
        borderRadius: AppRadius.buttonR,
        boxShadow: enabled ? AppShadow.primaryButton : null,
      );

  /// 화면 제목 옆 아이콘 타일 (28×28)
  static BoxDecoration get iconTile => BoxDecoration(
        color: AppColor.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.iconTile),
      );
}

// ─────────────────────────────────────────────────────────
// Chip / progress-bar sizing
// ─────────────────────────────────────────────────────────

abstract final class AppSize {
  static const chipPad = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
  static const buttonPad = EdgeInsets.symmetric(vertical: 16);

  static const barThin = 5.0; // 카드 안 미니 진행 바
  static const barBase = 7.0; // 일반 진행 바
  static const barThick = 9.0; // 홈 영양소 / 식물 EXP

  static const tabBarHeight = 84.0;
  static const fabSize = 56.0;
  static const minTapTarget = 44.0;
  static const textLinkHeight = 46.0; // 보조 액션 텍스트 링크
}

// ─────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColor.primary,
      primary: AppColor.primary,
      surface: AppColor.surface,
    ),
    scaffoldBackgroundColor: AppColor.bg,
  );

  return base.copyWith(
    textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).apply(
      bodyColor: AppColor.text,
      displayColor: AppColor.textStrong,
    ),
    dividerColor: AppColor.divider,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColor.textStrong,
      contentTextStyle: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColor.surfaceSunken,
      border: OutlineInputBorder(
        borderRadius: AppRadius.chipR,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      hintStyle: AppText.hint,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetR),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Domain constants (기획서 확정 값)
// ─────────────────────────────────────────────────────────

abstract final class DietRules {
  /// 부가 정보 보정 계수 — 조리법
  static const cookFactor = <String, double>{
    '구이': 1.0, '볶음': 1.0, '찜': 0.9, '튀김': 1.25, '생식': 0.9, '찌개': 1.0,
  };

  /// 부가 정보 보정 계수 — 소스
  static const sauceFactor = <String, double>{
    '저당 소스': 0.94, '일반 소스': 1.0, '올리브오일': 1.0, '버터': 1.0, '무가당': 0.94,
  };

  /// 부가 정보 보정 계수 — 단백질
  static const proteinFactor = <String, double>{
    '돼지고기': 1.0, '소고기': 1.0, '닭가슴살': 0.88, '생선': 1.0, '두부': 0.88,
  };

  /// 섭취 분량 비율
  static const portionRatio = <String, double>{'전체': 1.0, '반절': 0.5, '1/3': 0.33};

  /// 그릇 채움 정도
  static const fillRatio = <String, double>{'가득': 1.0, '반': 0.5, '1/3': 0.33};

  /// 운동 종류 계수 (미등록 종류는 1.0)
  static const exerciseTypeFactor = <String, double>{
    '달리기': 1.2, '걷기': 0.7, '자전거': 1.0, '근력': 0.9,
    '요가': 0.6, '수영': 1.3, '등산': 1.1,
  };

  /// 운동 강도 계수 (분당 kcal 기준값)
  static const exerciseIntensityFactor = <String, int>{'낮음': 5, '보통': 8, '높음': 11};

  /// 활동량 계수 (권장 칼로리 산출)
  static const activityFactor = <String, double>{'적음': 1.2, '보통': 1.375, '많음': 1.55};

  /// 식물 성장 축 — 돌보기 1회당 EXP
  static const careExp = <String, int>{'물 주기': 10, '햇빛 받기': 15, '영양 주기': 20};

  /// 식물 단계 (레벨 하한)
  static const plantStages = <String, int>{
    '씨앗': 1, '새싹': 5, '어린잎': 10, '무성한잎': 15, '꽃': 20,
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

  /// 친구 정원 물 주기 하루 한도 / 회당 EXP (양쪽)
  static const dailyFriendWatering = 3;
  static const friendWateringExp = 5;
}
