import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/profile_repository.dart';
import 'package:diet_project/ui/onboarding/widgets/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _account = AuthAccount(uid: 'uid_1', provider: LoginProvider.google, displayName: '지민');

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
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('마지막 "시작하기"를 누르면 온보딩 완료가 계정에 저장되고 홈으로 간다', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final repo = MemoryProfileRepository();
    final state = AppState(auth: _FakeAuth(), profiles: repo);
    await state.restoreSession();
    state.step = 4;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: Scaffold(body: OnboardingPage())),
      ),
    );

    await tester.ensureVisible(find.text('시작하기'));
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(state.screen, 'home');
    expect(state.onboardingDone, isTrue);
    expect((await repo.load('uid_1'))?.onboardingDone, isTrue);
  });
}
