import 'package:diet_project/data/services/ai_consent_store.dart';
import 'package:diet_project/ui/home/viewmodel/ai_consent_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/notification_inbox_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationInboxViewModel', () {
    test('처음에는 읽지 않은 알림이 3개이고 전체 탭이다', () {
      final vm = NotificationInboxViewModel();

      expect(vm.unread, 3);
      expect(vm.notifTab, '전체');
    });

    test('알림 하나를 읽으면 읽지 않은 수가 줄고, 같은 알림은 두 번 줄지 않는다', () {
      final vm = NotificationInboxViewModel();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.markNotifRead('식물이 물을 기다려요');
      vm.markNotifRead('식물이 물을 기다려요');

      expect(vm.unread, 2);
      expect(notified, 1); // 이미 읽은 알림은 다시 알리지 않는다
    });

    test('모두 읽음 처리하면 0이 된다', () {
      final vm = NotificationInboxViewModel()..readAll();

      expect(vm.unread, 0);
    });

    test('탭을 바꾸면 알린다', () {
      final vm = NotificationInboxViewModel();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.setNotifTab('활동');

      expect(vm.notifTab, '활동');
      expect(notified, 1);
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
