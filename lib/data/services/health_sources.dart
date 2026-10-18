import 'package:diet_project/config/app_config.dart';

/// 앱이 보여주는 건강 수치(칼로리 · 영양소 · 체중)의 계산 방법과 참고 출처.
///
/// 리포트·영양소 화면의 "계산 방법과 참고 출처" 카드가 이 목록을 그대로 보여준다.
/// 전체 설명은 웹 페이지(docs/health-sources.md)에도 있다.
class HealthSource {
  const HealthSource({
    required this.topic,
    required this.how,
    required this.sourceName,
    required this.url,
  });

  /// 어떤 수치에 대한 출처인지 (예: 기초대사량)
  final String topic;

  /// 이 앱에서 어떻게 쓰는지 한 줄 설명
  final String how;

  /// 사람이 읽는 출처 이름
  final String sourceName;

  final Uri url;
}

abstract final class HealthSources {
  static const baseUrl = AppConfig.siteBaseUrl;

  /// 전체 출처 안내 페이지
  static final fullPage = Uri.parse('$baseUrl/sources/');

  static final all = <HealthSource>[
    HealthSource(
      topic: '기초대사량',
      how: '미플린–세인트 조르 공식으로 계산하고, 활동량을 곱해 하루 권장 칼로리를 구해요.',
      sourceName: 'Mifflin MD 외, Am J Clin Nutr 1990 (PubMed)',
      url: Uri.parse('https://pubmed.ncbi.nlm.nih.gov/2305711/'),
    ),
    HealthSource(
      topic: '나트륨 기준 (하루 2,000mg 미만)',
      how: '나트륨 목표치로 쓰는 기준이에요.',
      sourceName: 'WHO — 소금(나트륨) 섭취 줄이기',
      url: Uri.parse(
        'https://www.who.int/news-room/fact-sheets/detail/salt-reduction',
      ),
    ),
    HealthSource(
      topic: '식이섬유 기준 (하루 25g 이상)',
      how: '식이섬유 목표치로 쓰는 기준이에요.',
      sourceName: 'WHO — 건강한 식단',
      url: Uri.parse(
        'https://www.who.int/news-room/fact-sheets/detail/healthy-diet',
      ),
    ),
    HealthSource(
      topic: '단백질 · 탄수화물 · 지방 · 물',
      how: '일반적인 참고값이에요. 연령·성별·활동량에 따라 필요량이 달라요.',
      sourceName: '한국인 영양소 섭취기준 (한국영양학회)',
      url: Uri.parse('https://www.kns.or.kr/'),
    ),
    HealthSource(
      topic: '운동 · 체중 관리',
      how: '운동 목표와 체중 관리에 대한 일반 지침이에요.',
      sourceName: 'WHO — 신체활동',
      url: Uri.parse(
        'https://www.who.int/news-room/fact-sheets/detail/physical-activity',
      ),
    ),
  ];
}
