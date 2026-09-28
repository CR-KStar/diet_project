import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/ui/record/widgets/record_tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// 로그인된 실제 계정처럼 동작하는 가짜 인증 (Mock이 아니라서 예시 기록이 비워진다).
class _RealAuth implements AuthService {
  @override
  AuthAccount? get currentAccount => const AuthAccount(uid: 'uid_1', provider: LoginProvider.google);

  @override
  Future<AuthAccount?> restoreAccount() async => currentAccount;

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async => currentAccount;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {}
}

AppState _at(DateTime now, {AuthService? auth}) => AppState(now: () => now, auth: auth);

void main() {
  group('날짜 키와 오늘', () {
    test('날짜 키는 연도를 포함한 yyyy-MM-dd 형식이다', () {
      expect(AppState.dateKeyOf(DateTime(2026, 9, 5)), '2026-09-05');
      expect(AppState.dateKeyOf(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('문자열 순서가 곧 날짜 순서다', () {
      final keys = [DateTime(2027, 1, 2), DateTime(2026, 12, 31), DateTime(2026, 9, 21)].map(AppState.dateKeyOf).toList();
      final sorted = [...keys]..sort();
      expect(sorted, ['2026-09-21', '2026-12-31', '2027-01-02']);
    });

    test('오늘은 시계를 따르고 시각은 무시한다', () {
      final s = _at(DateTime(2026, 9, 21, 23, 59));
      expect(s.today, DateTime(2026, 9, 21));
      expect(s.todayDateLabel, '9월 21일');
      expect(s.todayLabel, '9월 21일 월요일');
    });

    test('보고 있는 날짜는 처음에 오늘이다', () {
      final s = _at(DateTime(2026, 9, 21));
      expect([s.year, s.month, s.day], [2026, 9, 21]);
    });
  });

  group('달력 이동', () {
    test('이전 달로 가면 해를 넘어간다', () {
      final s = _at(DateTime(2026, 1, 31));
      s.prevMonth();
      expect([s.year, s.month], [2025, 12]);
      expect(s.day, 31);
    });

    test('이전 달에 그 날짜가 없으면 말일로 맞춘다', () {
      final s = _at(DateTime(2026, 3, 31));
      s.prevMonth();
      expect([s.year, s.month, s.day], [2026, 2, 28]);
    });

    test('오늘이 속한 달보다 뒤로는 갈 수 없다', () {
      final s = _at(DateTime(2026, 9, 21));
      expect(s.canGoNextMonth, isFalse);
      expect(s.nextMonth(), isFalse);
      expect(s.month, 9);
    });

    test('지난달에서 다음 달로 돌아오면 미래 날짜가 아닌 날로 맞춘다', () {
      final s = _at(DateTime(2026, 9, 10));
      s.prevMonth();
      s.selectDay(25);
      expect(s.nextMonth(), isTrue);
      expect([s.year, s.month, s.day], [2026, 9, 10]);
    });

    test('미래 날짜는 선택할 수 없다', () {
      final s = _at(DateTime(2026, 9, 21));
      s.selectDay(25);
      expect(s.day, 21);
      s.selectDay(20);
      expect(s.day, 20);
    });
  });

  group('기록과 연속 기록', () {
    test('예시 기록은 오늘 기준이라 오늘 날짜에 붙는다', () {
      final s = _at(DateTime(2026, 9, 21));
      expect(s.todayRegistry.dateKey, '2026-09-21');
      expect(s.todayRegistry.meals, isNotEmpty);
      expect(s.hasRecordOn(DateTime(2026, 9, 21)), isTrue);
      expect(s.hasRecordOn(DateTime(2026, 9, 19)), isFalse);
    });

    test('연속 기록은 오늘부터 이어진 날 수다 (예시: 오늘 식단 + 어제 체중 = 2일)', () {
      expect(_at(DateTime(2026, 9, 21)).streakDays, 2);
    });

    test('실제 계정으로 로그인하면 예시 기록이 비워진다', () async {
      final s = _at(DateTime(2026, 9, 21), auth: _RealAuth());
      await s.restoreSession();

      expect(s.todayRegistry.meals, isEmpty);
      expect(s.waterEntries, isEmpty);
      expect(s.weightEntries, isEmpty);
      expect(s.hasRecordOn(DateTime(2026, 9, 21)), isFalse);
      expect(s.streakDays, 0);
    });

    test('실제 계정에서 기록하면 오늘 날짜로 저장되고 연속 기록이 1이 된다', () async {
      final s = _at(DateTime(2026, 9, 21), auth: _RealAuth());
      await s.restoreSession();

      s.exType = '달리기';
      s.logExercise();

      expect(s.todayRegistry.exerciseLogs.single.dateKey, '2026-09-21');
      expect(s.streakDays, 1);
    });

    test('로그아웃하면 이전 계정의 기록이 남지 않는다', () async {
      final s = _at(DateTime(2026, 9, 21), auth: _RealAuth());
      await s.restoreSession();
      s.exType = '달리기';
      s.logExercise();

      await s.signOut();

      expect(s.todayRegistry.exerciseLogs, isEmpty);
    });
  });

  testWidgets('기록 탭 달력: 실제 연월을 보여주고 미래 날짜는 눌러도 바뀌지 않는다', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final state = _at(DateTime(2026, 9, 21));
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: Scaffold(body: RecordsScreen())),
      ),
    );

    expect(find.text('2026. 09'), findsOneWidget);

    await tester.tap(find.text('25')); // 미래
    await tester.pump();
    expect(state.day, 21);

    await tester.tap(find.text('20')); // 과거
    await tester.pump();
    expect(state.day, 20);
  });
}
