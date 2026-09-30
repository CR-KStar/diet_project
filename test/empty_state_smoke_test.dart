import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/water_repository.dart';
import 'package:diet_project/ui/record/viewmodel/water_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// 로그인된 실제 계정 — 프로토타입 예시 기록이 비워져서 "기록이 하나도 없는" 상태가 된다.
class _RealAuth implements AuthService {
  @override
  AuthAccount? get currentAccount =>
      const AuthAccount(uid: 'uid_1', provider: LoginProvider.google);

  @override
  Future<AuthAccount?> restoreAccount() async => currentAccount;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => currentAccount;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {}
}

/// 기록이 하나도 없는 새 계정으로 각 화면을 그려도 오류가 나지 않는지 확인한다.
/// (프로토타입은 예시 기록이 있다고 가정하고 만들어져서, 비어 있을 때 멈추는 곳이 있을 수 있다.)
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const screens = [
    'home',
    'notif',
    'nutrition',
    'recommend',
    'plant',
    'records',
    'capture',
    'exercise',
    'weight',
    'bowls',
    'report',
    'friends',
    'chNew',
    'my',
    'settings',
  ];

  for (final screen in screens) {
    testWidgets('기록이 없는 계정: "$screen" 화면이 오류 없이 그려진다', (tester) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final state = AppState(
        auth: _RealAuth(),
        now: () => DateTime(2026, 9, 21),
      );
      await state.restoreSession();
      state.go(screen);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: '"$screen" 화면을 그리다 예외가 났어요',
      );
      expect(state.todayRegistry.meals, isEmpty);
    });
  }

  testWidgets('기록이 없는 계정: 물 기록 시트가 오류 없이 열린다', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final state = AppState(auth: _RealAuth(), now: () => DateTime(2026, 9, 21));
    await state.restoreSession();
    state.waterSheet = true;
    final water = WaterViewModel(waterRepo: MemoryWaterRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: state),
          ChangeNotifierProvider<WaterViewModel>.value(value: water),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('그릇이 하나도 없는 계정: 그릇 선택 시트가 오류 없이 열린다', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final state = AppState(auth: _RealAuth(), now: () => DateTime(2026, 9, 21));
    await state.restoreSession();
    state.bowlSheet = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(state.bowls, isEmpty);
  });
}
