import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';

/// 앱의 아이콘 모음 — 화면 장식용 이모지 대신 Flutter 아이콘을 쓴다.
///
/// 이모지는 기기 · 웹 글꼴에 따라 모양이 달라지거나 네모로 깨져 보일 수 있어서, 메뉴 · 제목 ·
/// 버튼처럼 화면이 정해 둔 자리의 아이콘은 여기 있는 것을 쓴다. 식물 · 음식 · 그릇처럼
/// "내용" 자체인 그림(식물 도감, AI가 추천한 메뉴 …)은 이모지로 남긴다.
abstract final class AppIcons {
  // 하단 탭
  static const home = Icons.home_rounded;
  static const records = Icons.assignment_rounded;
  static const report = Icons.bar_chart_rounded;
  static const friends = Icons.group_rounded;
  static const my = Icons.person_rounded;

  // 기록 종류
  static const meal = Icons.restaurant_rounded;
  static const exercise = Icons.directions_run_rounded;
  static const weight = Icons.monitor_weight_rounded;
  static const water = Icons.water_drop_rounded;
  static const bowl = Icons.rice_bowl_rounded;

  // 영양소
  static const protein = Icons.egg_alt_rounded;
  static const carb = Icons.rice_bowl_rounded;
  static const fat = Icons.opacity_rounded;
  static const fiber = Icons.grass_rounded;
  static const sodium = Icons.grain_rounded;

  // 식물 돌보기 · 보상
  static const sun = Icons.wb_sunny_rounded;
  static const nutrition = Icons.shopping_basket_rounded;
  static const plant = Icons.eco_rounded;
  static const seed = Icons.grain_rounded;
  static const sparkle = Icons.auto_awesome_rounded;
  static const gem = Icons.diamond_rounded;
  static const trophy = Icons.emoji_events_rounded;
  static const fire = Icons.local_fire_department_rounded;
  static const target = Icons.track_changes_rounded;
  static const dex = Icons.menu_book_rounded;
  static const gardenDecor = Icons.yard_rounded;

  // 동작 · 상태
  static const notifications = Icons.notifications_rounded;
  static const calendar = Icons.calendar_month_rounded;
  static const camera = Icons.photo_camera_rounded;
  static const warning = Icons.warning_amber_rounded;
  static const edit = Icons.edit_rounded;
  static const settings = Icons.settings_rounded;
  static const lock = Icons.lock_rounded;
  static const link = Icons.link_rounded;
  static const close = Icons.close_rounded;
  static const check = Icons.check_rounded;
  static const sourceBook = Icons.library_books_rounded;
  static const document = Icons.description_rounded;
  static const terms = Icons.gavel_rounded;
  static const back = Icons.chevron_left_rounded;
}

/// 기록 종류별 아이콘 색.
abstract final class AppIconColors {
  static const meal = AppColor.warnDeep;
  static const exercise = AppColor.primary;
  static const weight = AppColor.teal;
  static const water = AppColor.info;
}
