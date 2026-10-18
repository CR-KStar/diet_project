import 'package:diet_project/data/services/ai_consent_store.dart';
import 'package:flutter/foundation.dart';

/// 외부 AI로 데이터를 보내는 기능(사진 분석 · 식단 추천)을 쓰기 전에 받는 동의를 담당한다.
///
/// 동의 여부는 기기에 저장해 두었다가 앱을 켤 때 불러온다. 철회하면 다시 묻는다.
class AiConsentViewModel extends ChangeNotifier {
  AiConsentViewModel({required AiConsentStore store}) : _store = store;

  final AiConsentStore _store;

  bool aiConsent = false;

  Future<void> loadAiConsent() async {
    aiConsent = await _store.read();
    notifyListeners();
  }

  Future<void> setAiConsent(bool value) async {
    aiConsent = value;
    notifyListeners();
    await _store.write(value);
  }
}
