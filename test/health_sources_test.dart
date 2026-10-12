import 'package:diet_project/data/services/health_sources.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/ui/core/ui/health_sources_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  group('건강 정보 출처', () {
    test('모든 출처에 주제 · 설명 · 이름과 https 링크가 있다', () {
      for (final s in HealthSources.all) {
        expect(s.topic, isNotEmpty);
        expect(s.how, isNotEmpty);
        expect(s.sourceName, isNotEmpty);
        expect(s.url.scheme, 'https');
        expect(s.url.host, isNotEmpty);
      }
      expect(HealthSources.fullPage.scheme, 'https');
    });

    test('기초대사량은 미플린–세인트 조르 공식과 같은 값이 나온다', () {
      // 남성 30세 175cm 70kg: 10×70 + 6.25×175 − 5×30 + 5 = 1648.75
      final male = UserProfile(
        userId: 'u',
        gender: '남성',
        heightCm: 175,
        weightKg: 70,
        age: 30,
      );
      expect(male.bmr, closeTo(1648.75, 0.01));
      // 여성 30세 165cm 55kg: 10×55 + 6.25×165 − 5×30 − 161 = 1270.25
      final female = UserProfile(
        userId: 'u',
        gender: '여성',
        heightCm: 165,
        weightKg: 55,
        age: 30,
      );
      expect(female.bmr, closeTo(1270.25, 0.01));
    });

    testWidgets('출처 카드는 모든 출처와 면책 문구를 보여준다', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HealthSourcesCard()),
          ),
        ),
      );

      expect(find.text('계산 방법과 참고 출처'), findsOneWidget);
      for (final s in HealthSources.all) {
        expect(find.text(s.topic), findsOneWidget);
        expect(find.text('${s.sourceName} ›'), findsOneWidget);
      }
      expect(find.textContaining('의학적 진단이나 처방이 아니며'), findsOneWidget);
      expect(find.text('전체 출처와 계산식 보기 ›'), findsOneWidget);
    });
  });
}
