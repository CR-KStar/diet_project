import 'package:diet_project/ui/core/ui/icons/app_icons.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';
import 'package:diet_project/ui/social/viewmodel/friend_view_model.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 사용자 신고 시트 — 사유를 고르고 (원하면) 설명을 적어 운영자에게 보낸다.
class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, required this.uid, required this.nickname});

  final String uid;
  final String nickname;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  static const _maxDetail = 300;

  ReportReason? _reason;
  String _detail = '';
  bool _sending = false;

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    final friends = context.read<FriendViewModel>();
    setState(() => _sending = true);
    final ok = await friends.reportUser(
      targetUid: widget.uid,
      nickname: widget.nickname,
      reason: reason,
      detail: _detail,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      toast(context, '신고가 접수됐어요. 확인 후 조치할게요');
    } else {
      setState(() => _sending = false);
      toast(context, '신고를 보내지 못했어요. 잠시 후 다시 시도해 주세요');
    }
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    title: '${widget.nickname}님 신고',
    subtitle: '신고한 사실은 상대에게 알려지지 않아요',
    leading: Icon(AppIcons.warning, color: AppColor.alertText),
    onClose: () => Navigator.of(context).pop(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('신고 사유', style: t(AppFontSize.f12, c: AppColor.textMuted)),
        const SizedBox(height: AppSpace.s8),
        ChipWrap(
          options: [for (final r in ReportReason.values) r.label],
          isSelected: (o) => _reason?.label == o,
          onPick: (o) => setState(
            () => _reason = ReportReason.values.firstWhere((r) => r.label == o),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Text(
          '자세한 내용 (선택, $_maxDetail자까지)',
          style: t(AppFontSize.f12, c: AppColor.textMuted),
        ),
        const SizedBox(height: AppSpace.s8),
        AppTextField(
          value: _detail,
          hint: '어떤 점이 문제였는지 알려 주세요',
          maxLines: 3,
          minHeight: 84,
          onChanged: (v) =>
              _detail = v.length > _maxDetail ? v.substring(0, _maxDetail) : v,
        ),
        const SizedBox(height: AppSpace.s16),
        PrimaryButton(
          label: _sending ? '보내는 중…' : '신고하기',
          enabled: _reason != null && !_sending,
          onTap: _reason == null || _sending ? null : _send,
        ),
        const SizedBox(height: AppSpace.s6),
        Text(
          '신고해도 친구 관계나 차단은 그대로예요. 필요하면 차단도 함께 해 주세요.',
          style: t(AppFontSize.f11, c: AppColor.textFaint, h: 1.5),
        ),
      ],
    ),
  );
}
