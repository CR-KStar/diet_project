import 'package:diet_project/ui/core/viewmodel/navigation_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NavigationViewModel nav;

  setUp(() => nav = NavigationViewModel());

  test('처음에는 로그인 화면이고 하단 탭은 숨겨진다', () {
    expect(nav.screen, 'login');
    expect(nav.showShell, isFalse);
  });

  test('별칭 id는 부모 화면과 서브 모드로 풀린다', () {
    nav.go('home');
    nav.go('mission');
    expect(nav.screen, 'home');
    expect(nav.missionOpen, isTrue);

    nav.go('dex');
    expect(nav.screen, 'plant');
    expect(nav.plantTab, '도감');
    expect(nav.missionOpen, isFalse);

    nav.go('privacy');
    expect(nav.screen, 'settings');
    expect(nav.setTab, '데이터 · 개인정보');
  });

  test('다른 화면으로 가면 서브 모드가 초기화된다', () {
    nav.go('home');
    nav.go('challenge');
    expect(nav.friendTab, '챌린지');
    nav.go('records');
    expect(nav.friendTab, '활동');
  });

  test('하단 탭이 보이는 화면에서만 이동 기록이 쌓이고, 뒤로가기로 되돌아간다', () {
    nav.go('home'); // login → home: 탭이 없던 화면이라 기록하지 않는다
    nav.go('records');
    nav.go('weight');
    expect(nav.goBack(), isTrue);
    expect(nav.screen, 'records');
    expect(nav.goBack(), isTrue);
    expect(nav.screen, 'home');
    expect(nav.goBack(), isFalse);
  });

  test('같은 화면으로 다시 가도 기록이 늘지 않는다', () {
    nav.go('home');
    nav.go('records');
    nav.go('records');
    expect(nav.goBack(), isTrue);
    expect(nav.screen, 'home');
    expect(nav.goBack(), isFalse);
  });

  test('closeSubMode는 열린 서브 모드를 닫고, 없으면 false', () {
    nav.go('home');
    expect(nav.closeSubMode(), isFalse);
    nav.setMissionOpen(true);
    expect(nav.closeSubMode(), isTrue);
    expect(nav.missionOpen, isFalse);
  });

  test('replaceWith는 이동 기록을 남기지 않는다', () {
    nav.go('home');
    nav.go('chNew');
    nav.replaceWith('friends', friendTab: '챌린지');
    expect(nav.screen, 'friends');
    expect(nav.friendTab, '챌린지');
    nav.goBack();
    expect(nav.screen, 'home');
  });

  test('이동하면 onNavigated로 요청한 id를 알린다', () {
    final seen = <String>[];
    nav.onNavigated = seen.add;
    nav.go('signup');
    nav.go('home');
    expect(seen, ['signup', 'home']);
    expect(nav.screen, 'home');
  });

  test('이동하면 구독자에게 알린다', () {
    var count = 0;
    nav.addListener(() => count++);
    nav.go('home');
    nav.setPlantTab('도감');
    expect(count, 2);
  });
}
