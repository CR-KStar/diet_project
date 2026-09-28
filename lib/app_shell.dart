import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common.dart';
import 'ui/onboarding/widgets/login_page.dart';
import 'ui/onboarding/widgets/onboarding_page.dart';
import 'ui/home/widgets/home_page.dart';
import 'ui/home/widgets/notification_page.dart';
import 'ui/home/widgets/nutrient_detail_page.dart';
import 'ui/home/widgets/meal_recommend_page.dart';
import 'ui/growth/widgets/my_plant_page.dart';
import 'ui/record/widgets/record_tab_page.dart';
import 'ui/record/widgets/meal_record_page.dart';
import 'ui/record/widgets/daily_entry_page.dart';
import 'ui/report_settings/widgets/report_page.dart';
import 'ui/social/widgets/social_page.dart';
import 'ui/report_settings/widgets/my_page.dart';
import 'ui/report_settings/widgets/settings_page.dart';

/// FAB을 눌렀을 때 뜨는 빠른 기록 시트 — 식단/운동/체중/물 4가지 바로가기
class QuickSheet extends StatelessWidget {
  const QuickSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    Widget tile(String emoji, String title, String desc, VoidCallback onTap) =>
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.primaryTint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 10),
                  Text(title, style: t(14, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(desc, style: t(11, c: AppColor.textFaint)),
                ],
              ),
            ),
          ),
        );

    return SheetScaffold(
      title: '빠른 기록',
      onClose: s.closeFab,
      child: Column(
        children: [
          Row(
            children: [
              tile('🍽️', '식단 기록', '사진 + 부가 정보', () => s.go('capture')),
              const SizedBox(width: 12),
              tile('🏃', '운동 기록', '루틴 불러오기', () => s.go('exercise')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              tile('⚖️', '체중 기록', '눈바디 사진', () => s.go('weight')),
              const SizedBox(width: 12),
              tile('💧', '물 기록', '컵 단위로 빠르게', () {
                s.setSub(() {
                  s.fabOpen = false;
                  s.waterSheet = true;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// 그릇 선택 바텀 시트 — 부가 정보 화면의 "변경 ›"에서 열림
class BowllPickSheet extends StatelessWidget {
  const BowllPickSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    return SheetScaffold(
      title: '그릇 선택',
      onClose: () => s.setSub(() => s.bowlSheet = false),
      child: Column(
        children: [
          for (final entry in s.bowls.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  s.selectBowl(entry.key);
                  s.setSub(() => s.bowlSheet = false);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppDeco.selectableCard(
                    selected: entry.key == s.bowlIndex,
                  ),
                  child: Row(
                    children: [
                      IconTile(
                        entry.value.icon,
                        size: 44,
                        radius: 22,
                        bg: AppColor.surfaceSunken,
                        fontSize: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  entry.value.name,
                                  style: t(15, w: FontWeight.w700),
                                ),
                                if (entry.value.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Pill('기본 그릇', fontSize: 10),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.value.capacityMl}ml · ${entry.value.material}',
                              style: t(12, c: AppColor.textFaint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // 화면 본문
            Positioned.fill(
              bottom: s.showShell ? AppSize.tabBarHeight : 0,
              child: _ScreenBody(screen: s.screen),
            ),
            // 하단 탭바
            if (s.showShell)
              const Align(alignment: Alignment.bottomCenter, child: _TabBar()),
            if (s.showShell) const _DraggableFab(),
            if (s.fabOpen)
              _SheetOverlay(onClose: s.closeFab, child: const QuickSheet()),
            if (s.waterSheet)
              _SheetOverlay(
                onClose: () => s.setSub(() => s.waterSheet = false),
                child: const WaterSheet(),
              ),
            if (s.bowlSheet)
              _SheetOverlay(
                onClose: () => s.setSub(() => s.bowlSheet = false),
                child: const BowllPickSheet(),
              ),
          ],
        ),
      ),
    );
  }
}

/// 바텀 시트 배경(딤) + 하단 고정 + 슬라이드 인 애니메이션
class _SheetOverlay extends StatelessWidget {
  const _SheetOverlay({required this.onClose, required this.child});
  final VoidCallback onClose;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: onClose,
          child: Container(color: const Color(0x59141916)),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(begin: const Offset(0, 1), end: Offset.zero),
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOut,
          builder: (context, offset, c) =>
              FractionalTranslation(translation: offset, child: c),
          child: child,
        ),
      ),
    ],
  );
}

/// screen 문자열 -> 화면 위젯
class _ScreenBody extends StatelessWidget {
  const _ScreenBody({required this.screen});
  final String screen;
  @override
  Widget build(BuildContext context) {
    final body = switch (screen) {
      'login' => const LoginPage(),
      'onboard' => const OnboardingPage(),
      'home' => const HomeScreen(),
      'notif' => const NotifScreen(),
      'nutrition' => const NutritionScreen(),
      'recommend' => const RecommendScreen(),
      'plant' => const PlantScreen(),
      'records' => const RecordsScreen(),
      'capture' => const CaptureScreen(),
      'mealDetail' => const MealDetailScreen(),
      'exercise' => const ExerciseScreen(),
      'weight' => const WeightScreen(),
      'bowls' => const BowlsScreen(),
      'report' => const ReportScreen(),
      'friends' => const FriendsScreen(),
      'chNew' => const ChallengeNewScreen(),
      'my' => const MyScreen(),
      'profile' => const MyScreen(), // 내 정보 수정은 마이의 편집 모드
      'settings' => const SettingsScreen(),
      _ => const HomeScreen(),
    };
    return body;
  }
}

// 하단 탭바
class _TabBar extends StatelessWidget {
  const _TabBar();
  static const _tabs = [
    ('home', '🏠', '홈'),
    ('records', '📋', '기록'),
    ('report', '📊', '리포트'),
    ('friends', '👥', '친구'),
    ('my', '👤', '마이'),
  ];
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Container(
      height: AppSize.tabBarHeight,
      padding: const EdgeInsets.only(top: 14, left: 6, right: 6),
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: Color(0xFFEEF1F2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _tabs.map((tab) {
          final group = AppState.tabGroups[tab.$1] ?? [tab.$1];
          final active = group.contains(s.screen);
          return Expanded(
            child: GestureDetector(
              onTap: () => s.go(tab.$1),
              behavior: HitTestBehavior.opaque,
              child: Opacity(
                opacity: active ? 1 : 0.5,
                child: Column(
                  children: [
                    SizedBox(
                      height: 22,
                      child: Center(
                        child: Text(
                          tab.$2,
                          style: const TextStyle(fontSize: 19),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tab.$3,
                      style: t(
                        10,
                        w: active ? FontWeight.w700 : FontWeight.w500,
                        c: active ? AppColor.primary : AppColor.textFaint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? AppColor.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 드래그 가능한 빠른 기록 버튼
class _DraggableFab extends StatefulWidget {
  const _DraggableFab();
  @override
  State<_DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<_DraggableFab> {
  Offset? _pos;
  bool _dragging = false;
  bool _moved = false;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // LayoutBuilder를 쓰는 이유: MediaQuery.size는 상태표시줄 등을 뺀 실제 크기가
    // 아니라서(SafeArea가 그 위에서 별도로 보정) 상태표시줄 높이만큼 어긋나기 쉬워요.
    // constraints는 이 위젯이 실제로 배치되는 박스 크기 그 자체라 항상 정확해요.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        // 탭바는 좌우 6px 패딩 안에 5개 탭이 균등폭(Expanded)으로 배치돼요.
        // '마이' 탭의 살짝 오른쪽 위, 탭바 바로 위에 기본 위치를 계산합니다.
        final tabWidth = (width - 12) / 5;
        final myTabCenterX = 6 + 4.5 * tabWidth + 12;
        final pos =
            _pos ??
            Offset(
              myTabCenterX - AppSize.fabSize / 2,
              height - AppSize.tabBarHeight - AppSize.fabSize - 16,
            );
        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onTap: () {
                  if (_moved) {
                    setState(() => _moved = false);
                    return;
                  }
                  s.toggleFab();
                },
                onPanStart: (_) => setState(() => _dragging = true),
                onPanUpdate: (d) => setState(() {
                  _moved = true;
                  final next = (_pos ?? pos) + d.delta;
                  _pos = Offset(
                    next.dx.clamp(10.0, width - AppSize.fabSize - 10),
                    next.dy.clamp(10.0, height - AppSize.fabSize - 20),
                  );
                }),
                onPanEnd: (_) => setState(() => _dragging = false),
                child: AnimatedScale(
                  scale: _dragging ? 1.08 : 1,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                    width: AppSize.fabSize,
                    height: AppSize.fabSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadow.fab,
                    ),
                    child: const Text(
                      '+',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
