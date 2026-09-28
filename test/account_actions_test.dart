import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/profile_repository.dart';
import 'package:diet_project/ui/report_settings/widgets/my_page.dart';
import 'package:diet_project/ui/report_settings/widgets/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _account = AuthAccount(
  uid: 'uid_1',
  provider: LoginProvider.google,
  displayName: '지민',
);

class _FakeAuth implements AuthService {
  @override
  AuthAccount? get currentAccount => _account;

  @override
  Future<AuthAccount?> restoreAccount() async => _account;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => _account;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {
    await beforeDelete?.call();
  }
}

Future<AppState> _loggedInState(MemoryProfileRepository repo) async {
  await repo.save(
    'uid_1',
    SavedProfile(
      nickname: '지민',
      onboardingDone: true,
      profile: UserProfile(userId: 'uid_1'),
      notifications: NotificationSettings(userId: 'uid_1'),
      privacy: PrivacySettings(userId: 'uid_1'),
    ),
  );
  final state = AppState(auth: _FakeAuth(), profiles: repo);
  await state.restoreSession();
  return state;
}

Future<void> _pump(WidgetTester tester, AppState state, Widget screen) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
}

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('마이 화면 · 로그아웃', () {
    testWidgets('확인창에서 "로그아웃"을 누르면 로그아웃되고 로그인 화면으로 간다', (tester) async {
      final state = await _loggedInState(MemoryProfileRepository());
      await _pump(tester, state, const MyScreen());

      await tester.ensureVisible(find.text('로그아웃'));
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      expect(find.text('로그아웃할까요?'), findsOneWidget);

      await tester.tap(_inDialog('로그아웃'));
      await tester.pumpAndSettle();

      expect(state.account, isNull);
      expect(state.screen, 'login');
    });

    testWidgets('확인창에서 "취소"를 누르면 로그인 상태가 그대로다', (tester) async {
      final state = await _loggedInState(MemoryProfileRepository());
      await _pump(tester, state, const MyScreen());

      await tester.ensureVisible(find.text('로그아웃'));
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      await tester.tap(_inDialog('취소'));
      await tester.pumpAndSettle();

      expect(state.account, isNotNull);
      expect(state.screen, 'home');
    });
  });

  group('설정 · 계정 삭제', () {
    testWidgets('확인창에서 "삭제"를 누르면 저장된 정보까지 지워지고 로그인 화면으로 간다', (tester) async {
      final repo = MemoryProfileRepository();
      final state = await _loggedInState(repo);
      state.setSetTab('데이터 · 개인정보');
      await _pump(tester, state, const SettingsScreen());

      await tester.ensureVisible(find.text('계정 삭제'));
      await tester.tap(find.text('계정 삭제'));
      await tester.pumpAndSettle();
      expect(find.text('계정을 삭제할까요?'), findsOneWidget);

      await tester.tap(_inDialog('삭제'));
      await tester.pumpAndSettle();

      expect(await repo.load('uid_1'), isNull);
      expect(state.account, isNull);
      expect(state.screen, 'login');
    });

    testWidgets('확인창에서 "취소"를 누르면 아무것도 지워지지 않는다', (tester) async {
      final repo = MemoryProfileRepository();
      final state = await _loggedInState(repo);
      state.setSetTab('데이터 · 개인정보');
      await _pump(tester, state, const SettingsScreen());

      await tester.ensureVisible(find.text('계정 삭제'));
      await tester.tap(find.text('계정 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(_inDialog('취소'));
      await tester.pumpAndSettle();

      expect(await repo.load('uid_1'), isNotNull);
      expect(state.account, isNotNull);
    });
  });
}
