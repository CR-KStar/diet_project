import 'package:diet_project/data/services/ai_consent_store.dart';

/// 메모리에만 — 데모 모드와 테스트용.
class MemoryAiConsentStore implements AiConsentStore {
  bool _value = false;

  @override
  Future<bool> read() async => _value;

  @override
  Future<void> write(bool value) async => _value = value;
}
