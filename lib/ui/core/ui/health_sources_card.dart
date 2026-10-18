import 'package:diet_project/data/services/health_sources.dart';
import 'package:diet_project/data/services/legal_links.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';

/// "계산 방법과 참고 출처" 카드 — 칼로리·영양소·체중 수치가 어떤 근거로 나온 것인지
/// 출처 링크와 함께 보여준다 (App Store 가이드라인 1.4.1).
/// 리포트와 영양소 화면 아래에 둬서 사용자가 쉽게 찾을 수 있게 한다.
class HealthSourcesCard extends StatelessWidget {
  const HealthSourcesCard({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await LegalLinks.open(uri);
    if (!ok && context.mounted) {
      toast(context, '링크를 열지 못했어요. 인터넷 연결을 확인해 주세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('계산 방법과 참고 출처', style: t(AppFontSize.f15, w: FontWeight.w800)),
          const SizedBox(height: AppSpace.s6),
          Text(
            '칼로리·영양소 수치는 아래 자료를 참고한 일반적인 기준이에요. '
            '의학적 진단이나 처방이 아니며, 개인에 따라 다를 수 있어요.',
            style: t(AppFontSize.f11, c: AppColor.textFaint, h: 1.6),
          ),
          const SizedBox(height: AppSpace.s10),
          for (final s in HealthSources.all)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _open(context, s.url),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.topic,
                      style: t(AppFontSize.f12, w: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.s2),
                    Text(
                      s.how,
                      style: t(AppFontSize.f11, c: AppColor.textMuted, h: 1.5),
                    ),
                    const SizedBox(height: AppSpace.s2),
                    Text(
                      '${s.sourceName} ›',
                      style: t(
                        AppFontSize.f11,
                        c: AppColor.primaryDark,
                        w: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open(context, HealthSources.fullPage),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.s4),
              child: Text(
                '전체 출처와 계산식 보기 ›',
                style: t(
                  AppFontSize.f12,
                  c: AppColor.primaryDark,
                  w: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
