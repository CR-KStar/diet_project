import 'package:shared_preferences/shared_preferences.dart';
import 'package:diet_project/data/services/ai_consent_store.dart';

/// 기기에 저장 — 앱을 껐다 켜도 유지된다.
class PrefsAiConsentStore implements AiConsentStore {
  static const _key = 'ai_consent_v1';

  @override
  Future<bool> read() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> write(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_key, value);
}
