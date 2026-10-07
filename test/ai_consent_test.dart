import 'package:diet_project/app_state.dart';
import 'package:diet_project/data/services/ai_consent_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('외부 AI 전송 동의', () {
    test('처음에는 동의하지 않은 상태다', () {
      expect(AppState().aiConsent, isFalse);
    });

    test('동의하면 저장소에 남고, 앱을 다시 켜도 불러온다', () async {
      final store = MemoryAiConsentStore();
      final s = AppState(aiConsentStore: store);
      await s.setAiConsent(true);
      expect(s.aiConsent, isTrue);

      final reopened = AppState(aiConsentStore: store);
      expect(reopened.aiConsent, isFalse); // 불러오기 전
      await reopened.loadAiConsent();
      expect(reopened.aiConsent, isTrue);
    });

    test('철회하면 다시 동의하지 않은 상태가 된다', () async {
      final store = MemoryAiConsentStore();
      final s = AppState(aiConsentStore: store);
      await s.setAiConsent(true);
      await s.setAiConsent(false);
      expect(await store.read(), isFalse);
    });

    test('동의 전에는 추천 화면에 들어가도 AI 추천을 자동 요청하지 않는다', () {
      final s = AppState();
      s.go('recommend');
      expect(s.loadingRecommendations, isFalse);
      expect(s.aiRecommendations, isNull);
    });
  });
}
