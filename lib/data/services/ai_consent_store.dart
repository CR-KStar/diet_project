/// "식사 사진 · 식단 정보를 외부 AI(Anthropic)로 보내 분석한다"는 동의 여부를 기억한다.
/// 동의하기 전에는 사진이나 식단 정보를 서버로 보내지 않는다.
abstract class AiConsentStore {
  Future<bool> read();
  Future<void> write(bool value);
}
