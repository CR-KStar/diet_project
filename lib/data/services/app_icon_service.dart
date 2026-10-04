import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 오늘 식단을 기록했는지에 따라 홈 화면 앱 아이콘을 바꾼다 (빈 그릇 ↔ 채운 그릇).
///
/// iOS는 공식 Alternate Icon API로 매끄럽게 바뀌고, 안드로이드는
/// activity-alias 2개 중 하나만 켜두는 방식이라 런처(제조사)에 따라
/// 반영 속도가 다를 수 있다. 둘 다 "틀렸다고 실패하면 조용히 넘어간다"
/// — 아이콘 꾸밈 기능이라 실패해도 앱 사용에는 지장이 없어야 한다.
class AppIconService {
  static const _channel = MethodChannel('kr.chaerin.dietapp/app_icon');

  bool? _lastFilled;

  /// [filled]가 이전에 보낸 값과 같으면 플랫폼 호출을 건너뛴다(불필요한
  /// 아이콘 전환 시도를 줄인다 — 특히 안드로이드는 전환마다 비용이 있다).
  Future<void> setFilled(bool filled) async {
    if (_lastFilled == filled) return;
    _lastFilled = filled;
    try {
      await _channel.invokeMethod('setFilled', {'filled': filled});
    } catch (e, stack) {
      debugPrint('앱 아이콘을 바꾸지 못했어요: $e\n$stack');
    }
  }
}
