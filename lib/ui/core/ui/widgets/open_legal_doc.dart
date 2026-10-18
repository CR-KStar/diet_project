import 'package:diet_project/data/services/legal_links.dart';
import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/toast.dart';

/// 동의 항목([term])에 맞는 약관 · 처방침 전문을 브라우저로 연다.
Future<void> openLegalDoc(BuildContext context, String term) async {
  final ok = await LegalLinks.open(LegalLinks.forTerm(term));
  if (!ok && context.mounted) toast(context, '문서를 열지 못했어요. 인터넷 연결을 확인해 주세요');
}
