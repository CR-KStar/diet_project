import 'package:diet_project/ui/home/viewmodel/ai_consent_view_model.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/confirm_dialog.dart';

/// 식사 사진 · 식단 정보를 외부 AI로 보내기 전에 동의를 받는다.
/// 이미 동의했으면 묻지 않고 true, 동의하지 않으면 false (이때는 아무것도 보내지 않는다).
Future<bool> ensureAiConsent(
  BuildContext context,
  AiConsentViewModel consent,
) async {
  if (consent.aiConsent) return true;
  final ok = await confirmDialog(
    context,
    title: 'AI 분석에 동의해 주세요',
    message:
        '식사 사진과 식단 추천에 필요한 정보(부족한 영양소, 선호 조건)가 '
        'AI 분석을 위해 외부 AI 서비스(Anthropic, 미국)로 전송돼요.\n\n'
        '· 사진 원본은 저장되지 않고, 분석 결과만 기록으로 남아요.\n'
        '· 동의하지 않아도 직접 입력해서 기록할 수 있어요.\n'
        '· 설정 > 데이터 및 개인정보에서 언제든 철회할 수 있어요.',
    confirmLabel: '동의하고 진행',
  );
  if (ok) await consent.setAiConsent(true);
  return ok;
}
