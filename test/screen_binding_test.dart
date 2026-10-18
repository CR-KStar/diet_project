import 'package:diet_project/app_providers.dart';
import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diet_project/utils/app_state_format.dart';

/// 화면이 AppState 하나가 아니라 자기 ViewModel을 직접 구독한다 — AppState가 변경을 대신
/// 알려주지 않아도, ViewModel이 바뀌면 그 값을 보여주는 화면이 다시 그려져야 한다.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<AppState> pumpAt(WidgetTester tester, String screen) async {
    // 테스트용 글꼴은 실제 글꼴보다 커서 몇 px 넘치는 경고가 나는데, 여기서 보려는 것이 아니다.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final state = AppState(now: () => DateTime(2026, 10, 18));
    state.go(screen);
    await tester.pumpWidget(
      AppProviders(
        state: state,
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    return state;
  }

  testWidgets('내 정보를 바꾸면 홈의 권장 칼로리가 바로 바뀐다', (tester) async {
    final state = await pumpAt(tester, 'home');
    final before = state.dailyTarget;
    expect(find.text('${AppStateFormat.comma(before)} kcal'), findsWidgets);

    state.profileViewModel.gender = state.gender == '남성' ? '여성' : '남성';
    await tester.pump();

    final after = state.dailyTarget;
    expect(after, isNot(before));
    expect(find.text('${AppStateFormat.comma(after)} kcal'), findsWidgets);
    expect(find.text('${AppStateFormat.comma(before)} kcal'), findsNothing);
  });

  testWidgets('물을 기록하면 홈의 물 카드가 바로 바뀐다', (tester) async {
    final state = await pumpAt(tester, 'home');
    expect(find.text(AppStateFormat.comma(state.waterTotal)), findsWidgets);

    state.waterViewModel.setWaterInput(300);
    state.waterViewModel.addWater();
    await tester.pump();

    expect(find.text(AppStateFormat.comma(state.waterTotal)), findsWidgets);
  });

  testWidgets('식단을 기록하면 홈의 섭취 칼로리가 바로 바뀐다', (tester) async {
    final state = await pumpAt(tester, 'home');
    final before = state.intakeKcal;
    expect(find.text(AppStateFormat.comma(before)), findsWidgets);

    state.logMeal();
    await tester.pump();

    expect(state.intakeKcal, greaterThan(before));
    expect(find.text(AppStateFormat.comma(state.intakeKcal)), findsWidgets);
  });

  testWidgets('식단 입력값을 바꾸면 식단 화면의 보정 칼로리가 바로 바뀐다', (tester) async {
    final state = await pumpAt(tester, 'capture');
    state.setSub(() => state.extraOpen = true);
    await tester.pump(const Duration(milliseconds: 600));
    final before = state.adjustedKcal;
    expect(find.text('$before'), findsWidgets);

    state.mealDraftViewModel.setExtra('meat', '닭가슴살');
    await tester.pump();

    expect(state.adjustedKcal, lessThan(before));
    expect(find.text('${state.adjustedKcal}'), findsWidgets);
  });

  testWidgets('공개 범위를 바꾸면 친구 화면의 요약이 바로 바뀐다', (tester) async {
    final state = await pumpAt(tester, 'friends');
    expect(find.textContaining('친구만'), findsWidgets);

    state.profileViewModel.setShareScope('비공개');
    await tester.pump();

    expect(find.textContaining('비공개 · 공개 항목'), findsWidgets);
  });

  testWidgets('알림함은 알림이 없으면 가짜 알림 대신 안내를 보여주고, 홈 배지도 없다', (tester) async {
    final state = await pumpAt(tester, 'notif');

    expect(find.text('아직 알림이 없어요'), findsOneWidget);
    expect(find.text('알림 설정'), findsOneWidget);
    expect(find.text('모두 읽음'), findsNothing);
    expect(find.textContaining('지현님'), findsNothing);
    expect(find.textContaining('식물이 물을 기다려요'), findsNothing);
    expect(state.notificationInboxViewModel.unread, 0);
  });

  testWidgets('홈의 알림 종에는 읽지 않은 알림이 없으면 숫자가 보이지 않는다', (tester) async {
    await pumpAt(tester, 'home');

    // 예전에는 모든 계정에 "3"이 떠 있었다.
    expect(find.text('3'), findsNothing);
  });
}
