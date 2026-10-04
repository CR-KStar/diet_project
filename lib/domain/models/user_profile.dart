import 'package:flutter/material.dart' show Color;
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'enums.dart';

/// 앱 사용자 기본 정보
class User {
  const User({
    required this.id,
    required this.nickname,
    required this.emoji,
    required this.tint,
  });

  static const String meId = 'u_me';

  final String id;
  final String nickname;
  final String emoji;
  final Color tint;
}

/// 사용자의 신체 정보 및 다이어트 목표 (계산 로직 포함)
///
/// 목표·활동량·성별은 정해진 선택지라 내부적으로는 enum(DietGoal,
/// ActivityLevel, Gender)으로 보관합니다. 화면 쪽 코드는 계속 문자열
/// getter/setter(goal, activity, gender)를 쓰면 되고, 대신 그 문자열이
/// enums.dart에 정의된 값이 아니면 컴파일 시점에 걸러집니다.
class UserProfile {
  UserProfile({
    required this.userId,
    String goal = '체중 감량',
    String activity = '보통',
    String gender = '여성',
    this.heightCm = 168,
    this.weightKg = 56.7,
    this.age = 29,
    double? goalWeight,
  }) : goalWeight = goalWeight ?? weightKg,
       _goal = _goalFromLabel(goal),
       _activity = _activityFromLabel(activity),
       _gender = _genderFromLabel(gender);

  /// 이 신체 정보의 주인 — User.id
  final String userId;

  /// 앱 내부에서는 enum으로 보관하고, 기존 화면은 label getter로 읽습니다.
  DietGoal _goal;
  ActivityLevel _activity;
  Gender _gender;

  DietGoal get goalType => _goal;
  ActivityLevel get activityLevel => _activity;
  Gender get genderType => _gender;

  String get goal => _goal.label;
  set goal(String value) => _goal = _goalFromLabel(value);

  String get activity => _activity.label;
  set activity(String value) => _activity = _activityFromLabel(value);

  String get gender => _gender.label;
  set gender(String value) => _gender = _genderFromLabel(value);

  double heightCm;
  double weightKg;
  int age;
  double goalWeight;

  /// 체질량지수 (BMI) = 몸무게(kg) / 키(m)^2
  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  /// 기초대사량 (BMR) — 해리스-베네딕트 공식
  double get bmr => _gender == Gender.female
      ? 10 * weightKg + 6.25 * heightCm - 5 * age - 161
      : 10 * weightKg + 6.25 * heightCm - 5 * age + 5;

  /// 활동량과 감량 목표를 반영한 일일 권장 섭취 칼로리
  int get dailyTarget {
    final f = DietRules.activityFactor[_activity.label] ?? 1.375;
    final base = bmr * f - (_goal == DietGoal.loseWeight ? 300 : 0);
    return (base / 10).round() * 10;
  }

  /// 목표 체중까지 남은 차이와 예상 소요 기간
  String get goalDelta {
    final d = weightKg - goalWeight;
    if (d.abs() < 0.05) return '현재 체중 유지';
    final weeks = (d.abs() / DietRules.weeklyLossPace).round().clamp(1, 999);
    return '${d > 0 ? '-' : '+'}${d.abs().toStringAsFixed(1)}kg · 약 $weeks주';
  }

  static DietGoal _goalFromLabel(String value) => switch (value) {
    '체중 유지' => DietGoal.maintainWeight,
    '근육 증가' => DietGoal.gainMuscle,
    _ => DietGoal.loseWeight,
  };

  static ActivityLevel _activityFromLabel(String value) => switch (value) {
    '적음' => ActivityLevel.low,
    '많음' => ActivityLevel.high,
    _ => ActivityLevel.moderate,
  };

  static Gender _genderFromLabel(String value) => switch (value) {
    '남성' => Gender.male,
    '공개 안 함' => Gender.undisclosed,
    _ => Gender.female,
  };
}

/// 사용자 알림 설정
class NotificationSettings {
  NotificationSettings({
    required this.userId,
    this.mealReminder = true,
    this.waterReminder = true,
    this.exerciseReminder = false,
    this.friendActivity = true,
    this.morningAlertTime = '08:00',
    this.eveningAlertTime = '21:00',
    this.weeklyReportTime = '일요일 20:00',
  });

  /// 이 알림 설정의 주인 — User.id
  final String userId;
  bool mealReminder;
  bool waterReminder;
  bool exerciseReminder;
  bool friendActivity;

  /// 설정 화면의 "알림 시간" 3종 — 아침 기록 · 저녁 정리 · 주간 리포트.
  String morningAlertTime;
  String eveningAlertTime;
  String weeklyReportTime;
}

/// 개인정보 및 공개 범위 설정
class PrivacySettings {
  PrivacySettings({
    required this.userId,
    this.scope = ShareScope.friends,
    this.shareGarden = true,
    this.shareStreak = true,
    this.shareWeightTrend = false,
    this.shareMealPhotos = true,
    this.shareChallengeRank = true,
  });

  /// 이 공개 범위 설정의 주인 — User.id
  final String userId;
  ShareScope scope;
  bool shareGarden;
  bool shareStreak;
  bool shareWeightTrend;
  bool shareMealPhotos;
  bool shareChallengeRank;
}
