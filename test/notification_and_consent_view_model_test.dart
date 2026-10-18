import 'package:diet_project/data/services/ai_consent_store.dart';
import 'package:diet_project/ui/home/viewmodel/ai_consent_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/notification_inbox_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationInboxViewModel', () {
    InboxNotification n(String id, String category) => InboxNotification(
      id: id,
      category: category,
      icon: '🔔',
      title: '알림 $id',
      body: '내용',
      at: DateTime(2026, 10, 18, 9),
      route: 'home',
    );

    test('처음에는 알림이 하나도 없고, 읽지 않은 알림도 없다 (가짜 알림을 보여주지 않는다)', () {
      final vm = NotificationInboxViewModel();

      expect(vm.items, isEmpty);
      expect(vm.visibleItems, isEmpty);
      expect(vm.unread, 0);
      expect(vm.notifTab, '전체');
    });

    test('알림이 있으면 읽지 않은 수를 센다', () {
      final vm = NotificationInboxViewModel(
        items: [n('a', '기록'), n('b', '친구'), n('c', '식물')],
      );

      expect(vm.unread, 3);
    });

    test('알림 하나를 읽으면 읽지 않은 수가 줄고, 같은 알림은 두 번 줄지 않는다', () {
      final vm = NotificationInboxViewModel(
        items: [n('a', '기록'), n('b', '친구')],
      );
      var notified = 0;
      vm.addListener(() => notified++);

      vm.markNotifRead('a');
      vm.markNotifRead('a');

      expect(vm.unread, 1);
      expect(vm.isUnread(vm.items.first), isFalse);
      expect(notified, 1); // 이미 읽은 알림은 다시 알리지 않는다
    });

    test('모두 읽음 처리하면 0이 되고, 읽을 게 없으면 알리지 않는다', () {
      final vm = NotificationInboxViewModel(
        items: [n('a', '기록'), n('b', '친구')],
      );
      var notified = 0;
      vm.addListener(() => notified++);

      vm.readAll();
      vm.readAll();

      expect(vm.unread, 0);
      expect(notified, 1);
    });

    test('탭을 고르면 그 분류의 알림만 보인다', () {
      final vm = NotificationInboxViewModel(
        items: [n('a', '기록'), n('b', '친구'), n('c', '기록')],
      );
      var notified = 0;
      vm.addListener(() => notified++);

      vm.setNotifTab('기록');

      expect(vm.visibleItems.map((x) => x.id), ['a', 'c']);
      expect(notified, 1);
      vm.setNotifTab('전체');
      expect(vm.visibleItems, hasLength(3));
    });
  });

  group('AiConsentViewModel', () {
    test('처음에는 동의하지 않은 상태이고, 저장된 값을 불러온다', () async {
      final store = MemoryAiConsentStore();
      await store.write(true);
      final vm = AiConsentViewModel(store: store);
      expect(vm.aiConsent, isFalse);

      await vm.loadAiConsent();

      expect(vm.aiConsent, isTrue);
    });

    test('동의하면 저장하고, 철회하면 다시 저장한다', () async {
      final store = MemoryAiConsentStore();
      final vm = AiConsentViewModel(store: store);

      await vm.setAiConsent(true);
      expect(await store.read(), isTrue);

      await vm.setAiConsent(false);
      expect(vm.aiConsent, isFalse);
      expect(await store.read(), isFalse);
    });

    test('바꾸면 알린다', () async {
      final vm = AiConsentViewModel(store: MemoryAiConsentStore());
      var notified = 0;
      vm.addListener(() => notified++);

      await vm.setAiConsent(true);

      expect(notified, 1);
    });
  });
}
