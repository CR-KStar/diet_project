import 'package:url_launcher/url_launcher.dart';

/// 약관 · 개인정보 처리방침 전문(GitHub Pages로 공개) 열기.
class LegalLinks {
  LegalLinks._();

  static const _base = 'https://cr-kstar.github.io/diet_project';
  static final privacy = Uri.parse('$_base/privacy/');
  static final terms = Uri.parse('$_base/terms/');

  /// 동의 항목 이름(AppState.terms의 키)에 맞는 문서. 서비스 이용약관만 따로,
  /// 나머지(개인정보 · 민감 건강정보 · 마케팅)는 처방침에 모두 담겨 있다.
  static Uri forTerm(String term) => term.contains('이용약관') ? terms : privacy;

  /// 기본 브라우저로 연다. 열지 못하면 false.
  static Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
