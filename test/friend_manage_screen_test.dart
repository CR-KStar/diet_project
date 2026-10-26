import 'package:diet_project/app_composition.dart';
import 'package:diet_project/app_providers.dart';
import 'package:diet_project/app_shell.dart';
import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/repositories/impl/memory_friend_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _me = AuthAccount(
  uid: 'me',
  provider: LoginProvider.google,
  displayName: '채린',
);

class _FakeAuth implements AuthService {
  @override
  bool get isDemo => false;

  @override
  AuthAccount? get currentAccount => _me;

  @override
  Future<AuthAccount?> restoreAccount() async => _me;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => _me;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late MemoryFriendRepository friends;
  late MemoryReportRepository reports;

  /// me와 bob은 친구이고, me가 carol에게 보낸 요청이 아직 답을 기다리는 상태.
  Future<AppState> pumpFriends(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    friends = MemoryFriendRepository();
    reports = MemoryReportRepository();
    await friends.ensureInviteCode('me', '채린');
    await friends.ensureInviteCode('bob', '밥');
    await friends.ensureInviteCode('carol', '캐롤');
    await friends.sendFriendRequest('bob', 'me');
    await friends.acceptFriendRequest(
      (await friends.loadIncomingRequests('me')).single,
    );
    await friends.sendFriendRequest('me', 'carol');

    final state = AppState(
      dependencies: memoryDependencies(
        auth: _FakeAuth(),
        friendRepo: friends,
        reportRepo: reports,
        now: () => DateTime(2026, 10, 18),
      ),
    );
    await state.restoreSession();
    state.navigationViewModel.go('friends');
    state.navigationViewModel.setFriendTab('친구 추가');
    await tester.pumpWidget(
      AppProviders(
        state: state,
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    return state;
  }

  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  testWidgets('내 친구와 보낸 요청이 목록에 나온다', (tester) async {
    await pumpFriends(tester);

    expect(find.text('내 친구 1'), findsOneWidget);
    expect(find.text('밥'), findsOneWidget);
    expect(find.text('보낸 요청 1'), findsOneWidget);
    expect(find.text('캐롤'), findsOneWidget);
  });

  testWidgets('보낸 요청을 취소하면 목록에서 사라진다', (tester) async {
    final state = await pumpFriends(tester);

    await tester.tap(find.text('요청 취소'));
    await tester.pumpAndSettle();

    expect(find.text('보낸 요청 1'), findsNothing);
    expect(state.friendViewModel.outgoingFriendRequests, isEmpty);
    expect(await friends.loadIncomingRequests('carol'), isEmpty);
  });

  testWidgets('친구 ⋯ 메뉴에서 친구 끊기는 확인창을 거쳐야 끊긴다', (tester) async {
    final state = await pumpFriends(tester);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('차단하기'), findsOneWidget);
    expect(find.text('신고하기'), findsOneWidget);

    await tester.tap(find.text('친구 끊기'));
    await tester.pumpAndSettle();
    expect(find.text('밥님과 친구를 끊을까요?'), findsOneWidget);

    // 취소하면 그대로다.
    await tester.tap(inDialog('취소'));
    await tester.pumpAndSettle();
    expect(state.friendViewModel.realFriends, isNotEmpty);

    await tester.tap(find.text('친구 끊기'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('친구 끊기'));
    await tester.pumpAndSettle();

    expect(state.friendViewModel.realFriends, isEmpty);
    expect(find.text('내 친구 1'), findsNothing);
  });

  testWidgets('차단하면 친구가 끊기고 차단한 사용자에 나오며, 해제하면 사라진다', (tester) async {
    final state = await pumpFriends(tester);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('차단하기'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('차단'));
    await tester.pumpAndSettle();

    expect(state.friendViewModel.isBlocked('bob'), isTrue);
    expect(state.friendViewModel.realFriends, isEmpty);
    expect(find.text('차단한 사용자 1'), findsOneWidget);

    await tester.tap(find.text('차단 해제'));
    await tester.pumpAndSettle();

    expect(state.friendViewModel.isBlocked('bob'), isFalse);
    expect(find.text('차단한 사용자 1'), findsNothing);
  });

  testWidgets('신고는 사유를 골라야 보낼 수 있고, 보내면 접수된다', (tester) async {
    await pumpFriends(tester);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('신고하기'));
    await tester.pumpAndSettle();
    expect(find.text('밥님 신고'), findsOneWidget);

    // 사유를 고르기 전에는 눌러도 접수되지 않는다.
    await tester.tap(find.text('신고하기'));
    await tester.pumpAndSettle();
    expect(reports.submitted, isEmpty);

    await tester.tap(find.text('스팸 · 광고'));
    await tester.pump();
    await tester.tap(find.text('신고하기'));
    await tester.pumpAndSettle();

    expect(reports.submitted, hasLength(1));
    expect(reports.submitted.single.targetUid, 'bob');
    expect(reports.submitted.single.reason.label, '스팸 · 광고');
    expect(find.text('밥님 신고'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });
}
