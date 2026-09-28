import 'package:diet_project/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('AppTextField는 한글 입력을 그대로 받아 onChanged로 넘긴다', (tester) async {
    String latest = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(value: '', onChanged: (v) => latest = v),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '채린');
    await tester.pump();

    expect(latest, '채린');
    expect(find.text('채린'), findsOneWidget);
  });
}
