import 'package:shared_preferences/shared_preferences.dart';

/// "식사 사진 · 식단 정보를 외부 AI(Anthropic)로 보내 분석한다"는 동의 여부를 기억한다.
/// 동의하기 전에는 사진이나 식단 정보를 서버로 보내지 않는다.
abstract class AiConsentStore {
  Future<bool> read();
  Future<void> write(bool value);
}

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

/// 메모리에만 — 데모 모드와 테스트용.
class MemoryAiConsentStore implements AiConsentStore {
  bool _value = false;

  @override
  Future<bool> read() async => _value;

  @override
  Future<void> write(bool value) async => _value = value;
}
